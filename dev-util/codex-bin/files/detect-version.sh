#!/bin/bash
# Detect latest Codex CLI version from GitHub API
# Usage: detect-version.sh

# codex tags are 'rust-vX.Y.Z'; alpha tags are marked prerelease and excluded
# by the /releases/latest endpoint
VERSION=$(curl -s "https://api.github.com/repos/openai/codex/releases/latest" \
    | grep -oE '"tag_name": ?"rust-v[^"]*"' | cut -d'"' -f4 | sed 's/^rust-v//')

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

echo "$VERSION"
