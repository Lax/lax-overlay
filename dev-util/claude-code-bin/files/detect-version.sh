#!/bin/bash
# Detect latest Claude Code version from GitHub API
# Usage: detect-version.sh
# Note: GitHub releases track the npm 'latest' dist-tag; the 'stable'
# dist-tag lags behind on purpose.

VERSION=$(curl -s "https://api.github.com/repos/anthropics/claude-code/releases/latest" \
    | grep -oE '"tag_name": ?"v[^"]*"' | cut -d'"' -f4 | sed 's/^v//')

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

echo "$VERSION"
