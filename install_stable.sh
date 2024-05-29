#!/bin/bash

# Identify the system's OS and architecture
OS=$(uname -s) # Linux or Darwin
ARCH=$(uname -m) # arm64(on Darwin) or x86_64(on Linux or Darwin) or aarch64(on Linux)

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
BINARY_FILE="timeplus-enterprise.tar.gz"

# Download URL
DOWNLOAD_URL="https://install.timeplus.com/stable-${OS}-${ARCH}.tar.gz"

# Download the binary
echo "Downloading $DOWNLOAD_URL..."
# Download the file and capture the HTTP status code
HTTP_STATUS=$(curl -L -w "%{http_code}" -o "$BINARY_FILE" "$DOWNLOAD_URL")

# Check if the HTTP status code indicates success (200)
if [ "$HTTP_STATUS" -eq 200 ]; then
  echo "Download complete. Extracting package..."
  tar xfv $BINARY_FILE
  cd timeplus/bin
  echo "Starting Timeplus Enterprise..."
  ./timeplus start
  echo "Successfully downloaded and started Timeplus Enterprise."
  echo "You can visit http://localhost:8000 or access the SQL client via 'timeplus/bin/timeplusd client -h 127.0.0.1'"
  echo "To learn more, please check the documentation at https://docs.timeplus.com/singlenode_install"
else
  rm $BINARY_FILE
  echo "Bare metal package for $OS-$ARCH is not available yet. Please check Timeplus docs to install via Docker. (HTTP status code: $HTTP_STATUS)" >&2
  exit 1
fi
