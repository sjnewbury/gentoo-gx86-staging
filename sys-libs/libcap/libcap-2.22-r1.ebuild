# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libcap/libcap-2.22-r1.ebuild,v 1.2 2013/02/17 07:58:20 zmedico Exp $

EAPI="4"

inherit eutils multilib toolchain-funcs pam multilib-minimal

DESCRIPTION="POSIX 1003.1e capabilities"
HOMEPAGE="http://www.friedhoff.org/posixfilecaps.html"
SRC_URI="mirror://kernel/linux/libs/security/linux-privs/libcap${PV:0:1}/${P}.tar.bz2"

# it's available under either of the licenses
LICENSE="|| ( GPL-2 BSD )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux"
IUSE="pam"

RDEPEND="sys-apps/attr[${MULTILIB_USEDEP}]
	pam? ( virtual/pam[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	sys-kernel/linux-headers"

_multilib_substitute() {
	sed -i \
				-e "/^PAM_CAP/s:=.*:=$(usex pam):" \
				-e '/^DYNAMIC/s:=.*:=yes:' \
				-e "/^lib=/s:=.*:=/usr/$(get_libdir):" \
				${BUILD_DIR}/Make.Rules || die
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.22-build-system-fixes.patch
	epatch "${FILESDIR}"/${PN}-2.22-no-perl.patch
	epatch "${FILESDIR}"/${PN}-2.20-ignore-RAISE_SETFCAP-install-failures.patch
	epatch "${FILESDIR}"/${PN}-2.21-include.patch

	multilib_copy_sources

	multilib_parallel_foreach_abi _multilib_substitute
}

multilib_src_configure() {
	tc-export_build_env BUILD_CC
	tc-export CC AR RANLIB
}

multilib_src_install() {
	# no configure, needs explicit install line #444724#c3
	emake install DESTDIR="${ED}"

	gen_usr_ldscript -a cap

	dopammod pam_cap/pam_cap.so
	dopamsecurity '' pam_cap/capability.conf

	rm -rf "${ED}"/usr/$(get_libdir)/security
}

multilib_src_install_all() {

	dodoc CHANGELOG README doc/capability.notes
}
