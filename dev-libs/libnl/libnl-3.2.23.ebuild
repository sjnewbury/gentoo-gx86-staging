# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libnl/libnl-3.2.23.ebuild,v 1.1 2013/11/03 16:50:09 jer Exp $

EAPI=5
PYTHON_COMPAT=( python2_{6,7} python3_{2,3} )
DISTUTILS_OPTIONAL=1
inherit distutils-r1 eutils libtool multilib multilib-minimal

NL_P=${P/_/-}

DESCRIPTION="A collection of libraries providing APIs to netlink protocol based Linux kernel interfaces"
HOMEPAGE="http://www.infradead.org/~tgr/libnl/"
SRC_URI="
	http://www.infradead.org/~tgr/${PN}/files/${NL_P}.tar.gz
"
LICENSE="LGPL-2.1 utils? ( GPL-2 )"
SLOT="3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="static-libs python utils"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}
	python? ( dev-lang/swig )
	sys-devel/flex
	sys-devel/bison
"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DOCS=( ChangeLog )

S=${WORKDIR}/${NL_P}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.1-vlan-header.patch
	epatch "${FILESDIR}"/${PN}-3.2.20-rtnl_tc_get_ops.patch
	epatch "${FILESDIR}"/${PN}-3.2.20-cache-api.patch
	epatch "${FILESDIR}"/${PN}-3.2.22-python.patch

	elibtoolize

	if use python; then
		cp "${FILESDIR}"/${P}-utils.h python/netlink/utils.h || die
		cd "${S}"/python || die
		distutils-r1_src_prepare
	fi

	multilib_copy_sources
}

multilib_src_configure() {
	local myeconfargs=()
	myeconfargs+=(
		--disable-silent-rules
		$(use_enable static-libs static)
	)

	if multilib_build_binaries ; then
	myeconfargs+=(
		$(use_enable utils cli)
	)
	fi
	econf "${myeconfargs[@]}"

	if multilib_build_binaries && use python; then
		cd "${BUILD_DIR}"/python || die
		distutils-r1_src_configure
	fi
}

multilib_src_compile() {
	default

	if multilib_build_binaries && use python; then
		cd "${BUILD_DIR}"/python || die
		distutils-r1_src_compile
	fi
}

multilib_src_install() {
	default

	if multilib_build_binaries && use python ; then
		# Unset DOCS= since distutils-r1.eclass interferes
		DOCS=''
		cd "${BUILD_DIR}"/python || die
		distutils-r1_src_install
	fi
}

multilib_src_install_all() {
	prune_libtool_files $(usex static-libs --modules --all)
}
