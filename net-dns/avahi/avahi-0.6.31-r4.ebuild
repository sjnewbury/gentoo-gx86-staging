# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:

EAPI="5"

PYTHON_COMPAT=( python{2_6,2_7} )
PYTHON_REQ_USE="gdbm"

WANT_AUTOMAKE=1.11

inherit autotools-multilib eutils mono python-r1 multilib flag-o-matic user systemd

DESCRIPTION="System which facilitates service discovery on a local network"
HOMEPAGE="http://avahi.org/"
SRC_URI="http://avahi.org/download/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-linux"
IUSE="autoipd bookmarks dbus doc gdbm gtk gtk3 howl-compat +introspection ipv6 kernel_linux mdnsresponder-compat mono nls python qt4 test utils"

REQUIRED_USE="
	utils? ( || ( gtk gtk3 ) )
	python? ( dbus gdbm )
	mono? ( dbus )
	howl-compat? ( dbus )
	mdnsresponder-compat? ( dbus )
"

COMMON_DEPEND="
	dev-libs/libdaemon[${MULTILIB_USEDEP}]
	dev-libs/expat[${MULTILIB_USEDEP}]
	dev-libs/glib:2[${MULTILIB_USEDEP}]
	gdbm? ( sys-libs/gdbm[${MULTILIB_USEDEP}] )
	qt4? ( dev-qt/qtcore:4 )
	gtk? ( x11-libs/gtk+:2 )
	gtk3? ( x11-libs/gtk+:3 )
	dbus? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	kernel_linux? ( sys-libs/libcap[${MULTILIB_USEDEP}] )
	introspection? ( dev-libs/gobject-introspection[${MULTILIB_USEDEP}] )
	mono? (
		dev-lang/mono[${MULTILIB_USEDEP}]
		gtk? ( dev-dotnet/gtk-sharp[${MULTILIB_USEDEP}] )
	)
	python? (
		gtk? ( dev-python/pygtk )
		dbus? ( dev-python/dbus-python )
	)
	bookmarks? (
		dev-python/twisted-core
		dev-python/twisted-web
	)
"

DEPEND="
	${COMMON_DEPEND}
	dev-util/intltool
	virtual/pkgconfig
	doc? (
		app-doc/doxygen
	)
"

RDEPEND="
	${COMMON_DEPEND}
	howl-compat? ( !net-misc/howl )
	mdnsresponder-compat? ( !net-misc/mDNSResponder )
"

pkg_preinst() {
	enewgroup netdev
	enewgroup avahi
	enewuser avahi -1 -1 -1 avahi

	if use autoipd; then
		enewgroup avahi-autoipd
		enewuser avahi-autoipd -1 -1 -1 avahi-autoipd
	fi
}

src_prepare() {
	if use ipv6; then
		sed -i \
			-e s/use-ipv6=no/use-ipv6=yes/ \
			avahi-daemon/avahi-daemon.conf || die
	fi

	sed -i\
		-e "s:\\.\\./\\.\\./\\.\\./doc/avahi-docs/html/:../../../doc/${PF}/html/:" \
		doxygen_to_devhelp.xsl || die

	# Make gtk utils optional
	epatch "${FILESDIR}"/${PN}-0.6.30-optional-gtk-utils.patch

	# Fix init scripts for >=openrc-0.9.0, bug #383641
	epatch "${FILESDIR}"/${PN}-0.6.x-openrc-0.9.x-init-scripts-fixes.patch

	# install-exec-local -> install-exec-hook
	epatch "${FILESDIR}"/${P}-install-exec-hook.patch

	# Backport host-name-from-machine-id patch, bug #466134
	epatch "${FILESDIR}"/${P}-host-name-from-machine-id.patch

	# Don't install avahi-discover unless ENABLE_GTK_UTILS, bug #359575
	epatch "${FILESDIR}"/${P}-fix-install-avahi-discover.patch

	epatch "${FILESDIR}"/${P}-so_reuseport-may-not-exist-in-running-kernel.patch

	# Drop DEPRECATED flags, bug #384743
	sed -i -e 's:-D[A-Z_]*DISABLE_DEPRECATED=1::g' avahi-ui/Makefile.am || die

	# Fix references to Lennart's home directory, bug #466210
	sed -i -e 's/\/home\/lennart\/tmp\/avahi//g' man/* || die

	# Prevent .pyc files in DESTDIR
	>py-compile

	eautoreconf

	# Needed only to copy precompiled man pages
	multilib_copy_sources

	use sh && replace-flags -O? -O0
}

src_configure() {
	local myeconfargs=(
		--disable-static
	)

	if use python; then
		python_export_best
		myeconfargs+=(
			$(use_enable dbus python-dbus)
			$(use_enable gtk pygtk)
		)
		
	fi

	if use mono; then
		myeconfargs+=(
			$(use_enable doc monodoc)
		)
	fi

	# We need to unset DISPLAY, else the configure script might have problems detecting the pygtk module
	unset DISPLAY

	myeconfargs+=(
		--localstatedir="${EPREFIX}/var"
		--with-distro=gentoo
		--disable-python-dbus
		--disable-pygtk
		--disable-xmltoman
		--disable-monodoc
		--enable-glib
		--enable-gobject
		$(use_enable test tests)
		$(use_enable autoipd)
		$(use_enable mdnsresponder-compat compat-libdns_sd)
		$(use_enable howl-compat compat-howl)
		$(use_enable doc doxygen-doc)
		$(use_enable mono)
		$(use_enable dbus)
		$(use_enable python)
		$(use_enable nls)
		$(use_enable introspection)
		--disable-qt3
		$(use_enable gdbm)
		$(systemd_with_unitdir)
		)
	if multilib_build_binaries; then
		myeconfargs+=(
			$(use_enable utils gtk-utils)
			$(use_enable gtk)
			$(use_enable gtk3)
			$(use_enable qt4)
		)
	fi
	autotools-multilib_src_configure
}

src_compile() {
	autotools-multilib_src_compile

	use doc && { emake avahi.devhelp || die ; }
}

_avahi_multilib_install() {
	use howl-compat && ln -s avahi-compat-howl.pc "${ED}"/usr/$(get_libdir)/pkgconfig/howl.pc
}

src_install() {
	autotools-multilib_src_install

	use bookmarks && use python && use dbus && use gtk || \
		rm -f "${ED}"/usr/bin/avahi-bookmarks

	multilib_parallel_foreach_abi _avahi_multilib_install
	use mdnsresponder-compat && ln -s avahi-compat-libdns_sd/dns_sd.h "${ED}"/usr/include/dns_sd.h

	if use autoipd; then
		# /lib is correct here (either a symlink to the default libdir or non-abi-specific)
		insinto /lib/rcscripts/net
		doins "${FILESDIR}"/autoipd.sh || die

		insinto /lib/rc/net
		newins "${FILESDIR}"/autoipd-openrc.sh autoipd.sh || die
	fi

	dodoc docs/{AUTHORS,NEWS,README,TODO} || die

	if use doc; then
		dohtml -r doxygen/html/. || die
		insinto /usr/share/devhelp/books/avahi
		doins avahi.devhelp || die
	fi

	find "${ED}" -name '*.la' -exec rm -f {} +
}

pkg_postinst() {
	if use autoipd; then
		elog
		elog "To use avahi-autoipd to configure your interfaces with IPv4LL (RFC3927)"
		elog "addresses, just set config_<interface>=( autoipd ) in /etc/conf.d/net!"
		elog
	fi
}
