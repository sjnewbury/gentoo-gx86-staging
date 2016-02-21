# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/ldb/ldb-1.1.20.ebuild,v 1.2 2015/03/03 10:04:01 dlan Exp $

EAPI=5
PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE="threads"

inherit python-single-r1 waf-utils multilib multilib-minimal

DESCRIPTION="An LDAP-like embedded database"
HOMEPAGE="http://ldb.samba.org"
SRC_URI="http://www.samba.org/ftp/pub/${PN}/${P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0/${PV}"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~x86 ~amd64-fbsd ~x86-fbsd"
IUSE="doc +python"

RDEPEND="python? ( ${PYTHON_DEPS} )
dev-libs/popt
	>=sys-libs/talloc-2.1.1[python,${MULTILIB_USEDEP}]
	>=sys-libs/tevent-0.9.22[python(+),${MULTILIB_USEDEP}]
	>=sys-libs/tdb-1.3.4[python,${MULTILIB_USEDEP}]
	net-nds/openldap[${MULTILIB_USEDEP}]
	!!<net-fs/samba-3.6.0[ldb]
	!!>=net-fs/samba-4.0.0[ldb]
	${PYTHON_DEPS}
	"

DEPEND="dev-libs/libxslt
	doc? ( app-doc/doxygen )
	virtual/pkgconfig
	${RDEPEND}"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

WAF_BINARY="${S}/buildtools/bin/waf"

MULTILIB_WRAPPED_HEADERS=(
	# python goes only for native
	/usr/include/pyldb.h
)

pkg_setup() {
	python-single-r1_pkg_setup
}

ldb_build_with_python() {
	if ! multilib_is_native_abi || ! use python; then
		pushd "${BUILD_DIR}"
		epatch "${FILESDIR}"/disable-pyldb.patch
		popd
	fi
}

src_prepare() {
	epatch_user
	multilib_copy_sources
	multilib_foreach_abi ldb_build_with_python
}

multilib_src_configure() {
	waf-utils_src_configure \
		--disable-rpath \
		--disable-rpath-install --bundled-libraries=NONE \
		--with-modulesdir="${EPREFIX}"/usr/$(get_libdir)/samba \
		--builtin-libraries=NONE
}

multilib_src_compile(){
	waf-utils_src_compile
	use doc && doxygen Doxyfile
}

multilib_src_test() {
	WAF_MAKE=1 \
	PATH=buildtools/bin:../../../buildtools/bin:$PATH:"${BUILD_DIR}"/bin/shared/private/ \
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"${BUILD_DIR}"/bin/shared/private/:"${BUILD_DIR}"/bin/shared waf test || die
}

multilib_src_install() {
	waf-utils_src_install
}

multilib_src_install_all() {
	if use doc; then
		dohtml -r apidocs/html/*
		doman  apidocs/man/man3/*.3
	fi
}

pkg_postinst() {
	if has_version sys-auth/sssd; then
		ewarn "You have sssd installed. It is known to break after ldb upgrades,"
		ewarn "so please try to rebuild it before reporting bugs."
		ewarn "See http://bugs.gentoo.org/404281"
	fi
}