# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:

EAPI=5

MY_P=${PN}-${PV/_rc/rc}
inherit eutils cmake-multilib

DESCRIPTION="Access a working SSH implementation by means of a library"
HOMEPAGE="http://www.libssh.org/"
SRC_URI="https://red.libssh.org/attachments/download/87/${MY_P}.tar.xz -> ${P}.tar.xz"

LICENSE="LGPL-2.1"
KEYWORDS="amd64 ~arm ~hppa ~s390 x86 ~amd64-linux ~x86-linux"
SLOT="0/4" # subslot = soname major version
IUSE="debug doc examples gcrypt kerberos pcap +sftp ssh1 server static-libs test zlib"
# Maintainer: check IUSE-defaults at DefineOptions.cmake

RDEPEND="
	zlib? ( >=sys-libs/zlib-1.2[${MULTILIB_USEDEP}] )
	!gcrypt? ( >=dev-libs/openssl-0.9.8[${MULTILIB_USEDEP}] )
	gcrypt? ( >=dev-libs/libgcrypt-1.5[${MULTILIB_USEDEP}] )
	kerberos? ( virtual/krb5[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	test? ( dev-util/cmocka )
"

DOCS=( AUTHORS README ChangeLog )

S=${WORKDIR}/${MY_P}

PATCHES=(
		"${FILESDIR}/${PN}-0.5.0-tests.patch"
		"${FILESDIR}/${PN}-0.6.0-libgcrypt-1.6.0.patch"
)

src_prepare() {
	# just install the examples do not compile them
	sed -i \
		-e '/add_subdirectory(examples)/s/^/#DONOTWANT/' \
		CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		$(cmake-multilib_use_with debug DEBUG_CALLTRACE)
		$(cmake-multilib_use_with debug DEBUG_CRYPTO)
		$(cmake-multilib_use_with gcrypt)
		$(cmake-multilib_use_with kerberos gssapi)
		$(cmake-multilib_use_with pcap)
		$(cmake-multilib_use_with server)
		$(cmake-multilib_use_with sftp)
		$(cmake-multilib_use_with ssh1)
		$(cmake-multilib_use_with static-libs STATIC_LIB)
		$(cmake-multilib_use_with test STATIC_LIB)
		$(cmake-multilib_use_with test TESTING)
		$(cmake-multilib_use_with zlib)
	)

	cmake-multilib_src_configure
}

src_compile() {
	cmake-multilib_src_compile
	use doc && cmake-multilib_src_compile doc
}

src_install() {
	cmake-multilib_src_install

	use doc && dohtml -r "${CMAKE_BUILD_DIR}"/doc/html/*

	use static-libs || rm -f "${D}"/usr/$(get_libdir)/libssh{,_threads}.a

	if use examples; then
		docinto examples
		dodoc examples/*.{c,h,cpp}
	fi
}
