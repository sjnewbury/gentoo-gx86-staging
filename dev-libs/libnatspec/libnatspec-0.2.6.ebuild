# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libnatspec/libnatspec-0.2.6.ebuild,v 1.17 2012/07/15 18:17:10 armin76 Exp $

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )

inherit python-any-r1 autotools eutils multilib-minimal

DESCRIPTION="library to smooth charset/localization issues"
HOMEPAGE="http://natspec.sourceforge.net/"
SRC_URI="mirror://sourceforge/natspec/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc python"

RDEPEND="dev-libs/popt[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	python? ( dev-lang/tcl )"

ECONF_SOURCE="${S}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-iconv.patch
	epatch "${FILESDIR}"/${P}-builddir.patch
	# regenerate to fix imcompatible readlink usage
	rm -f "${S}"/ltmain.sh "${S}"/libtool
	eautoreconf
}

multilib_src_configure() {
	if multilib_is_native_abi ; then
		use doc || export ac_cv_prog_DOX=no
		use python && export PYTHON2="${PYTHON}" \

		# braindead configure script does not disable python on --without-python
		econf $(use python && use_with python)
	else
		# Only build optional docs and python binding on native ABI
		export ac_cv_prog_DOX=no
		econf
	fi
}

multilib_src_install_all() {
	dodoc ChangeLog NEWS README TODO
}
