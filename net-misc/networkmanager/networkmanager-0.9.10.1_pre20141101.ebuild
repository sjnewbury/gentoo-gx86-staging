# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/networkmanager/networkmanager-0.9.10.1_pre20141101.ebuild,v 1.1 2014/11/01 15:50:50 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME_ORG_MODULE="NetworkManager"
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit bash-completion-r1 eutils gnome2 linux-info multilib systemd user readme.gentoo toolchain-funcs vala versionator virtualx udev multilib-minimal

DESCRIPTION="Universal network configuration daemon for laptops, desktops, servers and virtualization hosts"
HOMEPAGE="https://wiki.gnome.org/Projects/NetworkManager"

SRC_URI="http://dev.gentoo.org/~pacho/gnome/${GNOME_ORG_MODULE}-${PV}.tar.xz"

LICENSE="GPL-2+"
SLOT="0" # add subslot if libnm-util.so.2 or libnm-glib.so.4 bumps soname version

IUSE="bluetooth connection-sharing consolekit +dhclient dhcpcd gnutls +introspection \
kernel_linux +nss +modemmanager ncurses +ppp resolvconf selinux systemd teamd test \
vala +wext +wifi zeroconf" # wimax

KEYWORDS="~amd64 ~arm ~x86"

REQUIRED_USE="
	modemmanager? ( ppp )
	^^ ( nss gnutls )
	^^ ( dhclient dhcpcd )
"

S="${WORKDIR}/${GNOME_ORG_MODULE}-0.9.10.1"

# gobject-introspection-0.10.3 is needed due to gnome bug 642300
# wpa_supplicant-0.7.3-r3 is needed due to bug 359271
# TODO: Qt support?
#
# iputils version needed due path changes (#523632). Upstream fixed
# it with a major refactor committed to 'master' for handling different
# paths for arping and other tools and, then, the version requirement
# will be able to be dropped on next major NM version
COMMON_DEPEND="
	>=sys-apps/dbus-1.2[${MULTILIB_USEDEP}]
	>=dev-libs/dbus-glib-0.100[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.32:2[${MULTILIB_USEDEP}]
	>=dev-libs/libnl-3.2.8:3=[${MULTILIB_USEDEP}]
	>=sys-auth/polkit-0.106
	net-libs/libndp[${MULTILIB_USEDEP}]
	>=net-libs/libsoup-2.26:2.4=[${MULTILIB_USEDEP}]
	>=net-misc/iputils-20121221-r1
	sys-libs/readline[${MULTILIB_USEDEP}]
	>=virtual/libgudev-165:=[${MULTILIB_USEDEP}]
	bluetooth? ( >=net-wireless/bluez-5 )
	connection-sharing? (
		net-dns/dnsmasq[dhcp]
		net-firewall/iptables )
	gnutls? (
		dev-libs/libgcrypt:0=[${MULTILIB_USEDEP}]
		net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	modemmanager? ( >=net-misc/modemmanager-0.7.991 )
	ncurses? ( >=dev-libs/newt-0.52.15[${MULTILIB_USEDEP}] )
	nss? ( >=dev-libs/nss-3.11:=[${MULTILIB_USEDEP}] )
	dhclient? ( =net-misc/dhcp-4*[client] )
	dhcpcd? ( >=net-misc/dhcpcd-4.0.0_rc3 )
	introspection? ( >=dev-libs/gobject-introspection-0.10.3 )
	ppp? ( >=net-dialup/ppp-2.4.5:=[ipv6] )
	resolvconf? ( net-dns/openresolv )
	systemd? ( >=sys-apps/systemd-183:0= )
	teamd? ( >=net-misc/libteam-1.9[${MULTILIB_USEDEP}] )
	zeroconf? ( net-dns/avahi:=[autoipd] )
	|| ( sys-power/upower sys-power/upower-pm-utils >=sys-apps/systemd-183 )
"
RDEPEND="${COMMON_DEPEND}
	consolekit? ( sys-auth/consolekit )
	wifi? ( >=net-wireless/wpa_supplicant-0.7.3-r3[dbus] )
"
DEPEND="${COMMON_DEPEND}
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	>=sys-devel/gettext-0.17
	>=sys-kernel/linux-headers-2.6.29
	virtual/pkgconfig
	vala? ( $(vala_depend) )
	test? (
		dev-lang/python:2.7
		dev-python/dbus-python[python_targets_python2_7]
		dev-python/pygobject:2[python_targets_python2_7] )
"

sysfs_deprecated_check() {
	ebegin "Checking for SYSFS_DEPRECATED support"

	if { linux_chkconfig_present SYSFS_DEPRECATED_V2; }; then
		eerror "Please disable SYSFS_DEPRECATED_V2 support in your kernel config and recompile your kernel"
		eerror "or NetworkManager will not work correctly."
		eerror "See http://bugs.gentoo.org/333639 for more info."
		die "CONFIG_SYSFS_DEPRECATED_V2 support detected!"
	fi
	eend $?
}

pkg_pretend() {
	if use kernel_linux; then
		get_version
		if linux_config_exists; then
			sysfs_deprecated_check
		else
			ewarn "Was unable to determine your kernel .config"
			ewarn "Please note that if CONFIG_SYSFS_DEPRECATED_V2 is set in your kernel .config, NetworkManager will not work correctly."
			ewarn "See http://bugs.gentoo.org/333639 for more info."
		fi

	fi
}

pkg_setup() {
	enewgroup plugdev
}

src_prepare() {
	DOC_CONTENTS="To modify system network connections without needing to enter the
		root password, add your user account to the 'plugdev' group."

	# Find arping at proper place, bug #523632
	epatch "${FILESDIR}/${PN}-0.9.10.0-arpingpath.patch"

	# Use python2.7 shebangs for test scripts, upstream bug #739448
	sed -e 's@\(^#!.*python\)@\12.7@' \
		-i */tests/*.py || die

	# Force use of /run, avoid eautoreconf, upstream bug #737139
	sed -e 's:$localstatedir/run/:/run/:' -i configure || die

	# Only build vala bindings for native ABI
	use vala && multilib_build_binaries && vala_src_prepare

	epatch_user # don't remove, users often want custom patches for NM

	gnome2_src_prepare
}

multilib_src_configure() {
	local myconf

	# Same hack as net-dialup/pptpd to get proper plugin dir for ppp, bug #519986
	if use ppp; then
		local PPPD_VER=`best_version net-dialup/ppp`
		PPPD_VER=${PPPD_VER#*/*-} #reduce it to ${PV}-${PR}
		PPPD_VER=${PPPD_VER%%[_-]*} # main version without beta/pre/patch/revision
		myconf="${myconf} --with-pppd-plugin-dir=/usr/$(get_libdir)/pppd/${PPPD_VER}"
	fi

	# unit files directory needs to be passed only when systemd is enabled,
	# otherwise systemd support is not disabled completely, bug #524534
	use systemd && myconf="${myconf} "$(systemd_with_unitdir)""

	# TODO: enable wimax when we have a libnl:3 compatible revision of it
	# wimax will be removed, bug #522822
	# ifnet plugin always disabled until someone volunteers to actively
	# maintain and fix it
	if ! multilib_is_native_abi; then
	myconf+="
		--disable-bluez5-dun
		--disable-ppp
		--without-dhclient
		--without-dhcpcd
		--without-modem-manager-1
		--without-nmtui
		--without-resolvconf
		--disable-teamdctl
		--disable-vala
	"
	else
	myconf+="
		$(use_enable bluetooth bluez5-dun)
		$(use_enable ppp)
		$(use_with dhclient)
		$(use_with dhcpcd)
		$(use_with modemmanager modem-manager-1)
		$(use_with ncurses nmtui)
		$(use_with resolvconf)
		$(use_enable teamd teamdctl)
		$(use_enable vala)
	"
	fi

	ECONF_SOURCE="${S}" gnome2_src_configure \
		--disable-more-warnings \
		--disable-static \
		--localstatedir=/var \
		--disable-ifnet \
		--without-netconfig \
		--with-dbus-sys-dir=/etc/dbus-1/system.d \
		--with-udev-dir="$(get_udevdir)" \
		--with-config-plugins-default=keyfile \
		--with-iptables=/sbin/iptables \
		--with-libsoup=yes \
		--enable-concheck \
		--with-crypto=$(usex nss nss gnutls) \
		--with-session-tracking=$(usex systemd systemd $(usex consolekit consolekit no)) \
		--with-suspend-resume=$(usex systemd systemd upower) \
		$(use_enable introspection) \
		--disable-wimax \
		$(use_with modemmanager modem-manager-1) \
		$(use_with selinux) \
		$(use_enable test tests) \
		--without-valgrind \
		$(use_with wext) \
		${myconf}
}

multilib_src_test() {
	Xemake check
}

multilib_src_install() {
	# Install completions at proper place, bug #465100
	gnome2_src_install completiondir="$(get_bashcompdir)"
}

multilib_src_install_all() {
	readme.gentoo_create_doc

	newinitd "${FILESDIR}/init.d.NetworkManager" NetworkManager
	newconfd "${FILESDIR}/conf.d.NetworkManager" NetworkManager

	# /var/run/NetworkManager is used by some distros, but not by Gentoo
	rmdir -v "${ED}/var/run/NetworkManager" || die "rmdir failed"

	# Need to keep the /etc/NetworkManager/dispatched.d for dispatcher scripts
	keepdir /etc/NetworkManager/dispatcher.d

	# Provide openrc net dependency only when nm is connected
	exeinto /etc/NetworkManager/dispatcher.d
	newexe "${FILESDIR}/10-openrc-status-r4" 10-openrc-status
	sed -e "s:@EPREFIX@:${EPREFIX}:g" \
		-i "${ED}/etc/NetworkManager/dispatcher.d/10-openrc-status" || die

	keepdir /etc/NetworkManager/system-connections
	chmod 0600 "${ED}"/etc/NetworkManager/system-connections/.keep* # bug #383765

	# Allow users in plugdev group to modify system connections
	insinto /usr/share/polkit-1/rules.d/
	doins "${FILESDIR}/01-org.freedesktop.NetworkManager.settings.modify.system.rules"
}

pkg_postinst() {
	gnome2_pkg_postinst
	readme.gentoo_print_elog

	if [[ -e "${EROOT}etc/NetworkManager/nm-system-settings.conf" ]]; then
		ewarn "The ${PN} system configuration file has moved to a new location."
		ewarn "You must migrate your settings from ${EROOT}/etc/NetworkManager/nm-system-settings.conf"
		ewarn "to ${EROOT}etc/NetworkManager/NetworkManager.conf"
		ewarn
		ewarn "After doing so, you can remove ${EROOT}etc/NetworkManager/nm-system-settings.conf"
	fi

	# The polkit rules file moved to /usr/share
	old_rules="${EROOT}etc/polkit-1/rules.d/01-org.freedesktop.NetworkManager.settings.modify.system.rules"
	if [[ -f "${old_rules}" ]]; then
		case "$(md5sum ${old_rules})" in
		  574d0cfa7e911b1f7792077003060240* )
			# Automatically delete the old rules.d file if the user did not change it
			elog
			elog "Removing old ${old_rules} ..."
			rm -f "${old_rules}" || eerror "Failed, please remove ${old_rules} manually"
			;;
		  * )
			elog "The ${old_rules}"
			elog "file moved to /usr/share/polkit-1/rules.d/ in >=networkmanager-0.9.4.0-r4"
			elog "If you edited ${old_rules}"
			elog "without changing its behavior, you may want to remove it."
			;;
		esac
	fi

	# ifnet plugin was disabled for systemd users with 0.9.8.6 version
	# and for all people with 0.9.10.0-r1 (see ChangeLog for full explanations)
	if use systemd; then
		if ! version_is_at_least 0.9.8.6 ${REPLACING_VERSIONS}; then
			ewarn "Ifnet plugin won't be used with systemd support enabled"
			ewarn "as it is meant to be used with openRC and can cause collisions"
			ewarn "(like bug #485658)."
			ewarn "Because of this, you will likely need to reconfigure some of"
			ewarn "your networks. To do this you can rely on Gnome control center,"
			ewarn "nm-connection-editor or nmtui tools for example."
		fi
	else
		if ! version_is_at_least 0.9.10.0-r1 ${REPLACING_VERSIONS}; then
			ewarn "Ifnet plugin is now disabled because of it being unattended"
			ewarn "and unmaintained for a long time, leading to some unfixed bugs"
			ewarn "and new problems appearing. We will now use upstream 'keyfile'"
			ewarn "plugin."
			ewarn "Because of this, you will likely need to reconfigure some of"
			ewarn "your networks. To do this you can rely on Gnome control center,"
			ewarn "nm-connection-editor or nmtui tools for example."
		fi
	fi

	# NM fallbacks to plugin specified at compile time (upstream bug #738611)
	# but still show a warning to remember people to have cleaner config file
	if [[ -e "${EROOT}etc/NetworkManager/NetworkManager.conf" ]]; then
		if grep plugins "${EROOT}etc/NetworkManager/NetworkManager.conf" | grep -q ifnet; then
			ewarn
			ewarn "You seem to use 'ifnet' plugin in ${EROOT}etc/NetworkManager/NetworkManager.conf"
			ewarn "Since it won't be used when running under Systemd, you will need to stop setting"
			ewarn "ifnet plugin there to allow NetworkManager to work."
			ewarn
		fi
	fi
}
