# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-i18n/enca/enca-1.14.ebuild,v 1.2 2013/04/26 20:29:33 pva Exp $

EAPI="5"

inherit eutils toolchain-funcs autotools-multilib

DESCRIPTION="ENCA detects the character coding of a file and converts it if desired"
HOMEPAGE="http://gitorious.org/enca"
SRC_URI="http://dl.cihar.com/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="doc +recode"

DEPEND="recode? ( >=app-text/recode-3.6_p15 )"
RDEPEND="${DEPEND}"

AUTOTOOLS_AUTORECONF=2.52

src_prepare() {
	epatch "${FILESDIR}"/${PN}-remove-dirty-path-hack.patch
	epatch "${FILESDIR}"/${P}-automake-1.13.patch
	rm missing # too old, automake will update it
	# fix crosscompilation, bug #424473
	if tc-is-cross-compiler; then
		sed -e "s#./make_hash#./native_make_hash#" -i tools/Makefile.am || die
	fi
	autotools-multilib_src_prepare
}

src_configure() {
	local myeconfargs=(
		--enable-external
		--disable-static
		$(use_with recode librecode "${EPREFIX}"/usr)
		$(use_enable doc gtk-doc)
	)
	autotools-multilib_src_configure
}

enca_native_hashmap() {
	if tc-is-cross-compiler; then
		pushd "${BUILD_DIR}"/tools > /dev/null
		$(tc-getBUILD_CC) -o native_make_hash "${S}"/tools/make_hash.c || die "native make_hash failed"
		popd > /dev/null
	fi
}

src_compile() {
	multilib_foreach_abi enca_native_hashmap
	autotools-multilib_src_compile
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	# Symlinks for installclash
	if ! multilib_build_binaries ; then
		rm -rf "${ED}"/usr/bin/*
		rm -rf "${ED}"/usr/share/man/*
	fi
}
