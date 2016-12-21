# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils flag-o-matic toolchain-funcs vcs-snapshot multilib-minimal

DESCRIPTION="lightweight Javascript interpreter"
HOMEPAGE="http://mujs.com/"
SRC_URI="http://git.ghostscript.com/?p=mujs.git;a=snapshot;h=1930f35933654d02234249b8c9b8c0d1c8c9fb6b;sf=tgz -> ${P}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="static-libs"

DEPEND=""
RDEPEND="${DEPEND}"

fix_multilib() {
	sed -i \
		-e "/^libdir/s/\/lib/\/$(get_libdir)/" \
		${BUILD_DIR}/Makefile || die sed failed
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0_p20150202-Makefile.patch
	epatch "${FILESDIR}"/${P}-shared.patch
	tc-export CC
	multilib_copy_sources

	# Fix multilib dir
	multilib_foreach_abi fix_multilib
}

multilib_src_compile() {
	emake libdir=/usr/$(get_libdir)
	use static-libs && emake build/libmujs.a

}

multilib_src_install() {
	emake DESTDIR="${ED}" install
	use static-libs && dolib.a ${BUILD_DIR}/build/libmujs.a
}
