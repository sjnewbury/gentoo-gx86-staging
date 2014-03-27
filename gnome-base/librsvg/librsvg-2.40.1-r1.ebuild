# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/librsvg/librsvg-2.40.1-r1.ebuild,v 1.3 2014/02/22 21:49:00 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit autotools gnome2 vala multilib-minimal

DESCRIPTION="Scalable Vector Graphics (SVG) rendering library"
HOMEPAGE="https://wiki.gnome.org/Projects/LibRsvg"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+introspection vala tools"
REQUIRED_USE="
	vala? ( introspection )
"

RDEPEND="
	>=dev-libs/glib-2.24:2[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.2[${MULTILIB_USEDEP}]
	>=x11-libs/pango-1.32.6[${MULTILIB_USEDEP}]
	>=dev-libs/libxml2-2.7:2[${MULTILIB_USEDEP}]
	>=dev-libs/libcroco-0.6.1[${MULTILIB_USEDEP}]
	>=x11-libs/gdk-pixbuf-2.20:2[introspection?,${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-0.10.8[${MULTILIB_USEDEP}] )
	tools? ( >=x11-libs/gtk+-3.2.0:3[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	dev-libs/gobject-introspection-common
	dev-libs/vala-common
	>=dev-util/gtk-doc-am-1.13
	virtual/pkgconfig
	vala? ( $(vala_depend) )
"
# >=gtk-doc-am-1.13, gobject-introspection-common, vala-common needed by eautoreconf

src_prepare() {
	# https://bugzilla.gnome.org/show_bug.cgi?id=712693
	epatch "${FILESDIR}/${PN}-2.40.1-gtk-optional.patch"
	# Fix out of source tree build - vala file is in srcdir not builddir
	epatch "${FILESDIR}"/${PN}-2.39.0-out-of-source.patch
	# old "missing" file causes eautoreconf warnings
	rm missing
	eautoreconf

	use vala && vala_src_prepare
	gnome2_src_prepare
}

multilib_src_configure() {
	local myconf=""

	# -Bsymbolic is not supported by the Darwin toolchain
	if [[ ${CHOST} == *-darwin* ]]; then
		myconf="${myconf} --disable-Bsymbolic"
	fi

	if multilib_build_binaries; then
		myconf="${myconf} $(use_enable vala) $(use_with tools gtk3)"
	fi
	
	# --disable-tools even when USE=tools; the tools/ subdirectory is useful
	# only for librsvg developers
	ECONF_SOURCE="${S}" gnome2_src_configure \
		--disable-static \
		--disable-tools \
		$(use_enable introspection) \
		--enable-pixbuf-loader \
		${myconf}
}

multilib_src_compile() {
	# causes segfault if set, see bug #411765
	unset __GL_NO_DSO_FINALIZER
	gnome2_src_compile
}

pkg_postinst() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER
	gnome2_pkg_postinst
}

pkg_postrm() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER
	gnome2_pkg_postrm
}
