# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Fork of curl-impersonate: curl that impersonates browser TLS/HTTP fingerprints"
HOMEPAGE="https://github.com/lexiforest/curl-impersonate"

# Version pins mirrored from the upstream CMake superbuild (CMakeLists.txt).
# Keep in sync when bumping.
BORINGSSL_SHA="156c7b75ae9b8c3b3f847acf264f17594c3859fb"

SRC_URI="https://github.com/lexiforest/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz
	https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
	https://github.com/google/brotli/archive/refs/tags/v1.2.0.tar.gz -> brotli-1.2.0.tar.gz
	https://github.com/google/boringssl/archive/${BORINGSSL_SHA}.zip
	https://github.com/nghttp2/nghttp2/releases/download/v1.63.0/nghttp2-1.63.0.tar.bz2
	https://github.com/ngtcp2/nghttp3/releases/download/v1.15.0/nghttp3-1.15.0.tar.bz2
	https://github.com/ngtcp2/ngtcp2/releases/download/v1.20.0/ngtcp2-1.20.0.tar.bz2
	https://github.com/curl/curl/archive/curl-8_21_0.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# ExternalProject archives prefetched into each dep's download dir
# (<name>-prefix/src, CMake's default DOWNLOAD_DIR) so the superbuild
# download step finds them with a matching hash and never hits the network.
# The download step looks for the URL's basename, not the distfile name,
# so pass "<dist-name> <prefix-name> [<download-name>]" (third field only
# needed when it differs from <dist-name>, e.g. brotli's tag URL).
DEP_ARCHIVES=(
	"zlib-1.3.1.tar.gz zlib"
	"zstd-1.5.7.tar.gz zstd"
	"brotli-1.2.0.tar.gz brotli v1.2.0.tar.gz"
	"${BORINGSSL_SHA}.zip boringssl"
	"nghttp2-1.63.0.tar.bz2 nghttp2"
	"nghttp3-1.15.0.tar.bz2 nghttp3"
	"ngtcp2-1.20.0.tar.bz2 ngtcp2"
	"curl-8_21_0.tar.gz curl"
)

BDEPEND="dev-build/cmake
	dev-build/ninja
	app-arch/unzip
	dev-lang/go
	sys-devel/patch"

DOCS=( README.md INSTALL.md )

src_unpack() {
	# Dep archives are handled by the CMake superbuild at build time.
	unpack "${P}.tar.gz"
}

src_configure() {
	local build_dir="${BUILD_DIR:-${WORKDIR}/${P}_build}"
	local entry archive prefix name
	for entry in "${DEP_ARCHIVES[@]}"; do
		read -r archive prefix name <<<"${entry}"
		name=${name:-${archive}}
		mkdir -p "${build_dir}/${prefix}-prefix/src" || die
		if [[ -f "${DISTDIR}/${archive}" ]]; then
			cp "${DISTDIR}/${archive}" "${build_dir}/${prefix}-prefix/src/${name}" || die
		else
			eerror "Missing DIST file: ${archive}"
			die "Missing DIST file: ${archive}"
		fi
	done

	local mycmakeargs=(
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)"
		-DUSE_LIBIDN2=OFF
		-DCURL_CA_BUNDLE="${EPREFIX}/etc/ssl/certs/ca-certificates.crt"
		-DCURL_CA_PATH="${EPREFIX}/etc/ssl/certs"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Drop headers: they collide with net-misc/curl's /usr/include/curl.
	rm -rf "${D}/usr/include" || die

	# The superbuild drops dependency licenses into the prefix root.
	rm -f "${D}/LICENSE"* "${D}/usr/LICENSE"* || die
}
