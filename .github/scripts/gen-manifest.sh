#!/bin/bash
# Regenerate Manifest DIST entries for changed ebuilds — the CI equivalent
# of `pkgdev manifest` (no pkgcore on the runner).
#
# Covers every package carrying a DIST Manifest: the 5 prebuilt binaries,
# curl-impersonate (multi-fetchable SRC_URI) and curl-cffi (SRC_URI comes
# from the pypi eclass — rebuilt here from PV).
#
# For each added/modified ebuild:
#   1. source the ebuild in a sandboxed bash (eclass helpers stubbed via
#      command_not_found_handle) so SRC_URI is expanded by bash itself
#   2. download every fetchable and compute size + BLAKE2B(512) + SHA512
#   3. replace the matching DIST lines in the package Manifest (LC_ALL=C
#      sort, matching pkgdev's canonical order for DIST-only manifests)
#
# Usage: gen-manifest.sh [ebuild ...]   # defaults to git-detected changes
#
# Env (CI): expects to run at the repo root after the agent's bump.

set -euo pipefail

MANIFEST_PKGS='opencode-bin|zcode-bin|codex-bin|claude-code-bin|maa-cli|curl-impersonate|curl-cffi'
DISTDIR=$(mktemp -d)
trap 'rm -rf "$DISTDIR"' EXIT

# fetchables already downloaded this run (associative by distfile name)
declare -A seen=()

# Gentoo PV -> PEP 440 (mirror of pypi.eclass _pypi_translate_version)
pypi_version() {
    local v=$1
    v=${v/_alpha/a}; v=${v/_beta/b}; v=${v/_pre/.dev}; v=${v/_rc/rc}; v=${v/_p/.post}
    printf "%s" "$v"
}

# source the ebuild (eclass funcs stubbed) and emit "url|distfile" pairs.
# Empty SRC_URI + DISTUTILS_USE_PEP517 set => pypi-eclass package: rebuild
# the sdist URL the way pypi.eclass's _pypi_set_globals would.
dist_pairs_of() { # ebuild_path
    local f=$1 d pn base pv out uri pep pver proj distfile
    d=$(dirname "$f"); pn=$(basename "$d")
    base=$(basename "$f" .ebuild); pv=${base#"$pn-"}
    out=$(bash --noprofile --norc -c '
        command_not_found_handle() { :; }   # eclass funcs (distutils_enable_tests, ...)
        inherit() { :; }
        unpack() { :; }; eapply() { :; }; eapply_user() { :; }; die() { exit 1; }
        PN=$1 PV=$2 P="$1-$2" PF="$1-$2" CATEGORY=$3
        WORKDIR=/nonexistent T=/nonexistent D=/nonexistent FILESDIR=/nonexistent
        source "$4"
        printf "SRC_URI=%s\nPEP517=%s\n" "${SRC_URI-}" "${DISTUTILS_USE_PEP517-}"
    ' _ "$pn" "$pv" "${d%/*}" "$f")
    uri=${out%%$'\n'PEP517=*}; uri=${uri#SRC_URI=}
    pep=${out##*PEP517=}
    if [[ -n $uri ]]; then
        parse_src_uri "$uri"
    elif [[ -n $pep ]]; then
        pver=$(pypi_version "$pv")
        proj=${pn//-/_}; proj=${proj,,}
        distfile="${proj}-${pver}.tar.gz"
        printf "https://files.pythonhosted.org/packages/source/%s/%s/%s|%s\n" \
            "${proj::1}" "$proj" "$distfile" "$distfile"
    else
        echo "::error::$f: no SRC_URI (and not a pypi-eclass package)" >&2
        return 1
    fi
}

# emit "url|distfile" pairs from an expanded SRC_URI
parse_src_uri() { # src_uri
    local -a w
    read -r -a w <<<"${1//$'\n'/ }"
    local i=0 u name
    while (( i < ${#w[@]} )); do
        u=${w[i]}
        if [[ ${w[i+1]:-} == "->" ]]; then
            name=${w[i+2]}; (( i += 3 ))
        else
            name=${u##*/}; (( i += 1 ))
        fi
        case "$u" in
            https://*|http://*|ftp://*|mirror://*) printf "%s|%s\n" "$u" "$name" ;;
            *) { echo "::error::unhandled SRC_URI form: $u" >&2; exit 1; } ;;
        esac
    done
}

gen_dist_lines() { # ebuild_path
    local f=$1 u name file size blake sha
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
    done <<<"$(dist_pairs_of "$f")"
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
        | grep -E "\.ebuild$" | grep -E "$MANIFEST_PKGS" || true)
fi

for t in "${targets[@]}"; do
    update_manifest "$t"
done
