# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/dbus-glib/dbus-glib-0.100.2.ebuild,v 1.12 2013/03/05 09:12:15 ago Exp $

EAPI=5
inherit bash-completion-r1 eutils multilib-minimal

DESCRIPTION="D-Bus bindings for glib"
HOMEPAGE="http://dbus.freedesktop.org/"
SRC_URI="http://dbus.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="|| ( GPL-2 AFL-2.1 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="debug doc static-libs test"

RDEPEND=">=dev-libs/expat-2[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.26:2[${MULTILIB_USEDEP}]
	>=sys-apps/dbus-1.6.2[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.4 )"

src_prepare() {
	# Fix testsuite, bug #356699 (fixed in git master)
	epatch "${FILESDIR}"/${PN}-0.100-fix-tests.patch

	# Wrong sections.txt file in the tarball; https://bugs.freedesktop.org/show_bug.cgi?id=55830
	cp "${FILESDIR}"/${PN}-0.100-dbus-glib-sections.txt doc/reference/dbus-glib-sections.txt || die
}

multilib_src_configure() {
	local myconf=(
		--localstatedir="${EPREFIX}"/var
		--enable-bash-completion
		$(use_enable debug verbose-mode)
		$(use_enable debug asserts)
		$(use_enable static-libs static)
		$(use_enable doc gtk-doc)
		)

	ECONF_SOURCE="${S}" econf "${myconf[@]}"

	if use test; then
		mkdir "${BUILD_DIR}-tests"
		cd "${BUILD_DIR}-tests"
		ECONF_SOURCE="${S}" econf \
			"${myconf[@]}" \
			$(use_enable test checks) \
			$(use_enable test tests) \
			$(use_enable test asserts) \
			$(use_with test test-socket-dir "${T}"/dbus-test-socket)
	fi
}

multilib_src_compile() {
	emake

	if use test; then
		cd "${BUILD_DIR}-tests"
		einfo "Running make in ${BUILD_DIR}-tests"
		emake
	fi
}

multilib_src_test() {
	cd "${BUILD_DIR}-tests"
	emake check
}

multilib_src_install_all() {
	# NEWS file is obsolete
	dodoc AUTHORS ChangeLog HACKING README

	newbashcomp "${ED}"/etc/bash_completion.d/dbus-bash-completion.sh dbus
	rm -rf "${ED}"/etc/bash_completion.d || die

	prune_libtool_files
}
