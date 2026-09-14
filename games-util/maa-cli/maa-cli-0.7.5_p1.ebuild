# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

UPSTREAM_PV="${PV%%_*}"
UPSTREAM_TAG="v${UPSTREAM_PV}"

DESCRIPTION="MAA (Arknights assistant) command-line tool, prebuilt binary"
HOMEPAGE="https://github.com/MaaAssistantArknights/maa-cli"
SRC_URI="https://github.com/MaaAssistantArknights/maa-cli/releases/download/${UPSTREAM_TAG}/maa_cli-${UPSTREAM_TAG}-x86_64-unknown-linux-gnu.tar.gz -> ${PN}-${UPSTREAM_PV}-x86_64-linux.tar.gz"

S="${WORKDIR}"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"

QA_PREBUILT="*"

RDEPEND="sys-libs/zlib-ng[compat]"

src_install() {
	newbin "${S}/maa" maa

	einstalldocs
	dodoc "${S}/licenses.md"
}

pkg_postinst() {
	elog "maa-cli installed."
	elog "It will fetch the MAA framework (libMaaCore) into ~/.local/share/MAA"
	elog "on first use ('maa install' or automatically)."
	elog "Run 'maa --help' to get started."
}
