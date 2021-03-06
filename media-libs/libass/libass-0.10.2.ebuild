# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libass/libass-0.10.1.ebuild,v 1.12 2013/07/06 17:08:27 ago Exp $

EAPI=5

inherit eutils multilib-minimal

DESCRIPTION="Library for SSA/ASS subtitles rendering"
HOMEPAGE="http://code.google.com/p/libass/"
SRC_URI="http://libass.googlecode.com/files/${P}.tar.xz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="+enca +fontconfig +harfbuzz static-libs"

RDEPEND="fontconfig? ( >=media-libs/fontconfig-2.4.2[${MULTILIB_USEDEP}] )
	>=media-libs/freetype-2.4:2[${MULTILIB_USEDEP}]
	virtual/libiconv[${MULTILIB_USEDEP}]
	>=dev-libs/fribidi-0.19.0[${MULTILIB_USEDEP}]
	harfbuzz? ( >=media-libs/harfbuzz-0.9.11[${MULTILIB_USEDEP}] )
	enca? ( app-i18n/enca[${MULTILIB_USEDEP}] )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

DOCS="Changelog"

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		$(use_enable enca) \
		$(use_enable fontconfig) \
		$(use_enable harfbuzz) \
		$(use_enable static-libs static)
}

multilib_src_install_all() {
	prune_libtool_files
}
