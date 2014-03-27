# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/heimdal/heimdal-1.5.3-r1.ebuild,v 1.3 2013/10/11 14:28:36 eras Exp $

EAPI=5
PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} )
VIRTUALX_REQUIRED="manual"

inherit autotools db-use eutils multilib python-any-r1 toolchain-funcs \
		virtualx flag-o-matic multilib-minimal

MY_P="${P}"
DESCRIPTION="Kerberos 5 implementation from KTH"
HOMEPAGE="http://www.h5l.org/"
SRC_URI="http://www.h5l.org/dist/src/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd"
IUSE="afs +berkdb caps hdb-ldap ipv6 otp +pkinit ssl static-libs threads test X"

RDEPEND="ssl? ( dev-libs/openssl[${MULTILIB_USEDEP}] )
	berkdb? ( sys-libs/db[${MULTILIB_USEDEP}] )
	!berkdb? ( sys-libs/gdbm[${MULTILIB_USEDEP}] )
	caps? ( sys-libs/libcap-ng[${MULTILIB_USEDEP}] )
	>=dev-db/sqlite-3.5.7[${MULTILIB_USEDEP}]
	>=sys-libs/e2fsprogs-libs-1.41.11[${MULTILIB_USEDEP}]
	sys-libs/ncurses[${MULTILIB_USEDEP}]
	sys-libs/readline[${MULTILIB_USEDEP}]
	afs? ( net-fs/openafs[${MULTILIB_USEDEP}] )
	hdb-ldap? ( >=net-nds/openldap-2.3.0[${MULTILIB_USEDEP}] )
	X? ( x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXau[${MULTILIB_USEDEP}]
		x11-libs/libXt[${MULTILIB_USEDEP}] )
	!!app-crypt/mit-krb5
	!!app-crypt/mit-krb5-appl"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	virtual/pkgconfig
	>=sys-devel/autoconf-2.62
	test? ( X? ( ${VIRTUALX_DEPEND} ) )"

src_prepare() {
	epatch "${FILESDIR}/heimdal_missing-include.patch"
	epatch "${FILESDIR}/heimdal_db6.patch"
	epatch "${FILESDIR}/heimdal_disable-check-iprop.patch"
	epatch "${FILESDIR}/heimdal_link_order.patch"
	epatch "${FILESDIR}/heimdal_missing_symbols.patch"
	epatch "${FILESDIR}/heimdal_texinfo-5.patch"
	eautoreconf
}

multilib_src_configure() {
	# QA
	append-flags -fno-strict-aliasing

	local myconf=""
	if use berkdb; then
		myconf="--with-berkeley-db --with-berkeley-db-include=$(db_includedir)"
	else
		myconf="--without-berkeley-db"
	fi
	econf \
		--enable-kcm \
		--disable-osfc2 \
		--enable-shared \
		--with-libintl=/usr \
		--with-readline=/usr \
		--with-sqlite3=/usr \
		--libexecdir=/usr/sbin \
		$(use_enable afs afs-support) \
		$(use_enable otp) \
		$(use_enable pkinit kx509) \
		$(use_enable pkinit pk-init) \
		$(use_enable static-libs static) \
		$(use_enable threads pthread-support) \
		$(use_with caps capng) \
		$(use_with hdb-ldap openldap /usr) \
		$(use_with ipv6) \
		$(use_with ssl openssl /usr) \
		$(use_with X x) \
		${myconf}
}

multilib_src_compile() {
	emake -j1
}

multilib_src_install() {
	INSTALL_CATPAGES="no" emake DESTDIR="${D}" install
}

multilib_src_install_all() {
	dodoc ChangeLog README NEWS TODO

	# Begin client rename and install
	for i in {telnetd,ftpd,rshd,popper}
	do
		mv "${D}"/usr/share/man/man8/{,k}${i}.8
		mv "${D}"/usr/sbin/{,k}${i}
	done

	for i in {rcp,rsh,telnet,ftp,su,login,pagsh,kf}
	do
		mv "${D}"/usr/share/man/man1/{,k}${i}.1
		mv "${D}"/usr/bin/{,k}${i}
	done

	mv "${D}"/usr/share/man/man5/{,k}ftpusers.5
	mv "${D}"/usr/share/man/man5/{,k}login.access.5

	newinitd "${FILESDIR}"/heimdal-kdc.initd-r2 heimdal-kdc
	newinitd "${FILESDIR}"/heimdal-kadmind.initd-r2 heimdal-kadmind
	newinitd "${FILESDIR}"/heimdal-kpasswdd.initd-r2 heimdal-kpasswdd
	newinitd "${FILESDIR}"/heimdal-kcm.initd-r1 heimdal-kcm

	newconfd "${FILESDIR}"/heimdal-kdc.confd heimdal-kdc
	newconfd "${FILESDIR}"/heimdal-kadmind.confd heimdal-kadmind
	newconfd "${FILESDIR}"/heimdal-kpasswdd.confd heimdal-kpasswdd
	newconfd "${FILESDIR}"/heimdal-kcm.confd heimdal-kcm

	insinto /etc
	newins "${FILESDIR}"/krb5.conf krb5.conf.example

	if use hdb-ldap; then
		insinto /etc/openldap/schema
		doins "${S}/lib/hdb/hdb.schema"
	fi

	use static-libs || find "${D}"/usr/lib* -name '*.la' -delete

	# default database dir
	keepdir /var/heimdal

	# Ugly hack for broken symlink - bug #417081
	rm "${D}"/usr/share/man/man5/qop.5 || die
	dosym mech.5 /usr/share/man/man5/qop.5
}
