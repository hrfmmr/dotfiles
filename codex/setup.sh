#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC_DIR="${SCRIPT_DIR}/skills"
AGENTS_SRC_FILE="${SCRIPT_DIR}/AGENTS.md"
CODEX_DST_DIR="${HOME}/.codex"
SKILLS_DST_DIR="${HOME}/.codex/skills"

if [[ ! -d "${SKILLS_SRC_DIR}" ]]; then
  echo "error: skills source directory not found: ${SKILLS_SRC_DIR}" >&2
  exit 1
fi

if [[ ! -f "${AGENTS_SRC_FILE}" ]]; then
  echo "error: AGENTS.md source file not found: ${AGENTS_SRC_FILE}" >&2
  exit 1
fi

mkdir -p "${CODEX_DST_DIR}" "${SKILLS_DST_DIR}"

find "${SKILLS_SRC_DIR}" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
  skill_name="$(basename "${skill_dir}")"
  dst="${SKILLS_DST_DIR}/${skill_name}"

  if [[ -e "${dst}" && ! -L "${dst}" ]]; then
    echo "skip: ${dst} already exists as a file or directory"
    continue
  fi

  ln -sfn "${skill_dir}" "${dst}"
  echo "linked: ${dst} -> ${skill_dir}"
done

AGENTS_DST_FILE="${CODEX_DST_DIR}/AGENTS.md"
if [[ -e "${AGENTS_DST_FILE}" && ! -L "${AGENTS_DST_FILE}" ]]; then
  echo "skip: ${AGENTS_DST_FILE} already exists as a file or directory"
else
  ln -sfn "${AGENTS_SRC_FILE}" "${AGENTS_DST_FILE}"
  echo "linked: ${AGENTS_DST_FILE} -> ${AGENTS_SRC_FILE}"
fi
