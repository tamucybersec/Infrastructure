#!/bin/sh
set -eu

# Usage: encrypt.sh <src=secrets> <dest=secrets.enc>
# Encrypts files in src recursively and outputs to dest

src="${1:-secrets}"
dest="${2:-secrets.enc}"

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
  mkdir -p "$outdir"
  sops --age "$(cat /age.pub)" -e "$f" > "$outdir/$outname"
done
