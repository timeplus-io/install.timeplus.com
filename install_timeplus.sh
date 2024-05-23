#!/bin/bash

LATEST_TAG=2.1.6.0
# Identify the system's OS and architecture
OS=$(uname -s) # Linux or Darwin
ARCH=$(uname -m) # arm64(on Darwin) or x86_64(on Linux or Darwin)

# for local debug only
OS=Linux
ARCH=x86_64

# normalize the OS and ARCH
case $OS in
  "Darwin")
    OS="darwin"
    ;;
  "Linux")
    OS="linux"
    ;;
  *)
esac

case $ARCH in
  "x86_64")
    ARCH="amd64"
    ;;
  "arm64" | "aarch64")
    ARCH="arm64"
    ;;
  *)
esac

# Binary file name
BINARY_FILE="timeplus-enterprise-v${LATEST_TAG}-${OS}-${ARCH}.tar.gz"

# Download URL
DOWNLOAD_URL="https://timeplus.io/dist/timeplus_enterprise/${BINARY_FILE}"

# Download the binary
echo "Downloading $BINARY_FILE..."
curl -L -o "$BINARY_FILE" "$DOWNLOAD_URL"

# Check if the download was successful
if [ $? -eq 0 ]; then
  tar xfv $BINARY_FILE
  cd timeplus/bin
  ./timeplus start
else
  echo "Download failed or the binary for $OS-$ARCH is not available." >&2
  exit 1
fi
