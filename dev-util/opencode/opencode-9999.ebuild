# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="AI coding agent, built for the terminal"
HOMEPAGE="https://opencode.ai"

IUSE="beta"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip"

STABLE_VER="1.18.4"
BETA_VER="0.0.0-beta-202607220512"

SRC_URI="
    !beta? ( https://github.com/anomalyco/opencode/releases/download/v${STABLE_VER}/opencode-linux-x64.tar.gz -> ${PN}-bin-${STABLE_VER}.tar.gz )
    beta? ( https://github.com/anomalyco/opencode-beta/releases/download/v${BETA_VER}/opencode-linux-x64.tar.gz -> ${PN}-bin-${BETA_VER}.tar.gz )
"

RDEPEND="
    app-shells/fzf
    sys-apps/ripgrep
    !dev-util/opencode-bin
"

S="${WORKDIR}"

src_install() {
    dobin "${S}/opencode"
    einstalldocs
}

pkg_postinst() {
    if use beta; then
        elog "OpenCode (beta) installed: ${BETA_VER}"
    else
        elog "OpenCode (stable) installed: ${STABLE_VER}"
    fi
    elog "Run 'opencode --help' to get started."
}
