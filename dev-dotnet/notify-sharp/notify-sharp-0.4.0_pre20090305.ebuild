# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-dotnet/notify-sharp/notify-sharp-0.4.0_pre20090305.ebuild,v 1.8 2013/10/12 12:07:49 pacho Exp $

EAPI=5
inherit autotools eutils mono

MY_P=${PN}-${PV#*_pre}

DESCRIPTION="a C# client implementation for Desktop Notifications"
HOMEPAGE="http://www.ndesk.org/NotifySharp"
SRC_URI="mirror://gentoo/${MY_P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="doc"

RDEPEND=">=dev-lang/mono-1.1.13[${MULTILIB_USEDEP}]
	>=dev-dotnet/gtk-sharp-2.10.1[${MULTILIB_USEDEP}]
	>=dev-dotnet/dbus-sharp-0.6[${MULTILIB_USEDEP}]
	>=dev-dotnet/dbus-sharp-glib-0.4[${MULTILIB_USEDEP}]
	>=x11-libs/libnotify-0.4.5"[${MULTILIB_USEDEP}]
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}/${PN}-0.4.0_pre20080912-control-docs.patch" \
		"${FILESDIR}/${P}-dbus-sharp.patch"
	eautoreconf
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf $(use_enable doc docs)
}
