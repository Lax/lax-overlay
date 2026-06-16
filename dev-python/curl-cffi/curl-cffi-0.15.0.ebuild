# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_EXT=1
inherit distutils-r1 pypi

DESCRIPTION="Python binding for curl-impersonate fork via cffi"
HOMEPAGE="https://github.com/lexiforest/curl_cffi"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-python/cffi[${PYTHON_USEDEP}]
	dev-python/certifi[${PYTHON_USEDEP}]
	>=net-misc/curl-impersonate-1.0.0"
BDEPEND="dev-build/cmake
	dev-build/ninja
	dev-libs/openssl"

distutils_enable_tests pytest

src_prepare() {
	# Switch libs.json from static to dynamic linking
	sed -i 's/"link_type": "static"/"link_type": "dynamic"/g' libs.json || die

	# Remove download_libcurl() call and fix libdir check
	sed -i '/^download_libcurl()$/,/^$/d' scripts/build.py || die
	sed -i '/download_libcurl/d' scripts/build.py || die
	sed -i 's/if is_static and libdir.exists():/if is_static and libdir.exists() and libdir != Path("."):/' scripts/build.py || die

	default
}
