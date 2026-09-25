#!/bin/bash
set -euo pipefail

# Usage: encrypt.sh <src=secrets> <dest=secrets.enc>
# Encrypts files in src recursively and outputs to dest.

src="${1:-secrets}"
dest="${2:-secrets.enc}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

normalized() {
  local f="$1" base ext
  base="$(basename "$f")"
  ext=""
  [[ "$base" == *.* ]] && ext=".${base##*.}"
  sops --age "$(cat /age.pub)" -e "$f" > "$tmp/norm.enc$ext"
  sops -d "$tmp/norm.enc$ext"
}

find "$src" -type f | while read -r f; do
  rel="${f#"$src"/}"
  dir="$(dirname "$rel")"
  base="$(basename "$rel")"
  case "$base" in
    *.*) outname="${base%.*}.enc.${base##*.}" ;;
    *) outname="${base}.enc" ;;
  esac
  outdir="$dest/$dir"
  [ "$dir" = "." ] && outdir="$dest"
  out="$outdir/$outname"

  if [ -f "$out" ] && cmp -s <(sops -d "$out" 2>/dev/null) <(normalized "$f"); then
    continue
  fi

  mkdir -p "$outdir"
  sops --age "$(cat /age.pub)" -e "$f" > "$out"
done
