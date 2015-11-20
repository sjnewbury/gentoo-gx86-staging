# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"

inherit autotools eutils multilib toolchain-funcs gnome2-live multilib-minimal

DESCRIPTION="Internationalized text layout and rendering library"
HOMEPAGE="http://www.pango.org/"

LICENSE="LGPL-2+ FTL"
SLOT="0"

IUSE="X +introspection"

RDEPEND="
	>=media-libs/harfbuzz-0.9.9:=[glib(+),truetype(+),${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.33.12:2[${MULTILIB_USEDEP}]
	>=media-libs/fontconfig-2.10.91:1.0=[${MULTILIB_USEDEP}]
	media-libs/freetype:2=[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.12.10:=[X?,${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-0.9.5[${MULTILIB_USEDEP}] )
	X? (
		x11-libs/libXrender[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		>=x11-libs/libXft-2.0.0[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	>=dev-util/gtk-doc-am-1.15
	virtual/pkgconfig
	X? ( x11-proto/xproto[${MULTILIB_USEDEP}] )
	!<=sys-devel/autoconf-2.63:2.5
"

ECONF_SOURCE="${S}"

src_prepare() {
	epatch "${FILESDIR}/${P}-lib64.patch"
	eautoreconf

	gnome2_src_prepare
}

multilib_src_configure() {
	tc-export CXX

	gnome2_src_configure \
		--with-cairo \
		$(use_enable introspection) \
		$(use_with X xft) \
		"$(usex X --x-includes="${EPREFIX}/usr/include" "")" \
		"$(usex X --x-libraries="${EPREFIX}/usr/$(get_libdir)" "")"
}

multilib_src_install_all() {
	local PANGO_CONFDIR="/etc/pango/${CHOST}"
	dodir "${PANGO_CONFDIR}"
	keepdir "${PANGO_CONFDIR}"
}

pkg_postinst() {
	gnome2_pkg_postinst

	einfo "Generating modules listing..."
	local PANGO_CONFDIR="${EROOT}/etc/pango/${CHOST}"
	local pango_conf="${PANGO_CONFDIR}/pango.modules"
	local tmp_file=$(mktemp -t tmp_pango_ebuild.XXXXXXXXXX)

	# be atomic!
	if pango-querymodules --system \
		"${EROOT}"usr/$(get_libdir)/pango/1.8.0/modules/*$(get_modname) \
			> "${tmp_file}"; then
		cat "${tmp_file}" > "${pango_conf}" || {
			rm "${tmp_file}"; die; }
	else
		ewarn "Cannot update pango.modules, file generation failed"
	fi
	rm "${tmp_file}"

	if [[ ${REPLACING_VERSIONS} < 1.30.1 ]]; then
		elog "In >=${PN}-1.30.1, default configuration file locations moved from"
		elog "~/.pangorc and ~/.pangox_aliases to ~/.config/pango/pangorc and"
		elog "~/.config/pango/pangox.aliases"
	fi
}
