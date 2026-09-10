# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

UPSTREAM_PV="${PV%%_*}"
UPSTREAM_TAG="rust-v${UPSTREAM_PV}"

DESCRIPTION="OpenAI Codex CLI coding agent, prebuilt static binary"
HOMEPAGE="https://github.com/openai/codex"
SRC_URI="https://github.com/openai/codex/releases/download/${UPSTREAM_TAG}/codex-x86_64-unknown-linux-musl.tar.gz -> ${PN}-${UPSTREAM_PV}-x86_64-linux.tar.gz"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="strip"

QA_PREBUILT="*"

src_install() {
	newbin "${S}/codex-x86_64-unknown-linux-musl" codex
	einstalldocs
}

pkg_postinst() {
	elog "Codex CLI installed."
	elog "Run 'codex --help' to get started."
}
