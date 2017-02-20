# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libva-utils/libva-utils-9999.ebuild,v 1.18 2013/06/29 03:43:38 aballier Exp $

EAPI=5

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SCM=git-r3
	EGIT_REPO_URI="git://github.com/01org/libva-utils"
fi

inherit autotools ${SCM} multilib multilib-minimal

DESCRIPTION="Video Acceleration (VA) API for Linux Utilities"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/vaapi"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
else
	SRC_URI="http://www.freedesktop.org/software/vaapi/releases/libva-utils/${P}.tar.bz2"
fi

LICENSE="MIT"
SLOT="0"
if [ "${PV%9999}" = "${PV}" ] ; then
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
else
	KEYWORDS=""
fi
IUSE="+drm wayland X"
REQUIRED_USE="|| ( drm wayland X )"

RDEPEND=">=x11-libs/libva-1.8.0[${MULTILIB_USEDEP}]
	drm? (	x11-libs/libdrm[${MULTILIB_USEDEP}] )
	X? (
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXfixes[${MULTILIB_USEDEP}]
	)
	wayland? ( >=dev-libs/wayland-1[${MULTILIB_USEDEP}] )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

ECONF_SOURCE="${S}"

src_prepare() {
	eautoreconf
}

multilib_src_configure() {
	myconf="\
		--disable-silent-rules
		$(use_enable X x11)
		$(use_enable wayland)
		$(use_enable drm)
		"
	econf ${myconf}

}
