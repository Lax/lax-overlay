# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="AI coding agent, built for the terminal"
HOMEPAGE="https://opencode.ai"
SRC_URI="https://github.com/anomalyco/opencode/releases/download/v${PV}/opencode-linux-x64.tar.gz -> ${PN}-bin-${PV}-linux-x64.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test ) strip"

RDEPEND="
	app-shells/fzf
	sys-apps/ripgrep
"
RDEPEND="${RDEPEND}
	!dev-util/opencode-bin
"

QA_PREBUILT="*"
STRIP_MASK="/usr/bin/opencode"

S="${WORKDIR}"

src_install() {
	dobin "${S}/opencode"

	einstalldocs
}

pkg_postinst() {
	elog "OpenCode has been installed successfully!"
	elog ""
	elog "To get started:"
	elog "  opencode --help"
	elog ""
	elog "For configuration and documentation, visit:"
	elog "  https://opencode.ai/docs"
	elog ""
	elog "Note: You may need to configure your AI provider API keys"
	elog "in your shell configuration or opencode config files."
}
