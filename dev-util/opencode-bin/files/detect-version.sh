#!/bin/bash
# Detect latest opencode version
# Usage: detect-version.sh [beta|stable]
# stable: GitHub API releases/latest
# beta:   npm registry dist-tags.beta (the dated beta releases in
#         anomalyco/opencode-beta carry the CLI tarballs; the v0.0.0-beta-NNNNN
#         tags are desktop-only builds — don't use them)

CHANNEL="${1:-stable}"

if [ "$CHANNEL" = "beta" ]; then
    VERSION=$(curl -s "https://registry.npmjs.org/opencode-ai" \
        | grep -o '"beta": "0\.0\.0-beta-[0-9]*"' | cut -d'"' -f4)
else
    VERSION=$(curl -s "https://api.github.com/repos/anomalyco/opencode/releases/latest" \
        | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
fi

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

echo "$VERSION"
