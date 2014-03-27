# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libva-intel-driver/libva-intel-driver-9999.ebuild,v 1.9 2013/06/26 19:06:32 aballier Exp $

EAPI="5"

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SCM=git-2
	EGIT_BRANCH=cl_branch
#	EGIT_REPO_URI="git://anongit.freedesktop.org/git/vaapi/intel-driver"
EGIT_REPO_URI=git://people.freedesktop.org/~yakuiz/intel-driver
fi

inherit autotools ${SCM} multilib-minimal

DESCRIPTION="HW video decode support for Intel integrated graphics"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/vaapi"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
	S="${WORKDIR}/${PN}"
else
	SRC_URI="http://www.freedesktop.org/software/vaapi/releases/libva-intel-driver/${P}.tar.bz2"
fi

LICENSE="MIT"
SLOT="0"
if [ "${PV%9999}" = "${PV}" ] ; then
	KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
else
	KEYWORDS=""
fi
IUSE="+drm wayland X opencl"

RDEPEND=">=x11-libs/libva-1.2.0[X?,wayland?,drm?,${MULTILIB_USEDEP}]
	!<x11-libs/libva-1.0.15[video_cards_intel,${MULTILIB_USEDEP}]
	>=x11-libs/libdrm-2.4.45[video_cards_intel,${MULTILIB_USEDEP}]
	wayland? ( media-libs/mesa[egl,${MULTILIB_USEDEP}] >=dev-libs/wayland-1[${MULTILIB_USEDEP}] )
	opencl? ( media-libs/mesa[beignet,${MULTILIB_USEDEP}] )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

ECONF_SOURCE="${S}"

src_prepare() {
	eautoreconf
}

multilib_src_configure() {
	econf \
		--disable-silent-rules \
		$(use_enable drm) \
		$(use_enable wayland) \
		$(use_enable X x11) \
		$(use_enable opencl)
}

multilib_src_install() {
	emake DESTDIR="${D}" install || die
}

multilib_src_install_all() {
	dodoc AUTHORS NEWS README || die
	find "${D}" -name '*.la' -delete
}
