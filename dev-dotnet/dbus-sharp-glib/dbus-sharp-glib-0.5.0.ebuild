# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-dotnet/dbus-sharp-glib/dbus-sharp-glib-0.5.0.ebuild,v 1.7 2012/05/04 03:56:56 jdhore Exp $

EAPI=5
inherit mono

DESCRIPTION="D-Bus for .NET: GLib integration module"
HOMEPAGE="https://github.com/mono/dbus-sharp"
SRC_URI="mirror://github/mono/dbus-sharp/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND="dev-lang/mono[${MULTILIB_USEDEP}]
	>=dev-dotnet/dbus-sharp-0.7[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

ECONF_SOURCE="${S}"

pkg_setup() {
	DOCS="AUTHORS README"
}

src_prepare() {
	default
	# Fix multilib pkgconfig libdir	
	sed -i -e "s:\${exec_prefix}/lib\$:@libdir@:g" *.pc.in || die "failed to fix pkgconfig file"
}
