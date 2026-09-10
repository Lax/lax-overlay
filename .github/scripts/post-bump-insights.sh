#!/bin/bash
# Generate the auto-bump job step summary: repo-wide update status table
# plus what this run did. Safe to run even when most steps were skipped.
#
# Env: GITHUB_STEP_SUMMARY, UPSTREAM_VER, UP_TO_DATE (true/false),
#      BUMP_NO_CHANGES (optional, set when sanity-check found no ebuild diff)

set -uo pipefail

SUMMARY="${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY not set}"

strip_p1() { sed 's/_p1$//'; }

# latest plain versioned ebuild (skips 0.0.0_beta* snapshots)
latest_ver() { # dir
    local d="$1" pfx
    pfx="$(basename "$d")"
    ls -1 "$d"/*.ebuild 2>/dev/null \
        | xargs -rn 1 basename \
        | grep -v '0\.0\.0_beta' \
        | sed "s/^${pfx}-//; s/\.ebuild$//; s/_p1$//" \
        | sort -V | tail -n 1
}

# latest beta snapshot ebuild (0.0.0_betaNNNN_p1)
latest_beta() { # dir
    ls -1 "$1"/*.ebuild 2>/dev/null \
        | grep '0\.0\.0_beta' \
        | sed 's/\.ebuild$//; s/.*_beta//; s/_p1$//' \
        | sort -V | tail -n 1
}

opencode_stable()  { gh api repos/anomalyco/opencode/releases/latest --jq '.tag_name' 2>/dev/null | tr -d v; }
opencode_beta()    { curl -s --max-time 15 "https://registry.npmjs.org/opencode-ai" 2>/dev/null | grep -o '"beta":"0\.0\.0-beta-[0-9]*"' | cut -d'"' -f4; }
zcode()            { curl -s --max-time 15 "https://zcode.z.ai/en" 2>/dev/null | grep -oE 'releases/[0-9]+\.[0-9]+\.[0-9]+' | sed 's|releases/||' | sort -uV | tail -n 1; }
curl_impersonate() { gh api repos/lexiforest/curl-impersonate/releases/latest --jq '.tag_name' 2>/dev/null | sed 's/^v//'; }
curl_cffi()        { gh api repos/lexiforest/curl_cffi/releases/latest --jq '.tag_name' 2>/dev/null | sed 's/^v//'; }

OC="dev-util/opencode-bin"

{
    echo "## Auto bump — repo update status"
    echo
    echo "| package | local latest | upstream latest | note |"
    echo "|---|---|---|---|"

    l=$(latest_ver "$OC");    u=$(opencode_stable)
    [ -z "$u" ] && echo "| opencode-bin (stable) | $l | *detect failed* | ⚠️ |" \
        || { [ "$l" = "$u" ] && echo "| opencode-bin (stable) | $l | $u | in sync ✅ |" \
        || echo "| opencode-bin (stable) | $l | $u | behind: next scheduled bump ⚠️ |"; }

    l=$(latest_beta "$OC");   u=$(opencode_beta)
    [ -z "$u" ] && echo "| opencode-bin (beta) | $l | *detect failed* | ⚠️ |" \
        || { [ "0.0.0-beta-$l" = "$u" ] && echo "| opencode-bin (beta) | 0.0.0-beta-$l | $u | in sync ✅ |" \
        || echo "| opencode-bin (beta) | 0.0.0-beta-$l | $u | behind: next dated npm-tag beta ⚠️ |"; }

    l=$(latest_ver dev-util/zcode-bin); u=$(zcode)
    [ -z "$u" ] && echo "| zcode-bin | $l | *detect failed* | ⚠️ |" \
        || { [ "$l" = "$u" ] && echo "| zcode-bin | $l | $u | in sync ✅ |" \
        || echo "| zcode-bin | $l | $u | behind: next scheduled bump ⚠️ |"; }

    l=$(latest_ver net-misc/curl-impersonate); u=$(curl_impersonate)
    [ -z "$u" ] && echo "| curl-impersonate | $l | *detect failed* | ⚠️ |" \
        || { [ "$l" = "$u" ] && echo "| curl-impersonate | $l | $u | in sync ✅ |" \
        || echo "| curl-impersonate | $l | $u | behind: next scheduled bump ⚠️ |"; }

    l=$(latest_ver dev-python/curl-cffi); u=$(curl_cffi)
    [ -z "$u" ] && echo "| curl-cffi | $l | *detect failed* | ⚠️ |" \
        || { [ "$l" = "$u" ] && echo "| curl-cffi | $l | $u | in sync ✅ |" \
        || echo "| curl-cffi | $l | $u | behind: next scheduled bump ⚠️ |"; }

    echo
    echo "## Run recap"
    echo
    echo "- upstream opencode stable detected: **${UPSTREAM_VER:-unknown}**"
    if [ "${UP_TO_DATE}" = "true" ]; then
        echo "- outcome: **skipped** — ebuild for latest version already present 🚀"
    else
        echo "- outcome: **bump executed**, target ${UPSTREAM_VER}"
        [ -n "${BUMP_NO_CHANGES:-}" ] && echo "- note: no ebuild changes were produced"
        if git status --porcelain 2>/dev/null | head -12 | grep -q .; then
            echo "- pending working tree state:"
            echo '```'
            git status --porcelain | head -12
            echo '```'
        fi
    fi
    echo
    echo "_generated $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
    echo
} >> "$SUMMARY"

echo "--- step summary generated ---" >&2
