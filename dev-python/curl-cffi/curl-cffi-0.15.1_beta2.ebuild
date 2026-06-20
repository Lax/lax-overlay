# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_EXT=1
PYPI_PV="0.15.1b2"
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
	# Switch libs.json from static to dynamic linking for linux
	sed -i 's/"link_type": "static"/"link_type": "dynamic"/g' libs.json || die

	# Remove the download_libcurl() call
	sed -i '/download_libcurl()/{
		/def /!d
	}' scripts/build.py || die

	# Fix get_curl_archives to skip listing missing dir
	sed -i '/^def get_curl_archives():/,/^$/{
		s/print("Files in linking directory:")/# print("Files in linking directory:")/
		s/print(os.listdir(libdir))/pass/
	}' scripts/build.py || die

	default
}
