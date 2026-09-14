#!/bin/bash
# Detect latest maa-cli version from GitHub API
# Usage: detect-version.sh

VERSION=$(curl -s "https://api.github.com/repos/MaaAssistantArknights/maa-cli/releases/latest" \
    | grep -oE '"tag_name": ?"v[^"]*"' | cut -d'"' -f4 | sed 's/^v//')

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

echo "$VERSION"
