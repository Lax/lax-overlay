#!/bin/bash
# Regenerate Manifest DIST entries for changed prebuilt ebuilds — the CI
# equivalent of `pkgdev manifest` (no pkgcore on the runner).
#
# For each added/modified ebuild of a prebuilt package (opencode-bin,
# zcode-bin, codex-bin, claude-code-bin, maa-cli):
#   1. source the ebuild in a sandboxed bash (inherit stubbed out) so SRC_URI
#      is fully expanded by bash itself — no fragile sed variable chains
#   2. download every fetchable and compute size + BLAKE2B(512) + SHA512
#   3. replace the matching DIST lines in the package Manifest (LC_ALL=C
#      sort, matching pkgdev's canonical order for DIST-only manifests)
#
# Usage: gen-manifest.sh [ebuild ...]   # defaults to git-detected changes
#
# Env (CI): expects to run at the repo root after the agent's bump.

set -euo pipefail

PREBUILT='opencode-bin|zcode-bin|codex-bin|claude-code-bin|maa-cli'
DISTDIR=$(mktemp -d)
trap 'rm -rf "$DISTDIR"' EXIT

# fetchables already downloaded this run (associative by distfile name)
declare -A seen=()

# expand an ebuild's SRC_URI by sourcing it with phase/eclass helpers stubbed
src_uri_of() { # ebuild_path
    local f=$1 d pn base pv
    d=$(dirname "$f"); pn=$(basename "$d")
    base=$(basename "$f" .ebuild); pv=${base#"$pn-"}
    bash --noprofile --norc -c '
        inherit() { :; }; use() { :; }; usev() { :; }; usex() { :; }
        use_enable() { :; }; use_with() { :; }
        unpack() { :; }; eapply() { :; }; eapply_user() { :; }; die() { exit 1; }
        PN=$1 PV=$2 P="$1-$2" PF="$1-$2" CATEGORY=$3
        WORKDIR=/nonexistent T=/nonexistent D=/nonexistent FILESDIR=/nonexistent
        source "$4"
        printf "%s" "$SRC_URI"
    ' _ "$pn" "$pv" "${d%/*}" "$f"
}

# emit "url|distfile" pairs from an expanded SRC_URI
parse_src_uri() { # src_uri
    local -a w
    read -r -a w <<<"${1//$'\n'/ }"
    local i=0 u name
    while (( i < ${#w[@]} )); do
        u=${w[i]}
        if [[ ${w[i+1]:-} == "->" ]]; then
            name=${w[i+2]}; i+=3
        else
            name=${u##*/}; i+=1
        fi
        case "$u" in
            https://*|http://*|ftp://*|mirror://*) printf "%s|%s\n" "$u" "$name" ;;
            *) { echo "::error::unhandled SRC_URI form: $u" >&2; exit 1; } ;;
        esac
    done
}

gen_dist_lines() { # ebuild_path
    local f=$1 uri u name file size blake sha
    uri=$(src_uri_of "$f")
    [ -n "$uri" ] || { echo "::error::$f: empty SRC_URI" >&2; exit 1; }
    while IFS='|' read -r u name; do
        [[ -n ${seen[$name]:-} ]] && continue
        seen[$name]=1
        file="$DISTDIR/$name"
        echo "fetching $name" >&2
        curl -sSL --fail --retry 3 --connect-timeout 30 -o "$file" "$u"
        size=$(stat -c %s "$file")
        blake=$(b2sum -l 512 "$file" | cut -d' ' -f1)
        sha=$(sha512sum "$file" | cut -d' ' -f1)
        printf "DIST %s %s BLAKE2B %s SHA512 %s\n" "$name" "$size" "$blake" "$sha"
    done <<<"$(parse_src_uri "$uri")"
}

update_manifest() { # ebuild_path
    local f=$1 manifest new skip tmp
    manifest=$(dirname "$f")/Manifest
    new=$(gen_dist_lines "$f")
    if [[ -z $new ]]; then
        return 0
    fi
    # collect the distfile names we generated so their old lines get replaced
    skip=$(printf "%s\n" "$new" | awk '{print $2}')
    tmp=$(mktemp)
    awk -v skip="$skip" \
        'BEGIN{n=split(skip,a,"\n"); for(k=1;k<=n;k++) S[a[k]]=1}
         $1!="DIST" || !($2 in S)' "$manifest" > "$tmp"
    printf "%s\n" "$new" >> "$tmp"
    LC_ALL=C sort -o "$tmp" "$tmp"
    mv "$tmp" "$manifest"
    echo "Manifest updated: $(dirname "$f")"
}

if (($#)); then
    targets=("$@")
else
    git add -A
    mapfile -t targets < <(git diff --cached --name-only --diff-filter=AM \
        | grep -E "\.ebuild$" | grep -E "$PREBUILT" || true)
fi

for t in "${targets[@]}"; do
    update_manifest "$t"
done
