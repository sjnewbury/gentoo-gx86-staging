# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-dotnet/libgdiplus/libgdiplus-2.10.9-r1.ebuild,v 1.3 2013/11/14 16:29:52 kensington Exp $

EAPI="5"

inherit base eutils mono flag-o-matic multilib-minimal

DESCRIPTION="Library for using System.Drawing with mono"
HOMEPAGE="http://www.mono-project.com"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~amd64-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"
SRC_URI="http://download.mono-project.com/sources/${PN}/${P}.tar.bz2"

IUSE="cairo"

RDEPEND=">=dev-libs/glib-2.16:2[${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.3.7[${MULTILIB_USEDEP}]
	>=media-libs/fontconfig-2.6[${MULTILIB_USEDEP}]
	>=media-libs/libpng-1.4:0[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXt[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.8.4[X,${MULTILIB_USEDEP}]
	media-libs/libexif[${MULTILIB_USEDEP}]
	>=media-libs/giflib-4.2.3[${MULTILIB_USEDEP}]
	virtual/jpeg:0[${MULTILIB_USEDEP}]
	media-libs/tiff:0[${MULTILIB_USEDEP}]
	!cairo? ( >=x11-libs/pango-1.20[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"

RESTRICT="test"

PATCHES=("${FILESDIR}/${P}-gold.patch"
	"${FILESDIR}/${PN}-2.10.1-libpng15.patch"
	"${FILESDIR}/${PN}-2.10.9-giflib-quantizebuffer.patch")

src_prepare() {
	base_src_prepare
	sed -i -e 's:ungif:gif:g' configure || die
	sed -i -e 's:freetype\/\(tttables\.h\):\1:g' src/gdiplus-private.h || die
}

multilib_src_configure() {
	append-flags -fno-strict-aliasing
	ECONF_SOURCE="${S}" econf 	--disable-dependency-tracking		\
		--disable-static			\
		--with-cairo=system			\
		$(use !cairo && printf %s --with-pango)
}

multilib_src_compile() {
	emake "$@"
}

multilib_src_install_all() {
	local commondoc=( AUTHORS ChangeLog README TODO )
	for docfile in "${commondoc[@]}"
	do
		[[ -e "${docfile}" ]] && dodoc "${docfile}"
	done
	if [[ "${DOCS[@]}" ]]
	then
		dodoc "${DOCS[@]}"
	fi
	prune_libtool_files
}
