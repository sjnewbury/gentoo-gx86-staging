# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/icu/icu-51.2-r1.ebuild,v 1.11 2013/11/12 20:12:53 ago Exp $

EAPI=5

inherit eutils toolchain-funcs base autotools multilib-minimal

DESCRIPTION="International Components for Unicode"
HOMEPAGE="http://www.icu-project.org/"
SRC_URI="http://download.icu-project.org/files/icu4c/${PV/_/}/icu4c-${PV//./_}-src.tgz"

LICENSE="BSD"

SLOT="0/51.2"
# As far as I can remember, icu consumers reacted rather sensitive to icu upgrades in the past. 
# Even if revdep-rebuild did not rebuild (i.e. soname did not change), random crashes and 
# other irregularities occured until the consumers were rebuilt. So let's rather err on the side
# of caution and more rebuilds here. See also bug 464876. dilfridge

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd"
IUSE="debug doc examples static-libs"

DEPEND="
	doc? (
		app-doc/doxygen[dot]
	)
"

S="${WORKDIR}/${PN}/source"

PATCHES=(
	"${FILESDIR}/${PN}-51.1-CVE-2013-2924.patch"
)

ECONF_SOURCE="${S}"

src_prepare() {
	local variable

	base_src_prepare

	# Do not hardcode flags in icu-config and icu-*.pc files.
	# https://ssl.icu-project.org/trac/ticket/6102
	for variable in CFLAGS CPPFLAGS CXXFLAGS FFLAGS LDFLAGS; do
		sed \
			-e "/^${variable} =.*/s: *@${variable}@\( *$\)\?::" \
			-i config/icu.pc.in \
			-i config/Makefile.inc.in \
			|| die
	done

	# Disable renaming as it is stupind thing to do
	sed -i \
		-e "s/#define U_DISABLE_RENAMING 0/#define U_DISABLE_RENAMING 1/" \
		common/unicode/uconfig.h || die

	# Fix linking of icudata
	sed -i \
		-e "s:LDFLAGSICUDT=-nodefaultlibs -nostdlib:LDFLAGSICUDT=:" \
		config/mh-linux || die

	# Append doxygen configuration to configure
	sed -i \
		-e 's:icudefs.mk:icudefs.mk Doxyfile:' \
		configure.in || die
	eautoreconf
}

multilib_src_configure() {
	local cross_opts

	# bootstrap for cross compilation
	if tc-is-cross-compiler; then
		CFLAGS="" CXXFLAGS="" ASFLAGS="" LDFLAGS="" \
		CC="$(tc-getBUILD_CC)" CXX="$(tc-getBUILD_CXX)" AR="$(tc-getBUILD_AR)" \
		RANLIB="$(tc-getBUILD_RANLIB)" LD="$(tc-getBUILD_LD)" \
		./configure --disable-renaming --disable-debug \
			--disable-samples --enable-static || die
		emake
		mkdir -p "${WORKDIR}/host/"
		cp -a {bin,lib,config,tools} "${WORKDIR}/host/"
		emake clean

		cross_opts="--with-cross-build=${WORKDIR}/host"
	fi

	econf \
		--disable-renaming \
		$(use_enable debug) \
		$(use_enable examples samples) \
		$(use_enable static-libs static) \
		${cross_opts}
}

multilib_src_compile() {
	default

	if use doc; then
		doxygen -u Doxyfile || die
		doxygen Doxyfile || die
	fi
}

multilib_src_test() {
	# INTLTEST_OPTS: intltest options
	#   -e: Exhaustive testing
	#   -l: Reporting of memory leaks
	#   -v: Increased verbosity
	# IOTEST_OPTS: iotest options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	# CINTLTST_OPTS: cintltst options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	emake -j1 VERBOSE="1" check
}

multilib_src_install_all() {
	dohtml ../readme.html

	use doc && dohtml -p api -r doc/html/
}
