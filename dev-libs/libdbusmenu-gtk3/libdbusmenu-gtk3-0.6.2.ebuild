# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

AYATANA_VALA_VERSION=0.20

inherit autotools flag-o-matic multilib-minimal

MY_PN=${PN/-gtk3}

DESCRIPTION="Library to pass menu structure across DBus"
HOMEPAGE="http://launchpad.net/dbusmenu"
SRC_URI="http://launchpad.net/${MY_PN/lib}/${PV%.*}/${PV}/+download/${MY_PN}-${PV}.tar.gz"

LICENSE="LGPL-2.1 LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug +introspection"

RDEPEND=">=dev-libs/glib-2.32
	>=dev-libs/dbus-glib-0.100
	dev-libs/libxml2
	>=x11-libs/gtk+-3.2:3
	introspection? ( >=dev-libs/gobject-introspection-1[${MULTILIB_USEDEP}] )
	~dev-libs/libdbusmenu-${PV}
	"
DEPEND="${RDEPEND}
	app-text/gnome-doc-utils
	dev-util/intltool
	virtual/pkgconfig
	introspection? ( dev-lang/vala:${AYATANA_VALA_VERSION}[vapigen] )"

S=${WORKDIR}/${MY_PN}-${PV}

ECONF_SOURCE=${S}

src_prepare() {
    # Hack to disable build core lib (link against system version)
    epatch "${FILESDIR}/${MY_PN}-gtk-no-glib.patch"
    eautoreconf
    default
}

multilib_src_configure() {
	append-flags -Wno-error #414323
	export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/usr/share/pkgconfig/

	use introspection && export VALA_API_GEN="$(type -P vapigen-${AYATANA_VALA_VERSION})"
	
	# dumper extra tool is only for GTK+-2.x, tests use valgrind which is stupid
	econf \
		--docdir=/usr/share/doc/${PF} \
		--disable-static \
		--disable-silent-rules \
		--disable-scrollkeeper \
		--enable-gtk \
		--disable-dumper \
		--disable-tests \
		$(use_enable introspection) \
		$(use_enable introspection vala) \
		$(use_enable debug massivedebugging) \
		--with-html-dir=/usr/share/doc/${PF}/html \
		--libdir=/usr/$(get_libdir)/${PN} \
		--includedir=/usr/include/${PN} \
		--with-gtk=3
}

multilib_src_test() { :; } #440192

multilib_src_install() {
	emake -j1 DESTDIR="${D}" install

	# move pkgconfig and girepository dirs into place
	mv ${ED}/usr/$(get_libdir)/${PN}/pkgconfig ${ED}/usr/$(get_libdir)
	mv ${ED}/usr/$(get_libdir)/${PN}/girepository-1.0 ${ED}/usr/$(get_libdir)
}

multilib_src_install_all() {
	dodoc AUTHORS ChangeLog README

	# Don't install core docs
	rm -rf ${ED}/usr/share/doc/${PF}/html/${MY_PN}-glib || die

	local a b
	for a in ${MY_PN}-gtk; do
		b=/usr/share/doc/${PF}/html/${a}
		[[ -d ${ED}/${b} ]] && dosym ${b} /usr/share/gtk-doc/html/${PF}/${a}
	done

	# avoid core collision
	rm ${ED}/usr/libexec/dbusmenu-bench

	prune_libtool_files
}
