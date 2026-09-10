# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

UPSTREAM_PV="0.0.0-beta-202608110357"

DESCRIPTION="AI coding agent, built for the terminal (beta snapshot)"
HOMEPAGE="https://opencode.ai"
SRC_URI="https://github.com/anomalyco/opencode-beta/releases/download/v${UPSTREAM_PV}/opencode-linux-x64.tar.gz -> opencode-bin-${UPSTREAM_PV}-linux-x64.tar.gz"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"

QA_PREBUILT="*"

RDEPEND="
	app-shells/fzf
	sys-apps/ripgrep
"

STRIP_MASK="/usr/bin/opencode"

src_install() {
	dobin "${S}"/opencode

	einstalldocs
}

pkg_postinst() {
	elog "OpenCode (beta snapshot) installed: ${UPSTREAM_PV}"
	elog "Run 'opencode --help' to get started."
}
