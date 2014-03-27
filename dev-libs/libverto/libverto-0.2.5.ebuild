# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libverto/libverto-0.2.5.ebuild,v 1.16 2013/08/16 17:04:28 pinkbyte Exp $

EAPI=5

inherit multilib-minimal

DESCRIPTION="Main event loop abstraction library"
HOMEPAGE="https://fedorahosted.org/libverto/"
SRC_URI="https://fedorahosted.org/releases/l/i/libverto/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd"
IUSE="glib +libev libevent tevent +threads static-libs"

# file collisions
DEPEND="!=app-crypt/mit-krb5-1.10.1-r0
	!=app-crypt/mit-krb5-1.10.1-r1
	!=app-crypt/mit-krb5-1.10.1-r2
	glib? ( >=dev-libs/glib-2.29[${MULTILIB_USEDEP}] )
	libev? ( >=dev-libs/libev-4.11[${MULTILIB_USEDEP}] )
	libevent? ( >=dev-libs/libevent-2.0[${MULTILIB_USEDEP}] )
	tevent? ( sys-libs/tevent[${MULTILIB_USEDEP}] )"

RDEPEND="${DEPEND}"

REQUIRED_USE="|| ( glib libev libevent tevent ) "

ECONF_SOURCE="${S}"

src_prepare() {
	# known problem uptream with tevent write test.  tevent does not fire a
	# callback on error, but we explicitly test for this behaviour.  Do not run
	# tevent tests for now.
	sed -i -e 's/def HAVE_TEVENT/ 0/' tests/test.h || die
}

multilib_src_configure() {
	econf \
		$(use_with glib) \
		$(use_with libev) \
		$(use_with libevent) \
		$(use_with tevent) \
		$(use_with threads pthread) \
		$(use_enable static-libs static)
}

multilib_src_install() {
	emake DESTDIR="${D}" install
}

multlib_src_install_all() {
	dodoc AUTHORS ChangeLog NEWS INSTALL README

	use static-libs || find "${D}" -name '*.la' -delete
}
