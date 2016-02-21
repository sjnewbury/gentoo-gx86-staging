# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gst-plugins-dash/gst-plugins-dash-1.2.4-r1.ebuild,v 1.2 2014/06/18 20:01:58 mgorny Exp $

EAPI="5"

GST_ORG_MODULE=gst-plugins-bad
inherit gstreamer

DESCRIPTION="MPEG-DASH plugin"

KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=dev-libs/libxml2-2.9.1-r4[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

# FIXME: gsturidownloader does not have a .pc
#src_prepare() {
#	gstreamer_system_link \
#		gst-libs/gst/uridownloader:gsturidownloader
#}

multilib_src_compile() {
	emake -C gst-libs/gst/uridownloader

	gstreamer_multilib_src_compile
}