# lax — Gentoo overlay

5 ebuild packages, EAPI=8, `~amd64`.

**Version suffix `_p1`**: prebuilt packages (`opencode-bin`, `zcode-bin`) append `_p1` to PV to mark them as this overlay's wraps (vs. official upstream). Upstream URLs use `UPSTREAM_PV="${PV%%_*}"` (beta ebuilds declare `UPSTREAM_PV` literally — PV is `0.0.0_betaNNNN_p1`-style); distfile names stay suffix-free so DIST digests don't change. New upstream release X.Y.Z gets ebuild `-$X.Y.Z-p1`.

**Beta snapshots** (`opencode-bin`): beta is a regular versioned ebuild (no USE flag), e.g. `opencode-bin-0.0.0_beta202608110357_p1`,
mapping upstream tag `v0.0.0-beta-202608110357` → PV `0.0.0_beta202608110357_p1`. Only the
dated beta tags carry the CLI tarball; `v0.0.0-beta-NNNNN` tags in `anomalyco/opencode-beta`
are desktop-only builds. Detect via `detect-version.sh beta` (npm `dist-tags.beta`).

## Repo layout

| Dir | Package | Upstream | Notes |
|---|---|---|---|
| `net-misc/curl-impersonate` | curl fork with browser TLS fingerprinting | lexiforest/curl-impersonate | Builds from source (cmake + autotools), embeds BoringSSL |
| `dev-python/curl-cffi` | Python cffi bindings | lexiforest/curl_cffi | PyPI source via `distutils-r1 pypi` |
| `dev-util/opencode-bin` | AI coding agent CLI binary | anomalyco/opencode | Prebuilt binary, has `Manifest` with DIST hashes |
| `dev-util/codex-bin` | OpenAI Codex CLI coding agent | openai/codex | Prebuilt static binary from `rust-vX.Y.Z` tags, has `Manifest` with DIST hashes |
| `dev-util/zcode-bin` | Zhipu GLM coding agent, Electron desktop app (.deb) | zcode.z.ai | Prebuilt Electron, has `Manifest` with DIST hashes, installed to `/opt/ZCode` |

## Updating packages

```bash
# helper: query latest upstream tag
bash dev-util/opencode-bin/files/detect-version.sh [beta|stable]   # beta = npm dist-tags.beta (dated tags only)
bash dev-util/zcode-bin/files/detect-version.sh
bash dev-util/codex-bin/files/detect-version.sh
```

For each version bump:
1. Create/update ebuild(s): new upstream release X.Y.Z → new ebuild `-$X.Y.Z-p1` (see `_p1` convention above)
2.    Re-gen Manifest for `dev-util/opencode-bin`:
   ```
   pkgdev manifest dev-util/opencode-bin
   ```
   (Only `opencode-bin`, `zcode-bin`, and `codex-bin` need a Manifest — prebuilt binaries. Others use `thin-manifests = true`.)
3. Commit: `git add -A && git commit -m "$pkg: $old -> $new"`

**Local vs CI**:
- Local interactive bumps commit per the recipe above.
- When running as the scheduled GitHub Actions bump agent (`auto-bump.yml`), do NOT
  commit or push — create/update ebuilds + Manifests only and let
  `stefanzweifel/git-auto-commit-action` handle the single `Auto bump YYYY-MM-DD` commit.

## Config

- `metadata/layout.conf`: `masters = gentoo`, `thin-manifests = true`, `repo-name = lax`
- No CI, no tests, no lint/typecheck scripts
