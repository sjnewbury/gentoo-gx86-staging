# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libdaemon/libdaemon-0.14-r1.ebuild,v 1.8 2012/05/13 19:47:31 aballier Exp $

EAPI=4

inherit libtool eutils multilib-minimal

DESCRIPTION="Simple library for creating daemon processes in C"
HOMEPAGE="http://0pointer.de/lennart/projects/libdaemon/"
SRC_URI="http://0pointer.de/lennart/projects/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc examples static-libs"

RDEPEND=""
DEPEND="doc? ( app-doc/doxygen )"

DOCS=( "README" )

src_prepare() {
	default
	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		--localstatedir=/var \
		--disable-examples \
		--disable-lynx \
		$(use_enable static-libs static)
}

multilib_src_compile() {
	emake

	if use doc ; then
		einfo "Building documentation"
		emake doxygen
	fi
}

multilib_src_install() {
	default
}

multilib_src_install_all() {

	find "${ED}" -name '*.la' -exec rm -f {} +

	if use doc; then
		ln -sf doc/reference/html reference
		dohtml -r doc/README.html doc/style.css reference
		doman doc/reference/man/man*/*
	fi

	if use examples; then
		docinto examples
		dodoc examples/testd.c
	fi

	rm -rf "${ED}"/usr/share/doc/${PF}/{README.html,style.css} || die "rm failed"
}