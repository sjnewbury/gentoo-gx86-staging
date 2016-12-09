# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit multilib-minimal

DESCRIPTION="Multitouch Protocol Translation Library"
HOMEPAGE="http://bitmath.org/code/mtdev/"
SRC_URI="http://bitmath.org/code/mtdev/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~sh sparc x86"
IUSE="static-libs"

DEPEND=">=sys-kernel/linux-headers-2.6.31"

ECONF_SOURCE="${S}"

multilib_src_configure() {
	econf $(use_enable static-libs static)
}

multilib_src_install_all() {
	find "${ED}" -name '*.la' -exec rm -f {} +
}
