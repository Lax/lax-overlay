#!/bin/bash
# Detect latest ZCode version from the zcode.z.ai homepage

VERSION=$(curl -s "https://zcode.z.ai/en" | grep -oE 'releases/[0-9]+\.[0-9]+\.[0-9]+' | sed 's|releases/||' | sort -uV | tail -n 1)

if [ -z "$VERSION" ]; then
    echo "ERROR: Could not detect version" >&2
    exit 1
fi

echo "$VERSION"
