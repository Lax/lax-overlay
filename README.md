# lax

Gentoo overlay providing [curl-cffi](https://github.com/lexiforest/curl_cffi) and [opencode](https://opencode.ai).

## Packages

| Package | Description |
|---|---|
| `net-misc/curl-impersonate` | Fork of curl that impersonates Chrome, Firefox, Safari TLS/HTTP2 fingerprints |
| `dev-python/curl-cffi` | Python cffi bindings for curl-impersonate |
| `dev-util/opencode` | AI coding agent for the terminal |

## Installation

### Add overlay

```bash
eselect repository add lax git https://github.com/Lax/lax-overlay.git
emaint sync -r lax
```

### Install packages

```bash
emerge --ask net-misc/curl-impersonate dev-python/curl-cffi dev-util/opencode
```

## Usage

### curl-impersonate CLI

```bash
# Impersonate Chrome
curl-chrome146 https://example.com

# Impersonate Firefox
curl-firefox147 https://example.com

# Impersonate Safari
curl-safari260 https://example.com
```

### curl-cffi Python

```python
from curl_cffi import requests

# Impersonate Chrome
response = requests.get("https://example.com", impersonate="chrome")

# Impersonate Firefox
response = requests.get("https://example.com", impersonate="firefox")

# Async support
import asyncio
from curl_cffi.requests import AsyncSession

async def main():
    async with AsyncSession() as session:
        response = await session.get("https://example.com", impersonate="chrome")

asyncio.run(main())
```

### opencode

```bash
# Stable channel (default)
emerge -1 '=dev-util/opencode-9999::lax'

# Beta channel
echo "dev-util/opencode beta" >> /etc/portage/package.use/lax
emerge -1 '=dev-util/opencode-9999::lax'
```

### Supported browser targets

- Chrome: 99-146, Android
- Firefox: 133-147
- Safari: 15.3-26.0, iOS
- Edge: 99, 101
- Tor: 145

## Dependencies

All from Gentoo main repo:

- `dev-python/cffi`
- `dev-python/certifi`
- `app-arch/brotli`
- `net-libs/nghttp2`
- `app-arch/zstd`
- `net-libs/libpsl`
- `virtual/zlib`

## License

MIT
