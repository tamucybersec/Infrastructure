#!/bin/sh
set -eu

# Usage: scan.sh <image> [trivy flags...]
# Scan an image for vulnerabilities during CI, failing on findings

image="$1"
shift

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v trivy_cache:/root/.cache/trivy \
  -v "$GITHUB_WORKSPACE":/work:ro \
  -w /work \
  -e TRIVY_SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}" \
  -e TRIVY_EXIT_CODE="${TRIVY_EXIT_CODE:-1}" \
  -e TRIVY_IGNORE_UNFIXED="${TRIVY_IGNORE_UNFIXED:-true}" \
  -e TRIVY_NO_PROGRESS=true \
  "${TRIVY_IMAGE:-aquasec/trivy:0.74.0}" \
  image "$@" "$image"
