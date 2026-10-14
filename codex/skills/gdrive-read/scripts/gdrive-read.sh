#!/usr/bin/env bash
# Read-only Google Drive access for coding agents.
# The access token lives only inside this process: it is never printed and
# never passed on a command line (curl reads the header from a file descriptor).

set -euo pipefail

readonly CONFIG_DIR="${GDRIVE_CLOUDSDK_CONFIG:-$HOME/.config/gcloud-gdrive}"
readonly DRIVE_SCOPE="https://www.googleapis.com/auth/drive"
readonly DRIVE_API="https://www.googleapis.com/drive/v3"
readonly SHEETS_API="https://sheets.googleapis.com/v4"
readonly MIME_DOC="application/vnd.google-apps.document"
readonly MIME_SHEET="application/vnd.google-apps.spreadsheet"
readonly MIME_FOLDER="application/vnd.google-apps.folder"
readonly MIME_XLSX="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
readonly MIME_DOCX="application/vnd.openxmlformats-officedocument.wordprocessingml.document"
readonly FILE_FIELDS="id,name,mimeType,modifiedTime,webViewLink"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly EX_USAGE=64
readonly EX_AUTH=65
readonly EX_NOTFOUND=66
readonly EX_UNSUPPORTED=67
readonly EX_HTTP=69
readonly EX_NOPERM=77

usage() {
  cat <<'EOF' >&2
Usage: gdrive-read.sh <command> [args]

  login [ACCOUNT]                          Start the browser login (a human approves it)
  status                                   Check that a token can be obtained (prints no token)
  meta   <url|id>                          Show id, name, mimeType, modifiedTime, webViewLink
  doc    <url|id> --out DIR                Save a Google Doc or uploaded .docx as Markdown
  sheet-list <url|id>                      List sheets (Google Sheet: gid, title, rows, cols; .xlsx: index, title, rows, cols)
  sheet  <url|id> [--gid N | --sheet TITLE] [--range A1] --out DIR
                                           Save one sheet as CSV (default: gid from URL, else first sheet)
  search <name-substring> [--type doc|sheet|folder] [--limit N]
                                           Search by file name across My Drive, shared-with-me, shared drives
  ls     <folder-url|id> [--limit N]       List a folder (one level)

Exit codes: 64 usage, 65 login required, 66 not found or no access, 67 unsupported type, 69 other HTTP error,
            77 credential store blocked (re-run with escalated permissions)
EOF
}

die() {
  local code="$1"
  shift
  printf 'gdrive-read: %s\n' "$*" >&2
  exit "$code"
}

gcloud_dedicated() {
  CLOUDSDK_CONFIG="$CONFIG_DIR" gcloud "$@"
}

login_hint() {
  printf 'Hint: run "%s login" and approve the browser prompt.\n' "$0" >&2
}

# unset first: an exported TOKEN from the caller would otherwise keep its export
# attribute and leak the bearer token into every child process's environment.
unset TOKEN
TOKEN=""

XLSX_TMPD=""
cleanup() {
  if [[ -n "$XLSX_TMPD" ]]; then
    rm -rf "$XLSX_TMPD"
  fi
}
trap cleanup EXIT

fetch_token() {
  [[ -n "$TOKEN" ]] && return 0
  local err
  err="$(mktemp)"
  if ! TOKEN="$(gcloud_dedicated auth print-access-token --scopes="$DRIVE_SCOPE" 2>"$err")" || [[ -z "$TOKEN" ]]; then
    TOKEN=""
    sed -E 's/ya29\.[A-Za-z0-9._-]+/<redacted>/g' "$err" | head -5 >&2
    # A sandbox that blocks the credential store looks like a login failure; a new login would not help.
    if grep -qE 'Operation not permitted|Permission denied' "$err"; then
      rm -f "$err"
      printf 'Hint: access to %s was blocked (sandbox?). Re-run this same command with escalated permissions; do not run login.\n' "$CONFIG_DIR" >&2
      exit "$EX_NOPERM"
    fi
    rm -f "$err"
    login_hint
    exit "$EX_AUTH"
  fi
  rm -f "$err"
}

# Print the file ID found in a Drive / Docs / Sheets URL, or the argument itself if it is a bare ID.
extract_id() {
  local s="$1" id=""
  if [[ "$s" =~ /(d|folders)/([A-Za-z0-9_-]{10,}) ]]; then
    id="${BASH_REMATCH[2]}"
  elif [[ "$s" =~ [?\&]id=([A-Za-z0-9_-]{10,}) ]]; then
    id="${BASH_REMATCH[1]}"
  elif [[ "$s" =~ ^[A-Za-z0-9_-]{10,}$ ]]; then
    id="$s"
  fi
  [[ -n "$id" ]] || die "$EX_USAGE" "cannot find a file ID in: $s"
  printf '%s\n' "$id"
}

extract_gid() {
  if [[ "$1" =~ gid=([0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  fi
}

uri_encode() {
  jq -rn --arg s "$1" '$s | @uri'
}

# http_get URL OUTFILE: GET with the bearer token; the body goes to OUTFILE.
# Non-2xx responses print Google's error message and exit with a mapped code.
http_get() {
  local url="$1" out="$2" code
  fetch_token
  if ! code="$(curl -sS -L -o "$out" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "$TOKEN") "$url")"; then
    rm -f "$out"
    die "$EX_HTTP" "request failed: ${url%%\?*}"
  fi
  [[ "$code" =~ ^2 ]] && return 0
  local msg
  msg="$(jq -r '.error.message // empty' "$out" 2>/dev/null || true)"
  [[ -n "$msg" ]] || msg="$(head -c 300 "$out" | tr '\n' ' ')"
  rm -f "$out"
  printf 'gdrive-read: HTTP %s from %s: %s\n' "$code" "${url%%\?*}" "$msg" >&2
  case "$code" in
    401) login_hint; exit "$EX_AUTH" ;;
    403|404) exit "$EX_NOTFOUND" ;;
    *) exit "$EX_HTTP" ;;
  esac
}

get_json() {
  local tmp
  tmp="$(mktemp)"
  http_get "$1" "$tmp"
  cat "$tmp"
  rm -f "$tmp"
}

file_meta() {
  get_json "$DRIVE_API/files/$1?supportsAllDrives=true&fields=$FILE_FIELDS"
}

# Print the Markdown export URL for a Google Doc or an uploaded .docx.
# Drive files.export rejects non-Google files, so .docx goes through the Docs editor's export.
doc_export_url() {
  local mime
  mime="$(file_meta "$1" | jq -r '.mimeType')"
  case "$mime" in
    "$MIME_DOC") echo "$DRIVE_API/files/$1/export?mimeType=$(uri_encode text/markdown)" ;;
    "$MIME_DOCX") echo "https://docs.google.com/document/d/$1/export?format=md" ;;
    *) die "$EX_UNSUPPORTED" "$1 is $mime, expected a Google Doc or .docx" ;;
  esac
}

# Print "native" for a Google Sheet, "xlsx" for an uploaded .xlsx; anything else is unsupported.
sheet_kind() {
  local mime
  mime="$(file_meta "$1" | jq -r '.mimeType')"
  case "$mime" in
    "$MIME_SHEET") echo native ;;
    "$MIME_XLSX") echo xlsx ;;
    *) die "$EX_UNSUPPORTED" "$1 is $mime, expected a Google Sheet or .xlsx" ;;
  esac
}

# xlsx_run ID ARGS...: download the .xlsx to a temp dir, run xlsx_tool.py on it, then delete it.
# ARGS may contain the placeholder @XLSX@ for the downloaded file path.
xlsx_run() {
  local id="$1" rc=0
  shift
  # Global so the EXIT trap removes it even when http_get exits on an error.
  XLSX_TMPD="$(mktemp -d)"
  http_get "$DRIVE_API/files/$id?alt=media&supportsAllDrives=true" "$XLSX_TMPD/book.xlsx"
  local args=() a
  for a in "$@"; do
    args+=("${a//@XLSX@/$XLSX_TMPD/book.xlsx}")
  done
  # Keep uv's cache inside the dedicated config dir: sandboxes that may write there (codex) can run this too.
  UV_CACHE_DIR="$CONFIG_DIR/uv-cache" uv run --quiet --with openpyxl --with defusedxml python3 -I "$SCRIPT_DIR/xlsx_tool.py" "${args[@]}" || rc=$?
  ((rc == 0)) || die "$EX_HTTP" "xlsx conversion failed for $id"
}

# Print the title of the sheet with the given gid (first sheet when gid is empty).
native_title_for_gid() {
  get_json "$SHEETS_API/spreadsheets/$1?fields=$(uri_encode 'sheets.properties(sheetId,title)')" |
    jq -r --arg gid "$2" '.sheets | (if $gid == "" then .[0] else (map(select((.properties.sheetId | tostring) == $gid)) | .[0]) end) | .properties.title // empty'
}

native_gid_for_title() {
  get_json "$SHEETS_API/spreadsheets/$1?fields=$(uri_encode 'sheets.properties(sheetId,title)')" |
    jq -r --arg t "$2" '.sheets | map(select(.properties.title == $t)) | .[0].properties.sheetId // empty'
}

prepare_out() {
  [[ -n "$1" ]] || die "$EX_USAGE" "--out DIR is required"
  mkdir -p "$1"
}

report_saved() {
  printf 'saved: %s (%s bytes, %s lines)\n' "$1" "$(wc -c <"$1" | tr -d ' ')" "$(wc -l <"$1" | tr -d ' ')"
}

files_tsv() {
  jq -r '(["id","name","mimeType","modifiedTime","webViewLink"] | @tsv),
         (.files[] | [.id, .name, .mimeType, .modifiedTime, .webViewLink] | @tsv)'
}

clamp_limit() {
  local n="$1"
  [[ "$n" =~ ^[0-9]+$ ]] || die "$EX_USAGE" "--limit must be a number"
  ((n < 1)) && n=1
  ((n > 100)) && n=100
  printf '%s\n' "$n"
}

list_files() {
  local q="$1" limit="$2" order="$3"
  get_json "$DRIVE_API/files?corpora=allDrives&includeItemsFromAllDrives=true&supportsAllDrives=true&pageSize=$limit&orderBy=$(uri_encode "$order")&fields=$(uri_encode "files($FILE_FIELDS)")&q=$(uri_encode "$q")" | files_tsv
}

cmd_login() {
  local account="${1:-}"
  if [[ -n "$account" ]]; then
    gcloud_dedicated auth login "$account" --enable-gdrive-access
  else
    gcloud_dedicated auth login --enable-gdrive-access
  fi
}

cmd_status() {
  fetch_token
  printf 'ok: token available for %s (config: %s)\n' \
    "$(gcloud_dedicated config get-value account 2>/dev/null)" "$CONFIG_DIR"
}

cmd_meta() {
  local id
  id="$(extract_id "$1")"
  file_meta "$id" | jq -r '[.id, .name, .mimeType, .modifiedTime, .webViewLink] | @tsv'
}

cmd_doc() {
  local src="" out=""
  while (($#)); do
    [[ "$1" != --* || $# -ge 2 ]] || die "$EX_USAGE" "$1 needs a value"
    case "$1" in
      --out) out="${2:-}"; shift 2 ;;
      *) src="$1"; shift ;;
    esac
  done
  [[ -n "$src" ]] || die "$EX_USAGE" "doc needs <url|id>"
  local id
  id="$(extract_id "$src")"
  prepare_out "$out"
  local url dest="$out/$id.md"
  url="$(doc_export_url "$id")"
  http_get "$url" "$dest"
  report_saved "$dest"
}

cmd_sheet_list() {
  local id
  id="$(extract_id "$1")"
  local kind
  kind="$(sheet_kind "$id")"
  if [[ "$kind" == xlsx ]]; then
    xlsx_run "$id" list @XLSX@
    return
  fi
  get_json "$SHEETS_API/spreadsheets/$id?fields=$(uri_encode 'sheets.properties(sheetId,title,gridProperties(rowCount,columnCount))')" |
    jq -r '(["gid","title","rows","cols"] | @tsv),
           (.sheets[].properties | [.sheetId, .title, .gridProperties.rowCount, .gridProperties.columnCount] | @tsv)'
}

cmd_sheet() {
  local src="" out="" gid="" title="" range=""
  while (($#)); do
    [[ "$1" != --* || $# -ge 2 ]] || die "$EX_USAGE" "$1 needs a value"
    case "$1" in
      --out) out="${2:-}"; shift 2 ;;
      --gid) gid="${2:-}"; shift 2 ;;
      --sheet) title="${2:-}"; shift 2 ;;
      --range) range="${2:-}"; shift 2 ;;
      *) src="$1"; shift ;;
    esac
  done
  [[ -n "$src" ]] || die "$EX_USAGE" "sheet needs <url|id>"
  [[ -z "$gid" || "$gid" =~ ^[0-9]+$ ]] || die "$EX_USAGE" "--gid must be a number"
  [[ -z "$gid" || -z "$title" ]] || die "$EX_USAGE" "use either --gid or --sheet, not both"
  local id kind
  id="$(extract_id "$src")"
  [[ -n "$gid" || -n "$title" ]] || gid="$(extract_gid "$src")"
  prepare_out "$out"
  kind="$(sheet_kind "$id")"
  local tag="${gid:-${title:-first}}"
  tag="${tag//[\/[:space:]]/_}${range:+-${range//[^A-Za-z0-9]/_}}"
  local dest="$out/$id-$tag.csv"

  # .xlsx with a tab title or a range: convert locally (Sheets API does not read Office files).
  if [[ "$kind" == xlsx && ( -n "$title" || -n "$range" ) ]]; then
    [[ -z "$gid" ]] || die "$EX_USAGE" "for .xlsx, pick the tab with --sheet TITLE (see sheet-list); a gid cannot be mapped to a tab"
    xlsx_run "$id" csv @XLSX@ "$dest" ${title:+--sheet "$title"} ${range:+--range "$range"}
    report_saved "$dest"
    return
  fi

  if [[ -z "$range" ]]; then
    if [[ -n "$title" ]]; then
      gid="$(native_gid_for_title "$id" "$title")"
      [[ -n "$gid" ]] || die "$EX_NOTFOUND" "no sheet titled '$title' in $id"
    fi
    http_get "https://docs.google.com/spreadsheets/d/$id/export?format=csv${gid:+&gid=$gid}" "$dest"
    report_saved "$dest"
    return
  fi

  if [[ -z "$title" ]]; then
    title="$(native_title_for_gid "$id" "$gid")"
    [[ -n "$title" ]] || die "$EX_NOTFOUND" "no sheet with gid ${gid:-<first>} in $id"
  fi
  local a1="'${title//\'/\'\'}'!$range"
  get_json "$SHEETS_API/spreadsheets/$id/values/$(uri_encode "$a1")" | jq -r '.values // [] | .[] | @csv' >"$dest"
  report_saved "$dest"
}

cmd_search() {
  local term="" type="" limit=30
  while (($#)); do
    [[ "$1" != --* || $# -ge 2 ]] || die "$EX_USAGE" "$1 needs a value"
    case "$1" in
      --type) type="${2:-}"; shift 2 ;;
      --limit) limit="$(clamp_limit "${2:-}")"; shift 2 ;;
      *) term="$1"; shift ;;
    esac
  done
  [[ -n "$term" ]] || die "$EX_USAGE" "search needs <name-substring>"
  local escaped="${term//\\/\\\\}"
  escaped="${escaped//\'/\\\'}"
  local q="name contains '$escaped' and trashed = false"
  case "$type" in
    "") ;;
    doc) q+=" and mimeType = '$MIME_DOC'" ;;
    sheet) q+=" and mimeType = '$MIME_SHEET'" ;;
    folder) q+=" and mimeType = '$MIME_FOLDER'" ;;
    *) die "$EX_USAGE" "--type must be doc, sheet, or folder" ;;
  esac
  list_files "$q" "$limit" "modifiedTime desc"
}

cmd_ls() {
  local src="" limit=100
  while (($#)); do
    [[ "$1" != --* || $# -ge 2 ]] || die "$EX_USAGE" "$1 needs a value"
    case "$1" in
      --limit) limit="$(clamp_limit "${2:-}")"; shift 2 ;;
      *) src="$1"; shift ;;
    esac
  done
  [[ -n "$src" ]] || die "$EX_USAGE" "ls needs <folder-url|id>"
  local id
  id="$(extract_id "$src")"
  list_files "'$id' in parents and trashed = false" "$limit" "folder,name"
}

main() {
  (($#)) || { usage; exit "$EX_USAGE"; }
  local cmd="$1"
  shift
  # Fetch once here so subshells (pipelines, $(...)) inherit TOKEN instead of re-running gcloud.
  case "$cmd" in
    meta|doc|sheet-list|sheet|search|ls) fetch_token ;;
  esac
  case "$cmd" in
    login) cmd_login "$@" ;;
    status) cmd_status ;;
    meta) (($#)) || die "$EX_USAGE" "meta needs <url|id>"; cmd_meta "$1" ;;
    doc) cmd_doc "$@" ;;
    sheet-list) (($#)) || die "$EX_USAGE" "sheet-list needs <url|id>"; cmd_sheet_list "$1" ;;
    sheet) cmd_sheet "$@" ;;
    search) cmd_search "$@" ;;
    ls) cmd_ls "$@" ;;
    -h|--help|help) usage ;;
    *) usage; exit "$EX_USAGE" ;;
  esac
}

main "$@"
