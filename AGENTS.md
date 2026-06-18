# lax — Gentoo overlay

3 ebuild packages, EAPI=8, `~amd64`.

## Repo layout

| Dir | Package | Upstream | Notes |
|---|---|---|---|
| `net-misc/curl-impersonate` | curl fork with browser TLS fingerprinting | lexiforest/curl-impersonate | Builds from source (cmake + autotools), embeds BoringSSL |
| `dev-python/curl-cffi` | Python cffi bindings | lexiforest/curl_cffi | PyPI source via `distutils-r1 pypi` |
| `dev-util/opencode` | AI coding agent CLI binary | anomalyco/opencode | Prebuilt binary, has `Manifest` with DIST hashes |

**`opencode-9999.ebuild`** is a tracking ebuild with `STABLE_VER` and `BETA_VER` variables + `USE=beta` flag. Update both when bumping.

## Updating packages

```bash
# helper: query latest upstream tag
dev-util/opencode/files/detect-version.sh [beta|stable]
```

For each version bump:
1. Create/update ebuild(s), update `BETA_VER` / `STABLE_VER` in `-9999` if needed
2. Re-gen Manifest for `dev-util/opencode`:
   ```
   pkgdev manifest dev-util/opencode
   ```
   (Only `opencode` needs a Manifest — prebuilt binary. Others use `thin-manifests = true`.)
3. Commit: `git add -A && git commit -m "$pkg: $old -> $new"`

## Config

- `metadata/layout.conf`: `masters = gentoo`, `thin-manifests = true`, `repo-name = lax`
- No CI, no tests, no lint/typecheck scripts
