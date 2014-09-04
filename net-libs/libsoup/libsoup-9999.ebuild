# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-libs/libsoup/libsoup-2.42.3.1.ebuild,v 1.3 2013/11/30 19:46:43 pacho Exp $

EAPI="5"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python{2_6,2_7} )

inherit gnome2 python-any-r1 virtualx
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi
inherit multilib-minimal

DESCRIPTION="An HTTP library implementation in C"
HOMEPAGE="https://wiki.gnome.org/LibSoup"

LICENSE="LGPL-2+"
SLOT="2.4"
IUSE="debug +introspection samba ssl test"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
	IUSE="${IUSE} doc"
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x86-solaris"
fi


RDEPEND="
	>=dev-libs/glib-2.38.0:2[${MULTILIB_USEDEP}]
	>=dev-libs/libxml2-2:2[${MULTILIB_USEDEP}]
	dev-db/sqlite:3[${MULTILIB_USEDEP}]
	>=net-libs/glib-networking-2.30.0[ssl?,${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-0.9.5[${MULTILIB_USEDEP}] )
	samba? ( net-fs/samba )
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=dev-util/intltool-0.35
	>=dev-util/gtk-doc-am-1.10
	sys-devel/gettext
	virtual/pkgconfig
"
if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		doc? ( >=dev-util/gtk-doc-1.10 )"
fi
#	test? (	www-servers/apache[ssl,apache2_modules_auth_digest,apache2_modules_alias,apache2_modules_auth_basic,
#		apache2_modules_authn_file,apache2_modules_authz_host,apache2_modules_authz_user,apache2_modules_dir,
#		apache2_modules_mime,apache2_modules_proxy,apache2_modules_proxy_http,apache2_modules_proxy_connect]
#		dev-lang/php[apache2,xmlrpc]
#		net-misc/curl
#		net-libs/glib-networking[ssl])"

src_prepare() {
	if [[ ${PV} = 9999 ]]; then
		# prevent SOUP_MAINTAINER_FLAGS from getting set
		mv .git .git-bck || die
	fi

	if ! use test; then
		# don't waste time building tests (bug #226271)
		sed 's/^\(SUBDIRS =.*\)tests\(.*\)$/\1\2/' -i Makefile.am \
			|| die "sed failed"
	fi

	# FIXME: does not behave as expected
	sed -e 's|\(g_test_add.*\)|/*\1*/|' \
		-i tests/socket-test.c || die

	gnome2_src_prepare
}

multilib_src_configure() {
	# FIXME: we need addpredict to workaround bug #324779 until
	# root cause (bug #249496) is solved
	addpredict /usr/share/snmp/mibs/.index

	# Disable apache tests until they are usable on Gentoo, bug #326957
	G2CONF="
		--disable-static \
		--disable-tls-check \
		--without-gnome \
		--without-apache-httpd \
		$(use_enable introspection) \
		$(use_with samba ntlm-auth '${EPREFIX}'/usr/bin/ntlm_auth)
		${G2CONF}
		"

		if multilib_build_binaries ; then
			GCONF2="
				$(use_with samba ntlm-auth '${EPREFIX}'/usr/bin/ntlm_auth)
				${G2CONF}
			"
		fi

	ECONF_SOURCE="${S}" gnome2_src_configure
}

multilib_src_test() {
	# Try to prevent more test failures, bug #413233#c7
	dbus-launch
	Xemake check
}
