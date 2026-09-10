# lax — Gentoo overlay

4 ebuild packages, EAPI=8, `~amd64`.

**Version suffix `_p1`**: prebuilt packages (`opencode-bin`, `zcode-bin`) append `_p1` to PV to mark them as this overlay's wraps (vs. official upstream). Upstream URLs use `UPSTREAM_PV="${PV%%_*}"`; distfile names stay suffix-free so DIST digests don't change. New upstream release X.Y.Z gets ebuild `-$X.Y.Z-p1`.

## Repo layout

| Dir | Package | Upstream | Notes |
|---|---|---|---|
| `net-misc/curl-impersonate` | curl fork with browser TLS fingerprinting | lexiforest/curl-impersonate | Builds from source (cmake + autotools), embeds BoringSSL |
| `dev-python/curl-cffi` | Python cffi bindings | lexiforest/curl_cffi | PyPI source via `distutils-r1 pypi` |
| `dev-util/opencode-bin` | AI coding agent CLI binary | anomalyco/opencode | Prebuilt binary, has `Manifest` with DIST hashes |
| `dev-util/zcode-bin` | Zhipu GLM coding agent, Electron desktop app (.deb) | zcode.z.ai | Prebuilt Electron, has `Manifest` with DIST hashes, installed to `/opt/ZCode` |

## Updating packages

```bash
# helper: query latest upstream tag
dev-util/opencode-bin/files/detect-version.sh
dev-util/zcode-bin/files/detect-version.sh
```

For each version bump:
1. Create/update ebuild(s): new upstream release X.Y.Z → new ebuild `-$X.Y.Z-p1` (see `_p1` convention above)
2.    Re-gen Manifest for `dev-util/opencode-bin`:
   ```
   pkgdev manifest dev-util/opencode-bin
   ```
   (Only `opencode-bin` and `zcode-bin` need a Manifest — prebuilt binaries. Others use `thin-manifests = true`.)
3. Commit: `git add -A && git commit -m "$pkg: $old -> $new"`

## Config

- `metadata/layout.conf`: `masters = gentoo`, `thin-manifests = true`, `repo-name = lax`
- No CI, no tests, no lint/typecheck scripts
