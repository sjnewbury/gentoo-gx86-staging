# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit autotools eutils multilib-minimal

MY_P="gc-${PV}"

DESCRIPTION="The Boehm-Demers-Weiser conservative garbage collector"
HOMEPAGE="http://www.hboehm.info/gc/"
SRC_URI="http://www.hboehm.info/gc/gc_source/${MY_P}.tar.gz"

LICENSE="boehm-gc"
SLOT="0"
KEYWORDS=
IUSE="cxx static-libs threads"

DEPEND=">=dev-libs/libatomic_ops-7.4[${MULTILIB_USEDEP}]
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

ECONF_SOURCE="${S}"

multilib_src_configure() {
	local config=(
		--with-libatomic-ops
		$(use_enable cxx cplusplus)
		$(use_enable static-libs static)
		$(use threads || echo --disable-threads)
	)
	econf "${config[@]}"
}

multilib_src_compile() {
	# Workaround build errors. #574566
	use ia64 && emake src/ia64_save_regs_in_stack.lo
	use sparc && emake src/sparc_mach_dep.lo
	default
}

src_install_all() {
	default
	use static-libs || prune_libtool_files

	rm -r "${ED}"/usr/share/gc || die
	dodoc README.QUICK doc/README{.environment,.linux,.macros}
	dohtml doc/*.html
	newman doc/gc.man GC_malloc.1
}
