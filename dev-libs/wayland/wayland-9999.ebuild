# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="git://anongit.freedesktop.org/git/${PN}/${PN}"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit autotools toolchain-funcs multilib-minimal $GIT_ECLASS

DESCRIPTION="Wayland protocol libraries"
HOMEPAGE="http://wayland.freedesktop.org/"

if [[ $PV = 9999* ]]; then
	SRC_URI="${SRC_PATCHES}"
else
	SRC_URI="http://wayland.freedesktop.org/releases/${P}.tar.xz"
fi

LICENSE="CCPL-Attribution-ShareAlike-3.0 MIT"
SLOT="0"
IUSE="doc static-libs"

RDEPEND="dev-libs/expat[${MULTILIB_USEDEP}]
	virtual/libffi[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

src_prepare() {
	if [[ ${PV} = 9999* ]]; then
		eautoreconf
	fi
	multilib_copy_sources
}

multilib_src_configure() {
	myconf="$(use_enable static-libs static) \
			$(use_enable doc documentation)"
	if tc-is-cross-compiler ; then
		myconf+=" --disable-scanner"
	fi
	econf ${myconf}
}