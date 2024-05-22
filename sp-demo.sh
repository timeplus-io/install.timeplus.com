#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
REQUIRED_TOOLS=("curl" "unzip" "docker" "make")

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command_exists "$tool"; then
        echo "Error: $tool is not installed."
        exit 1
    fi
done

# URL to the zip file
ZIP_URL="https://timeplus.io/dist/timeplus_enterprise/sp-demo-20240522.zip"
ZIP_FILE="sp-demo.zip"
INSTALL_DIR="sp-demo"

# Download the zip file
echo "Downloading demo setup..."
curl -L -o $ZIP_FILE $ZIP_URL

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the zip file. Exiting."
    exit 1
fi

# Unzip the downloaded file
echo "Unzipping the demo setup..."
unzip $ZIP_FILE -d $INSTALL_DIR

# Check if the unzip was successful
if [ $? -ne 0 ]; then
    echo "Failed to unzip the file. Exiting."
    exit 1
fi

# Navigate to the installation directory
cd $INSTALL_DIR

# Start Docker Compose
echo "Starting Docker Compose...Please access the UI via http://localhost:8000"
make start_init


# Check if Docker Compose was successful
if [ $? -ne 0 ]; then
    echo "Failed to start Docker Compose. Exiting."
    exit 1
fi

echo "Demo system is up and running!"
