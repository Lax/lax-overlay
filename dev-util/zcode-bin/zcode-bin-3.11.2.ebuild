# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker

MY_PN="ZCode"

DESCRIPTION="GLM-5.3 official AI coding agent (Zhipu AI), Electron desktop app"
HOMEPAGE="https://zcode.z.ai"
SRC_URI="https://cdn-zcode.z.ai/zcode/electron/releases/${PV}/linux-x64/${MY_PN}-${PV}-linux-x64.deb -> ${P}-linux-x64.deb"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"

QA_PREBUILT="/opt/ZCode/.*"

RDEPEND="
	app-accessibility/at-spi2-core
	app-crypt/libsecret
	dev-libs/nss
	sys-apps/util-linux
	x11-libs/gtk+:3
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libnotify
	x11-misc/xdg-utils
"

src_unpack() {
	unpack_deb "${P}-linux-x64.deb"
}

src_install() {
	dodir /opt/ZCode
	cp -a "${S}"/opt/ZCode/. "${ED}"/opt/ZCode/ || die
	fperms 4755 /opt/ZCode/chrome-sandbox

	dosym -r /opt/ZCode/zcode /usr/bin/zcode

	domenu "${S}"/usr/share/applications/zcode.desktop
	local size
	for size in 16 24 32 48 64 128 256 512 1024; do
		doicon -s ${size}x${size} \
			"${S}"/usr/share/icons/hicolor/${size}x${size}/apps/zcode.png
	done
}

pkg_postinst() {
	elog "ZCode desktop app has been installed."
	elog ""
	elog "If the app fails to launch with a sandbox error, either keep the"
	elog "SUID bit on /opt/ZCode/chrome-sandbox (enabled by this package) or"
	elog "ensure unprivileged user namespaces are available."
}
