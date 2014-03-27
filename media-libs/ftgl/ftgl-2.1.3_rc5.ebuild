# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/ftgl/ftgl-2.1.3_rc5.ebuild,v 1.19 2013/04/27 06:55:20 patrick Exp $

EAPI=5

inherit eutils flag-o-matic autotools multilib-minimal

MY_PV=${PV/_/-}
MY_PV2=${PV/_/\~}
MY_P=${PN}-${MY_PV}
MY_P2=${PN}-${MY_PV2}

DESCRIPTION="library to use arbitrary fonts in OpenGL applications"
HOMEPAGE="http://ftgl.wiki.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="static-libs"

DEPEND=">=media-libs/freetype-2.0.9[${MULTILIB_USEDEP}]
	virtual/opengl[${MULTILIB_USEDEP}]
	virtual/glu[${MULTILIB_USEDEP}]
	media-libs/freeglut[${MULTILIB_USEDEP}]"
RDEPEND="${DEPEND}"

S=${WORKDIR}/${MY_P2}

ECONF_SOURCE="${S}"

DOCS="AUTHORS BUGS ChangeLog INSTALL NEWS README TODO docs/projects_using_ftgl.txt"

src_prepare() {
	epatch "${FILESDIR}"/${P}-gentoo.patch \
		"${FILESDIR}"/${P}-underlink.patch
#	AT_M4DIR=m4 eautoreconf
	sed -e "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/" -i configure.ac || die
	eautoreconf
}

multilib_src_configure() {
	strip-flags # ftgl is sensitive - bug #112820
	econf \
		$(use_enable static-libs static)
}

multilib_src_install_all() {
	rm -rf "${ED}"/usr/share/doc/ftgl

	find "${ED}" -name '*.la' -exec rm -f {} +
}
