#!/usr/bin/env bash
# Combine images (local files/dirs/globs, URL lists, or direct URLs) into one PDF.
#
# Usage:
#   images_to_pdf.sh SOURCE... -o OUTPUT.pdf [options]
#
# SOURCE may be a directory, a glob, an image file, a text/markdown/html file
# containing image URLs, or an http(s) URL. Sources are expanded in the order
# given; files inside a directory or glob are sorted naturally (sort -V).
set -euo pipefail

die() { printf 'images-to-pdf: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*" >&2; }

OUT=""
PRESET="balanced"
MAX_DIM=""
QUALITY=""
DPI=""
COMPRESS=""
ORDER=""
CONTACT_SHEET=""
WORKDIR=""
KEEP=0
FORCE=0
DRY_RUN=0
SOURCES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)        OUT="${2:?--output needs a path}"; shift 2 ;;
    --preset)           PRESET="${2:?--preset needs a value}"; shift 2 ;;
    --max-dim)          MAX_DIM="${2:?}"; shift 2 ;;
    --quality)          QUALITY="${2:?}"; shift 2 ;;
    --dpi)              DPI="${2:?}"; shift 2 ;;
    --order)            ORDER="${2:?}"; shift 2 ;;
    --contact-sheet)    CONTACT_SHEET="${2:?}"; shift 2 ;;
    --workdir)          WORKDIR="${2:?}"; shift 2 ;;
    --keep)             KEEP=1; shift ;;
    --force)            FORCE=1; shift ;;
    --dry-run)          DRY_RUN=1; shift ;;
    -h|--help)          sed -n '2,12p' "$0"; exit 0 ;;
    --)                 shift; while [[ $# -gt 0 ]]; do SOURCES+=("$1"); shift; done ;;
    -*)                 die "unknown option: $1" ;;
    *)                  SOURCES+=("$1"); shift ;;
  esac
done

[[ ${#SOURCES[@]} -gt 0 ]] || die "no SOURCE given"
[[ -n $OUT || $DRY_RUN -eq 1 ]] || die "--output is required"
command -v magick >/dev/null 2>&1 || die "ImageMagick (magick) not found. Install: brew install imagemagick"

# ---- presets: MAX_DIM / QUALITY / DPI chosen so the widest page is ~10.5in ----
case "$PRESET" in
  balanced) P_DIM=2100; P_Q=90; P_DPI=200; P_COMP=JPEG ;;
  high)     P_DIM=3150; P_Q=93; P_DPI=300; P_COMP=JPEG ;;
  small)    P_DIM=1500; P_Q=85; P_DPI=150; P_COMP=JPEG ;;
  lossless) P_DIM=0;    P_Q="";  P_DPI=300; P_COMP=Zip ;;
  *) die "unknown preset: $PRESET (balanced|high|small|lossless)" ;;
esac
MAX_DIM="${MAX_DIM:-$P_DIM}"
DPI="${DPI:-$P_DPI}"
COMPRESS="${COMPRESS:-$P_COMP}"
if [[ -n $QUALITY && $COMPRESS != JPEG ]]; then
  log "note: --quality is ignored by the $PRESET preset (no JPEG recompression)"
fi
[[ -n $QUALITY ]] || QUALITY="$P_Q"

# Absolute path of a file whose parent exists; used to compare output targets.
abspath() {
  local dir base
  dir="$(cd "$(dirname "$1")" && pwd -P)"
  base="$(basename "$1")"
  printf '%s/%s\n' "$dir" "$base"
}
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# -e alone is false for a dangling symlink, which would then be silently replaced.
exists() { [[ -e $1 || -L $1 ]]; }

# Publish a finished temp file. Without --force this uses ln, which fails if the
# destination appeared while converting, so a concurrent writer is never clobbered.
publish() {
  local tmp="$1" dest="$2" what="$3"
  if [[ $FORCE -eq 1 ]]; then
    mv -f "$tmp" "$dest"
  else
    ln "$tmp" "$dest" 2>/dev/null \
      || die "$what appeared while converting: $dest (pass --force to overwrite)"
    rm -f "$tmp"
  fi
}

if [[ $DRY_RUN -eq 0 ]]; then
  # A directory destination would make ln/mv drop the temp file *inside* it and
  # report success, leaving a hidden PDF and no artifact at the requested path.
  if [[ -d $OUT ]]; then
    die "--output is a directory: $OUT (give a file path)"
  fi
  if [[ -n $CONTACT_SHEET && -d $CONTACT_SHEET ]]; then
    die "--contact-sheet is a directory: $CONTACT_SHEET (give a file path)"
  fi
  if exists "$OUT" && [[ $FORCE -eq 0 ]]; then
    die "output already exists: $OUT (pass --force to overwrite)"
  fi
  if [[ -n $CONTACT_SHEET ]] && exists "$CONTACT_SHEET" && [[ $FORCE -eq 0 ]]; then
    die "contact sheet already exists: $CONTACT_SHEET (pass --force to overwrite)"
  fi
fi

TMP_OUT=""
TMP_SHEET=""
cleanup() {
  [[ -z $TMP_OUT ]] || rm -f "$TMP_OUT"
  [[ -z $TMP_SHEET ]] || rm -f "$TMP_SHEET"
  [[ -z ${WORKDIR:-} || $KEEP -eq 1 ]] || rm -rf "$WORKDIR"
}
trap cleanup EXIT

# Created only when something is actually fetched, so --dry-run writes nothing.
ensure_workdir() {
  [[ -z ${DL_DIR:-} ]] || return 0
  if [[ -n $WORKDIR ]]; then
    mkdir -p "$WORKDIR"
    KEEP=1
  else
    WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/images-to-pdf.XXXXXX")"
  fi
  DL_DIR="$WORKDIR/downloads"
  mkdir -p "$DL_DIR"
}

# ---- URL fetch: GitHub attachments need a token for the 302, but the signed
#      redirect target rejects the Authorization header, so follow it in two steps.
fetch_url() {
  local url="$1" out="$2" token loc
  command -v curl >/dev/null 2>&1 || die "curl not found (needed for URL sources)"
  if [[ $url == https://github.com/* ]] && command -v gh >/dev/null 2>&1; then
    token="$(gh auth token 2>/dev/null || true)"
    if [[ -n $token ]]; then
      # Feed the header through a stdin config file: an -H argument would expose
      # the token in the process list, and a temp file would leave it on disk.
      loc="$(printf 'header = "Authorization: token %s"\n' "$token" \
             | curl -sS -K - -o /dev/null -w '%{redirect_url}' "$url" || true)"
      [[ -n $loc ]] && url="$loc"
    fi
  fi
  curl -fsSL -o "$out" "$url" || die "download failed (HTTP error or unreachable): $url"
}

IMG_EXT_RE='\.(png|jpe?g|webp|tiff?|gif|bmp|heic)$'

collect_from_dir() {
  local dir="$1" f found=0
  while IFS= read -r f; do
    ITEMS+=("$f"); found=1
  done < <(find "$dir" -maxdepth 1 -type f -print | grep -Ei "$IMG_EXT_RE" | sort -V)
  [[ $found -eq 1 ]] || die "no images found in directory: $dir"
}

collect_from_listfile() {
  local file="$1" urls
  # Prefer explicit img src="..." attributes; fall back to bare http(s) URLs.
  urls="$(grep -oE 'src="[^"]+"' "$file" | sed 's/^src="//; s/"$//' || true)"
  [[ -n $urls ]] || urls="$(grep -oE 'https?://[^"'"'"'[:space:]<>)]+' "$file" || true)"
  [[ -n $urls ]] || die "no image URLs found in: $file"
  while IFS= read -r u; do [[ -n $u ]] && ITEMS+=("$u"); done <<< "$urls"
}

ITEMS=()
for s in "${SOURCES[@]}"; do
  if [[ $s == http://* || $s == https://* ]]; then
    ITEMS+=("$s")
  elif [[ -d $s ]]; then
    collect_from_dir "$s"
  elif [[ -f $s ]]; then
    if printf '%s' "$s" | grep -Eiq "$IMG_EXT_RE"; then ITEMS+=("$s"); else collect_from_listfile "$s"; fi
  else
    # Unexpanded glob (quoted by the caller, or zsh nomatch). Clearing IFS around
    # the expansion suppresses word splitting, so a pattern or path may contain
    # spaces; pathname expansion still runs. compgen -G cannot do this: it splits
    # the pattern internally and misses "dir with space/*.png".
    saved_ifs="$IFS"
    IFS=
    shopt -s nullglob
    matches=($s)
    shopt -u nullglob
    IFS="$saved_ifs"
    # A word with no wildcard survives nullglob unchanged, so confirm it exists.
    [[ ${#matches[@]} -gt 0 && -e ${matches[0]} ]] || die "source not found: $s"
    while IFS= read -r f; do ITEMS+=("$f"); done < <(printf '%s\n' "${matches[@]}" | sort -V)
  fi
done

[[ ${#ITEMS[@]} -gt 0 ]] || die "no images resolved from the given sources"

# ---- optional reordering: --order '1-12,15,14,13' (1-indexed, ranges allowed).
#      Applied before downloading so unselected URLs are never fetched. ----
if [[ -n $ORDER ]]; then
  SELECTED=()
  IFS=',' read -r -a specs <<< "$ORDER"
  for spec in "${specs[@]}"; do
    spec="${spec// /}"
    [[ -n $spec ]] || continue
    if [[ $spec =~ ^([0-9]+)-([0-9]+)$ ]]; then
      a="${BASH_REMATCH[1]}"; b="${BASH_REMATCH[2]}"
      if [[ $a -le $b ]]; then
        for ((i = a; i <= b; i++)); do SELECTED+=("$i"); done
      else
        for ((i = a; i >= b; i--)); do SELECTED+=("$i"); done
      fi
    elif [[ $spec =~ ^[0-9]+$ ]]; then
      SELECTED+=("$spec")
    else
      die "bad --order token: $spec"
    fi
  done
  REORDERED=()
  for n in "${SELECTED[@]}"; do
    [[ $n -ge 1 && $n -le ${#ITEMS[@]} ]] || die "--order index out of range: $n (1..${#ITEMS[@]})"
    REORDERED+=("${ITEMS[$((n - 1))]}")
  done
  [[ ${#REORDERED[@]} -eq ${#ITEMS[@]} ]] || \
    log "note: --order selects ${#REORDERED[@]} of ${#ITEMS[@]} pages"
  ITEMS=("${REORDERED[@]}")
fi

if [[ $DRY_RUN -eq 1 ]]; then
  n=0
  for p in "${ITEMS[@]}"; do n=$((n + 1)); printf '%3d  %s\n' "$n" "$p"; done
  log "${#ITEMS[@]} page(s) resolved (dry run, nothing written)"
  exit 0
fi

# ---- output targets: create parents only now, so a failed source resolution or
#      a dry run leaves no empty directories behind ----
mkdir -p "$(dirname "$OUT")"
if [[ -n $CONTACT_SHEET ]]; then
  mkdir -p "$(dirname "$CONTACT_SHEET")"
  out_abs="$(abspath "$OUT")"
  sheet_abs="$(abspath "$CONTACT_SHEET")"
  # Compare case-folded as well: on a case-insensitive volume (the macOS default)
  # Out.pdf and out.pdf are one file, and the sheet would overwrite the PDF.
  if [[ "$out_abs" == "$sheet_abs" || "$(lower "$out_abs")" == "$(lower "$sheet_abs")" ]]; then
    die "--output and --contact-sheet point at the same file: $OUT"
  fi
fi

# ---- materialize: download URLs, keep local paths as-is ----
PAGES=()
idx=0
for item in "${ITEMS[@]}"; do
  idx=$((idx + 1))
  if [[ $item == http://* || $item == https://* ]]; then
    ensure_workdir
    tmp="$DL_DIR/$(printf '%04d' "$idx").bin"
    fetch_url "$item" "$tmp"
    fmt="$(magick identify -ping -format '%m' "$tmp" 2>/dev/null | head -c 8 || true)"
    [[ -n $fmt ]] || die "not an image (auth or 404?): $item -> $(head -c 80 "$tmp")"
    ext="$(printf '%s' "$fmt" | tr '[:upper:]' '[:lower:]')"
    mv "$tmp" "$DL_DIR/$(printf '%04d' "$idx").$ext"
    PAGES+=("$DL_DIR/$(printf '%04d' "$idx").$ext")
  else
    [[ -f $item ]] || die "file not found: $item"
    PAGES+=("$item")
  fi
done

# ---- build the PDF in a single pass (no intermediate JPEG generation) ----
ARGS=("${PAGES[@]}" -background white -alpha remove -alpha off)
[[ ${MAX_DIM:-0} -gt 0 ]] && ARGS+=(-resize "${MAX_DIM}x${MAX_DIM}>")
ARGS+=(-units PixelsPerInch -density "$DPI" -compress "$COMPRESS")
if [[ $COMPRESS == JPEG ]]; then
  ARGS+=(-quality "$QUALITY" -sampling-factor 4:4:4)
fi
# Render to a sibling temp file and rename only on success, so a failed run
# never leaves a truncated PDF at the destination.
TMP_OUT="$(mktemp "$(dirname "$OUT")/.images-to-pdf.XXXXXX")"
ARGS+=(-strip "pdf:$TMP_OUT")

magick "${ARGS[@]}"
publish "$TMP_OUT" "$OUT" "output"
TMP_OUT=""

# ---- optional contact sheet for visual order checking (tiles read left->right) ----
if [[ -n $CONTACT_SHEET ]]; then
  # Derive the output format from the basename only: dirname components may
  # contain dots (./proof, dir.v2/proof), and a dotfile or trailing dot has no
  # usable extension. Fall back to jpg in every ambiguous case.
  sheet_base="$(basename "$CONTACT_SHEET")"
  sheet_ext="jpg"
  if [[ $sheet_base == *.* && $sheet_base != .* && $sheet_base != *. ]]; then
    sheet_ext="$(lower "${sheet_base##*.}")"
  fi
  TMP_SHEET="$(mktemp "$(dirname "$CONTACT_SHEET")/.images-to-pdf-sheet.XXXXXX")"
  # montage exits non-zero on installs with no registered font even though it
  # still writes the sheet, so validate the artifact instead of trusting status:
  # the temp file must be readable back as an image before it replaces anything.
  magick montage "${PAGES[@]}" +label -tile 4x -geometry '420x+8+8' \
    -background white "$sheet_ext:$TMP_SHEET" 2>/dev/null || true
  # Full decode, not identify -ping: a header-only check would pass a sheet whose
  # pixel data was truncated, and that would then replace a good existing sheet.
  magick "$TMP_SHEET" null: >/dev/null 2>&1 \
    || die "contact sheet generation failed: $CONTACT_SHEET"
  if exists "$CONTACT_SHEET" && [[ $CONTACT_SHEET -ef $OUT ]]; then
    die "contact sheet path resolves to the output PDF: $CONTACT_SHEET"
  fi
  publish "$TMP_SHEET" "$CONTACT_SHEET" "contact sheet"
  TMP_SHEET=""
fi

pages="$(grep -a -c '/Type /Page$' "$OUT" || true)"
size="$(ls -lh "$OUT" | awk '{print $5}')"
q_report="n/a"
[[ $COMPRESS == JPEG ]] && q_report="$QUALITY"
log "wrote $OUT  (${pages:-?} pages, $size, preset=$PRESET dim=${MAX_DIM} q=${q_report} dpi=$DPI)"
[[ -n $CONTACT_SHEET ]] && log "contact sheet: $CONTACT_SHEET"
exit 0
