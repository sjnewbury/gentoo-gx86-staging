# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/giflib/giflib-4.2.3.ebuild,v 1.2 2013/10/19 05:51:56 vapier Exp $

EAPI=5

inherit eutils autotools multilib-minimal

DESCRIPTION="Library to handle, display and manipulate GIF images"
HOMEPAGE="http://sourceforge.net/projects/giflib/"
SRC_URI="mirror://sourceforge/giflib/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="static-libs X"

DEPEND="X? (
		x11-libs/libXt
		x11-libs/libX11
		x11-libs/libICE
		x11-libs/libSM
	)"
RDEPEND="${DEPEND}"

src_prepare() {
	# don't generate html docs
	sed -i '/^SUBDIRS/s/doc//' Makefile.am || die

	epatch "${FILESDIR}"/${PN}-4.1.6-giffix-null-Extension-fix.patch
	sed -i \
		-e 's:AM_CONFIG_HEADER:AC_CONFIG_HEADERS:' \
		configure.ac || die #486542
	eautoreconf
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		$(use_enable static-libs static) \
		$(use_enable X x11)
}

multilib_src_test() {
	cd tests || die
	emake
}

multilib_src_install_all() {
	# for static libs the .la file is required if built with +X
	use static-libs || find "${ED}" -name '*.la' -exec rm -f {} +
	doman doc/*.1
	dodoc doc/*.txt
}
