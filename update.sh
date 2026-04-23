#!/bin/bash

PROJECT="velocity"
USER_AGENT="velocity-updater/1.0.0 (contact@me.com)"
BASE_URL="https://fill.papermc.io/v3/projects"

# 1. Fetch versions
VERSIONS_RESPONSE=$(curl -s -H "User-Agent: $USER_AGENT" "${BASE_URL}/${PROJECT}/versions")

# 2. Pick the latest version (first in the returned list)
FOUND_VERSION=$(echo "$VERSIONS_RESPONSE" | jq -r '.versions[0].version.id')

if [ -z "$FOUND_VERSION" ] || [ "$FOUND_VERSION" = "null" ]; then
    echo "Error: Could not determine latest version."
    exit 1
fi

echo "Using latest version: $FOUND_VERSION"

# 3. Fetch builds and extract the URL
echo "Fetching builds for $FOUND_VERSION..."
BUILDS_RESPONSE=$(curl -s -H "User-Agent: $USER_AGENT" "${BASE_URL}/${PROJECT}/versions/${FOUND_VERSION}/builds")

# Ensure we get exactly one clean URL string
DOWNLOAD_URL=$(echo "$BUILDS_RESPONSE" | jq -r '
    ( .[] | select(.channel == "STABLE") | .downloads."server:default".url ) // 
    ( .[0] | .downloads."server:default".url )
' | head -n1 | tr -d "\r\n")

# 4. Download and save as server.jar
if [ -n "$DOWNLOAD_URL" ] && [ "$DOWNLOAD_URL" != "null" ]; then
    echo "Downloading $PROJECT version $FOUND_VERSION..."
    curl -L -H "User-Agent: $USER_AGENT" -o server.jar "$DOWNLOAD_URL"
    echo "Update complete!"
else
    echo "Error: Could not resolve a valid download URL."
    exit 1
fi
