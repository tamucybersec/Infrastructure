#!/bin/sh
set -eu

# Usage: decrypt.sh <src=secrets.enc> <dest=secrets>
# Decrypts files in src recursively and outputs to dest

src="${1:-secrets.enc}"
dest="${2:-secrets}"

find "$src" -type f | while read -r f; do
  rel="${f#"$src"/}"
  dir="$(dirname "$rel")"
  base="$(basename "$rel")"
  case "$base" in
    *.enc.*) outname="${base%.enc.*}.${base##*.}" ;;
    *.enc) outname="${base%.enc}" ;;
    *) continue ;;
  esac
  outdir="$dest/$dir"
  [ "$dir" = "." ] && outdir="$dest"
  mkdir -p "$outdir"
  sops -d "$f" > "$outdir/$outname"
done
