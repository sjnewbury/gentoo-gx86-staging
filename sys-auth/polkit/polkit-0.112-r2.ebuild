# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:

EAPI=5
inherit eutils autotools multilib pam pax-utils systemd user multilib-minimal

DESCRIPTION="Policy framework for controlling privileges for system-wide services"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/polkit"
SRC_URI="http://www.freedesktop.org/software/${PN}/releases/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="examples gtk +introspection jit kde nls pam selinux systemd"

RDEPEND="ia64? ( =dev-lang/spidermonkey-1.8.5*[-debug,${MULTILIB_USEDEP}] )
	!ia64? ( dev-lang/spidermonkey:17[-debug,jit=,${MULTILIB_USEDEP}] )
	>=dev-libs/glib-2.32[${MULTILIB_USEDEP}]
	>=dev-libs/expat-2:=[${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-1[${MULTILIB_USEDEP}] )
	pam? (
		sys-auth/pambase
		virtual/pam
		)
	selinux? ( sec-policy/selinux-policykit[${MULTILIB_USEDEP}] )
	systemd? ( sys-apps/systemd[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	app-text/docbook-xml-dtd:4.1.2
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	dev-util/intltool
	virtual/pkgconfig"
PDEPEND="
	gtk? ( || (
		>=gnome-extra/polkit-gnome-0.105
		lxde-base/lxpolkit
		) )
	kde? ( sys-auth/polkit-kde-agent )
	!systemd? ( sys-auth/consolekit[policykit] )"

QA_MULTILIB_PATHS="
	usr/lib/polkit-1/polkit-agent-helper-1
	usr/lib/polkit-1/polkitd"

pkg_setup() {
	local u=polkitd
	local g=polkitd
	local h=/var/lib/polkit-1

	enewgroup ${g}
	enewuser ${u} -1 -1 ${h} ${g}
	esethome ${u} ${h}
}

src_prepare() {
	sed -i -e 's|unix-group:wheel|unix-user:0|' src/polkitbackend/*-default.rules || die #401513

	# Native binaries should not be kept in /usr/lib on multilib systems
	# since /usr/lib can be used for x86 on amd64 multilib.
	epatch "${FILESDIR}"/"${P}"-libexec.patch

	eautoreconf
}

multilib_src_configure() {
	local myeconfargs=()
	if multilib_is_native_abi ; then
		myeconfargs=(
		--localstatedir="${EPREFIX}"/var
		--disable-static
		--enable-man-pages
		--disable-gtk-doc
		$(use_enable systemd libsystemd-login)
		$(use_enable introspection)
		--disable-examples
		$(use_enable nls)
		$(usex ia64 --with-mozjs=mozjs185 --with-mozjs=mozjs-17.0)
		"$(systemd_with_unitdir)"
		--with-authfw=$(usex pam pam shadow)
		$(use pam && echo --with-pam-module-dir="$(getpam_mod_dir)")
		--with-os-type=gentoo
		)
	else
		# Do not use PAM, prevents dependency on non-native ABI.
		# libpolkit* otherwise links with systemd/libgobject etc
		# so these options are still required for all ABIs.
		# mozjs is not required by libpolkit-*, but disabling it would
		# require extensive hacking of the build-system...
		myeconfargs=(
		--localstatedir="${EPREFIX}"/var
		--disable-static
		--disable-man-pages
		--disable-gtk-doc
		$(use_enable systemd libsystemd-login)
		$(use_enable introspection)
		--disable-examples
		--disable-nls
		$(usex ia64 --with-mozjs=mozjs185 --with-mozjs=mozjs-17.0)
		"$(systemd_with_unitdir)"
		--with-authfw=shadow
		--with-os-type=gentoo
		)
	fi	

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	default

	# Required for polkitd on hardened/PaX due to spidermonkey's JIT
	local f='src/polkitbackend/.libs/polkitd test/polkitbackend/.libs/polkitbackendjsauthoritytest'
	local m=''
	# Only used when USE="jit" is enabled for 'dev-lang/spidermonkey:17' wrt #485910
	has_version 'dev-lang/spidermonkey:17[jit]' && m='m'
	# ia64 uses spidermonkey-1.8.5 which requires different pax-mark flags
	use ia64 && m='mr'
	pax-mark ${m} ${f}
}

multilib_src_install() {
	emake DESTDIR="${D}" install
}

multilib_src_install_all() {
	dodoc docs/TODO HACKING NEWS README

	fowners -R polkitd:root /{etc,usr/share}/polkit-1/rules.d

	diropts -m0700 -o polkitd -g polkitd
	keepdir /var/lib/polkit-1

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins src/examples/{*.c,*.policy*}
	fi

	prune_libtool_files
}

pkg_postinst() {
	chown -R polkitd:root "${EROOT}"/{etc,usr/share}/polkit-1/rules.d
	chown -R polkitd:polkitd "${EROOT}"/var/lib/polkit-1
}
