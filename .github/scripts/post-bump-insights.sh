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
codex()            { gh api repos/openai/codex/releases/latest --jq '.tag_name' 2>/dev/null | sed 's/^rust-v//'; }

# upstream release-notes / tag-message summary for the *new* version we detect
notes_gh() { # repo maxchars
    gh api "repos/$1/releases/latest" --jq .body 2>/dev/null \
        | grep -v '^\[!\[^\\]' \
        | head -c "${2:-2000}"
}

notes_zcode() { # latest version block from zcode.z.ai changelog page
    curl -s --max-time 15 "https://zcode.z.ai/cn/changelog" 2>/dev/null \
        | python3 -c "
import re,sys
h=sys.stdin.read()
t=re.sub(r'<[^>]+>','\n',h)
ls=[l.strip() for l in t.split('\n') if l.strip()]
idx=[i for i,l in enumerate(ls) if re.match(r'^\d+\.\d+\.\d+$',l)]
if not idx: sys.exit()
out=ls[idx[0]:idx[1] if len(idx)>1 else idx[0]+25]
print('\n'.join(out[:25]))"
}

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

    l=$(latest_ver dev-util/codex-bin); u=$(codex)
    [ -z "$u" ] && echo "| codex-bin | $l | *detect failed* | ⚠️ |" \
        || { [ "$l" = "$u" ] && echo "| codex-bin | $l | $u | in sync ✅ |" \
        || echo "| codex-bin | $l | $u | behind: next scheduled bump ⚠️ |"; }

    echo
    echo "## Upstream new version notes"
    echo
    b=$(notes_gh anomalyco/opencode)
    if [ -n "$b" ]; then
        echo "<details>"
        echo "<summary><b>opencode</b> — target of next opencode-bin bump</summary>"
        echo
        echo "$b"
        echo
        echo "</details>"
        echo
    else
        echo "- opencode: no release notes body"
    fi

    b=$(notes_zcode)
    if [ -n "$b" ]; then
        echo "<details>"
        echo "<summary><b>zcode</b> — target of next zcode-bin bump</summary>"
        echo
        echo "$b"
        echo
        echo "</details>"
        echo
    fi

    b=$(notes_gh lexiforest/curl-impersonate)
    [ -n "$b" ] && { echo "<details>"; echo "<summary><b>curl-impersonate</b> target</summary>"; echo; echo "$b"; echo; echo "</details>"; echo; }

    b=$(notes_gh lexiforest/curl_cffi)
    [ -n "$b" ] && { echo "<details>"; echo "<summary><b>curl-cffi</b> target</summary>"; echo; echo "$b"; echo; echo "</details>"; echo; }
    echo
    echo "## Run recap"
    echo
    echo "- upstream opencode stable detected: **${UPSTREAM_VER:-unknown}**"
    if [ "${UP_TO_DATE}" = "true" ]; then
        echo "- outcome: **skipped** — ebuild for latest version already present 🚀"
    else
        echo "- outcome: **bump executed**, target ${UPSTREAM_VER}"
        if [ -s .bump-file-changes.txt ]; then
            echo "- files updated this run:"
            echo
            echo "| change | path |"
            echo "|---|---|"
            while IFS=$'\t' read -r s p; do
                case "$s" in
                    A*) kind='✚ added' ;;
                    M*) kind='✎ modified' ;;
                    D*) kind='✘ deleted' ;;
                    *)  kind="$s" ;;
                esac
                echo "| $kind | \`$p\` |"
            done < .bump-file-changes.txt
            if [ -s .bump-diffstat.txt ]; then
                echo
                echo "\`\`\`diffstat"
                cat .bump-diffstat.txt
                echo "\`\`\`"
            fi
        elif [ "${BUMP_NO_CHANGES:-}" = "1" ]; then
            echo "- but no ebuild changes were produced (upstream parity kept?)"
        else
            echo "- but no change report was captured (run failed before bump?)"
        fi
    fi
    [ "${BUMP_NO_CHANGES:-}" = "1" ] && [ "${UP_TO_DATE}" = "true" ] && echo "- (skipped fast path, nothing to do)"
    echo
    echo "_generated $(date -u +%Y-%m-%dT%H:%M:%SZ)_"
    echo
} >> "$SUMMARY"

echo "--- step summary generated ---" >&2
