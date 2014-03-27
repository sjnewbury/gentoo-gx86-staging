# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/gdbm/gdbm-1.10.ebuild,v 1.3 2013/02/17 20:03:35 zmedico Exp $

EAPI="4"

inherit flag-o-matic libtool multilib multilib-minimal

EX_P="${PN}-1.8.3"
DESCRIPTION="Standard GNU database libraries"
HOMEPAGE="http://www.gnu.org/software/gdbm/"
SRC_URI="mirror://gnu/gdbm/${P}.tar.gz
	exporter? ( mirror://gnu/gdbm/${EX_P}.tar.gz )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="+berkdb exporter static-libs"

RDEPEND="
	abi_x86_32? (
		!<=app-emulation/emul-linux-x86-baselibs-20131008-r4
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
	)"

EX_S="${WORKDIR}"/${EX_P}

src_prepare() {
	elibtoolize
}

multilib_src_configure() {
	# gdbm doesn't appear to use either of these libraries
	export ac_cv_lib_dbm_main=no ac_cv_lib_ndbm_main=no

	if multilib_build_binaries && use exporter ; then
		mkdir "${BUILD_DIR}"/"${EX_P}"
		pushd "${BUILD_DIR}"/"${EX_P}" >/dev/null
		append-lfs-flags
		ECONF_SOURCE="${EX_S}" \
		econf --disable-shared
		popd >/dev/null
	fi

	ECONF_SOURCE="${S}" \
	econf \
		--includedir="${EPREFIX}"/usr/include/gdbm \
		--with-gdbm183-libdir="${BUILD_DIR}/${EX_P}/.libs" \
		--with-gdbm183-includedir="${EX_S}" \
		$(use_enable berkdb libgdbm-compat) \
		$(use_enable exporter gdbm-export) \
		$(use_enable static-libs static)
}

multilib_src_compile() {
	if use exporter ; then
		emake -C "${BUILD_DIR}"/"${EX_P}" libgdbm.la
	fi

	emake
}

multilib_src_install_all() {
	use static-libs || find "${ED}" -name '*.la' -delete
	mv "${ED}"/usr/include/gdbm/gdbm.h "${ED}"/usr/include/ || die
}

pkg_preinst() {
	preserve_old_lib libgdbm{,_compat}.so.{2,3} #32510
}

pkg_postinst() {
	preserve_old_lib_notify libgdbm{,_compat}.so.{2,3} #32510
}
