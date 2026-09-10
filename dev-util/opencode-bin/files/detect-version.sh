#!/bin/bash
# Detect latest opencode version from GitHub API
# Usage: detect-version.sh [beta|stable]

CHANNEL="${1:-stable}"

if [ "$CHANNEL" = "beta" ]; then
    REPO="anomalyco/opencode-beta"
else
    REPO="anomalyco/opencode"
fi

# Get latest release tag from GitHub API
VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

echo "$VERSION"
