# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

UPSTREAM_PV="${PV%%_*}"
UPSTREAM_TAG="v${UPSTREAM_PV}"

DESCRIPTION="Anthropic Claude Code, agentic coding tool for the terminal, prebuilt binary"
HOMEPAGE="https://github.com/anthropics/claude-code"
SRC_URI="https://github.com/anthropics/claude-code/releases/download/${UPSTREAM_TAG}/claude-linux-x64.tar.gz -> ${PN}-${UPSTREAM_PV}-x86_64-linux.tar.gz"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"

QA_PREBUILT="*"

RDEPEND="
	!dev-util/claude-code
"

src_install() {
	newbin "${S}/claude" claude

	einstalldocs
}

pkg_postinst() {
	elog "Claude Code CLI installed."
	elog "Run 'claude --help' to get started."
}
