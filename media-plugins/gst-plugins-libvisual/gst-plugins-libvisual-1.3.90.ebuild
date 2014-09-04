# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gst-plugins-libvisual/gst-plugins-libvisual-1.2.4-r1.ebuild,v 1.2 2014/06/18 20:12:28 mgorny Exp $

EAPI="5"

GST_ORG_MODULE=gst-plugins-base
inherit gstreamer

KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd"
IUSE=""

RDEPEND=">=media-libs/libvisual-0.4.0-r3[${MULTILIB_USEDEP}]
	>=media-plugins/libvisual-plugins-0.4.0-r3[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

src_prepare() {
	gstreamer_system_link \
		gst-libs/gst/audio:gstreamer-audio \
		gst-libs/gst/video:gstreamer-video
}
