#!/bin/sh

# Be POSIX-sh compatible; enable strict mode where available
set -eu
# pipefail is not POSIX; only enable if supported
(set -o pipefail) 2>/dev/null || true

# GitHub user/repo
USER_REPO="timeplus-io/proton"

# Fetch the latest release tag from GitHub
LATEST_TAG=$(curl -fsSL https://api.github.com/repos/$USER_REPO/releases/latest | grep 'tag_name' | cut -d\" -f4 || true)

# Check if the tag is empty
if [ -z "${LATEST_TAG:-}" ]; then
  echo "Failed to fetch the latest release tag from GitHub." >&2
  exit 1
fi

# Identify the system's OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

# Map the architecture to the binary naming convention
case $ARCH in
  "x86_64")
    ARCH="x86_64"
    ;;
  "arm64" | "aarch64")
    if [ "$OS" = "Darwin" ]; then
      ARCH="arm64"
    else
      ARCH="aarch64"
    fi
    ;;
  *)
    echo "Currently, https://github.com/timeplus-io/proton does not support $OS-$ARCH releases. You can try our docker image\
            with  \
            \$ docker pull ghcr.io/timeplus-io/proton" >&2
    exit 1
    ;;
esac

NAME="proton-${LATEST_TAG}-${OS}-${ARCH}"
TARBALL="${NAME}.tar.gz"
TARGET_FILE="proton"

# Primary and fallback download locations
PRIMARY_BASE="https://d.timeplus.com"
FALLBACK_BASE="https://github.com/${USER_REPO}/releases/download/${LATEST_TAG}"

# Check if the proton file exists

# Fix me, what if I wanna use this script 3 times?
# if `proton` not exist, we use proton
# else
#     1.use `"proton-${LATEST_TAG}-${OS}-${ARCH}"` (by default)
#     2.overwrite it(only work on manual bash install.sh)

if [ -f "$TARGET_FILE" ]; then
  printf %s "'proton' file already exists. Do you want to overwrite it? (y/n): "
  # shellcheck disable=SC2162
  read answer || answer="n"
  case "$answer" in
    y|Y) TARGET_FILE="proton" ;;
    *)   TARGET_FILE=$NAME ;;
  esac
fi

# Helpers
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
# Use EXIT (or 0) for broad compatibility
trap cleanup EXIT 2>/dev/null || trap cleanup 0

download_to() {
  # $1=url $2=dest
  curl -fL --retry 3 --retry-delay 2 -o "$2" "$1"
}

extract_tarball() {
  # $1=tar.gz path, extracts NAME to $tmpdir
  if command -v tar >/dev/null 2>&1; then
    tar -xzf "$1" -C "$tmpdir"
    return 0
  else
    return 1
  fi
}

echo "Detected: ${OS}-${ARCH}, latest: ${LATEST_TAG}"

SUCCESS=0

echo "Attempting tarball from primary CDN: ${PRIMARY_BASE}/${TARBALL}"
if download_to "${PRIMARY_BASE}/${TARBALL}" "$tmpdir/${TARBALL}" && extract_tarball "$tmpdir/${TARBALL}" && [ -f "$tmpdir/${NAME}" ]; then
  mv "$tmpdir/${NAME}" "$TARGET_FILE"
  SUCCESS=1
else
  echo "Tarball not available on primary. Trying raw binary: ${PRIMARY_BASE}/${NAME}"
  if download_to "${PRIMARY_BASE}/${NAME}" "$tmpdir/${NAME}" && [ -s "$tmpdir/${NAME}" ]; then
    mv "$tmpdir/${NAME}" "$TARGET_FILE"
    SUCCESS=1
  else
    echo "Primary CDN failed. Trying GitHub release assets..."
    if download_to "${FALLBACK_BASE}/${TARBALL}" "$tmpdir/${TARBALL}" && extract_tarball "$tmpdir/${TARBALL}" && [ -f "$tmpdir/${NAME}" ]; then
      mv "$tmpdir/${NAME}" "$TARGET_FILE"
      SUCCESS=1
    else
      echo "GitHub tarball unavailable. Trying GitHub raw binary: ${FALLBACK_BASE}/${NAME}"
      if download_to "${FALLBACK_BASE}/${NAME}" "$tmpdir/${NAME}" && [ -s "$tmpdir/${NAME}" ]; then
        mv "$tmpdir/${NAME}" "$TARGET_FILE"
        SUCCESS=1
      fi
    fi
  fi
fi

if [ "$SUCCESS" -eq 1 ]; then
  chmod u+x "$TARGET_FILE"
  echo "Download complete: $TARGET_FILE"
  echo "
To interact with Proton:
1. Start the Proton server(data store in current folder ./proton-data/ ):
   ./$TARGET_FILE server

2. In a separate terminal, connect to the server:
   ./$TARGET_FILE client
   (Note: If you encounter a 'connection refused' error, use: ./$TARGET_FILE client --host 127.0.0.1)

3. To terminate the server, press ctrl+c in the server terminal.

For detailed usage and more information, check out the Timeplus documentation:
https://docs.timeplus.com/"
else
  echo "Download failed or the binary for $OS-$ARCH is not available." >&2
  exit 1
fi

if [ "${OS}" = "Linux" ]
then
    echo
    echo "You can also install it(data store in /var/lib/proton/):
    sudo ./${TARGET_FILE} install"
fi
