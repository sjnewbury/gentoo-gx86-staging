# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/gst-plugins-neon/gst-plugins-neon-1.2.4-r1.ebuild,v 1.2 2014/06/18 20:15:50 mgorny Exp $

EAPI="5"

GST_ORG_MODULE=gst-plugins-bad
inherit gstreamer

KEYWORDS="~alpha ~amd64 ~ppc ~ppc64 ~x86"
IUSE=""

RDEPEND=">=net-libs/neon-0.30.0[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"
