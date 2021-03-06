# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/graphite2/graphite2-1.2.1.ebuild,v 1.14 2013/10/12 21:53:33 hwoarang Exp $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

GENTOO_DEPEND_ON_PERL="no"
inherit base flag-o-matic eutils cmake-utils perl-module python-any-r1 multilib-minimal

DESCRIPTION="Library providing rendering capabilities for complex non-Roman writing systems"
HOMEPAGE="http://graphite.sil.org/"
SRC_URI="mirror://sourceforge/silgraphite/${PN}/${P}.tgz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x64-solaris"
IUSE="perl test"

RDEPEND="
	perl? ( dev-lang/perl )
"
DEPEND="${RDEPEND}
	perl? ( virtual/perl-Module-Build )
	test? (
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		media-libs/fontconfig[${MULTILIB_USEDEP}]
		media-libs/silgraphite[${MULTILIB_USEDEP}]
		${PYTHON_DEPS}
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-1.1.0-includes-libs-perl.patch"
	"${FILESDIR}/${PN}-1.0.2-no_harfbuzz_tests.patch"
	"${FILESDIR}/${PN}-1.0.3-no-test-binaries.patch"
	"${FILESDIR}/${PN}-1.2.0-solaris.patch"
)

pkg_setup() {
	use perl && perl-module_pkg_setup
	use test && python-any-r1_pkg_setup
}

fix_perl_linking() {
	_check_build_dir init
	sed -i \
		-e "s:@BUILD_DIR@:\"${CMAKE_BUILD_DIR}/src\":" \
		contrib/perl/Build.PL || die
}

src_prepare() {
	base_src_prepare

	# make tests optional
	if ! use test; then
		sed -i \
			-e '/tests/d' \
			CMakeLists.txt || die
	fi

	multilib_copy_sources
	
	# fix perl linking
	if use perl; then
		multilib_foreach_abi fix_perl_linking
	fi
}

multilib_src_configure() {
	local mycmakeargs=(
		"-DVM_MACHINE_TYPE=direct"
		# http://sourceforge.net/p/silgraphite/bugs/49/
		$([[ ${CHOST} == powerpc*-apple* ]] && \
			echo "-DGRAPHITE2_NSEGCACHE:BOOL=ON")
	)

	cmake-utils_src_configure
}

multilib_src_compile() {
	cmake-utils_src_compile
	if multilib_is_native_abi && use perl; then
		cd contrib/perl
		perl-module_src_prep
		perl-module_src_compile
	fi
}

multilib_src_test() {
	cmake-utils_src_test
	if multilib_is_native_abi && use perl; then
		cd contrib/perl
		perl-module_src_test
	fi
}

multilib_src_install() {
	cmake-utils_src_install
	if multilib_is_native_abi && use perl; then
		cd contrib/perl
		perl-module_src_install
		fixlocalpod
	fi
}

multilib_src_install_all() {
	prune_libtool_files --all
}
