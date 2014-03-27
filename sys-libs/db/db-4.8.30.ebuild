# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/db/db-4.8.30.ebuild,v 1.16 2013/09/23 19:21:24 ago Exp $

EAPI=5

inherit eutils db flag-o-matic java-pkg-opt-2 autotools multilib \
		multilib-minimal

#Number of official patches
#PATCHNO=`echo ${PV}|sed -e "s,\(.*_p\)\([0-9]*\),\2,"`
PATCHNO=${PV/*.*.*_p}
if [[ ${PATCHNO} == "${PV}" ]] ; then
	MY_PV=${PV}
	MY_P=${P}
	PATCHNO=0
else
	MY_PV=${PV/_p${PATCHNO}}
	MY_P=${PN}-${MY_PV}
fi

S="${WORKDIR}/${MY_P}/build_unix"
DESCRIPTION="Oracle Berkeley DB"
HOMEPAGE="http://www.oracle.com/technology/software/products/berkeley-db/index.html"
SRC_URI="http://download.oracle.com/berkeley-db/${MY_P}.tar.gz"
for (( i=1 ; i<=${PATCHNO} ; i++ )) ; do
	export SRC_URI="${SRC_URI} http://www.oracle.com/technology/products/berkeley-db/db/update/${MY_PV}/patch.${MY_PV}.${i}"
done

LICENSE="Sleepycat"
SLOT="4.8"
KEYWORDS="alpha amd64 arm hppa ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="doc java cxx tcl test"

# the entire testsuite needs the TCL functionality
DEPEND="tcl? ( >=dev-lang/tcl-8.4[${MULTILIB_USEDEP}] )
	test? ( >=dev-lang/tcl-8.4[${MULTILIB_USEDEP}] )
	java? ( >=virtual/jdk-1.5 )
	>=sys-devel/binutils-2.16.1"
RDEPEND="tcl? ( dev-lang/tcl )
	java? ( >=virtual/jre-1.5 )"



MULTILIB_WRAPPED_HEADERS=(
	/usr/include/db${SLOT}/dbstl_map.h
	/usr/include/db${SLOT}/db.h
	/usr/include/db${SLOT}/db.h
	/usr/include/db${SLOT}/dbstl_resource_manager.h
    /usr/include/db${SLOT}/dbstl_utility.h
    /usr/include/db${SLOT}/dbstl_base_iterator.h
)

src_unpack() {
	unpack "${MY_P}".tar.gz
}

src_prepare() {
	# Otherwise fails to properly link with libdl
	filter-ldflags -Wl,--as-needed

	# compilation with -O0 fails on amd64, see bug #171231
	if use amd64; then
		replace-flags -O0 -O2
		is-flagq -O[s123] || append-flags -O2
	fi

	cd "${WORKDIR}"/"${MY_P}"
	for (( i=1 ; i<=${PATCHNO} ; i++ ))
	do
		epatch "${DISTDIR}"/patch."${MY_PV}"."${i}"
	done
	epatch "${FILESDIR}"/${PN}-4.8-libtool.patch
	epatch "${FILESDIR}"/${PN}-4.8.24-java-manifest-location.patch
	epatch "${FILESDIR}"/${PN}-4.8.30-rename-atomic-compare-exchange.patch

	# use the includes from the prefix
	epatch "${FILESDIR}"/${PN}-4.6-jni-check-prefix-first.patch
	epatch "${FILESDIR}"/${PN}-4.3-listen-to-java-options.patch

	sed -e "/^DB_RELEASE_DATE=/s/%B %e, %Y/%Y-%m-%d/" -i dist/RELEASE

	# Include the SLOT for Java JAR files
	# This supersedes the unused jarlocation patches.
	sed -r -i \
		-e '/jarfile=.*\.jar$/s,(.jar$),-$(LIBVERSION)\1,g' \
		"${S}"/../dist/Makefile.in

	cd "${S}"/../dist
	rm -f aclocal/libtool.m4
	sed -i \
		-e '/AC_PROG_LIBTOOL$/aLT_OUTPUT' \
		configure.ac
	sed -i \
		-e '/^AC_PATH_TOOL/s/ sh, none/ bash, none/' \
		aclocal/programs.m4
	AT_M4DIR="aclocal aclocal_java" eautoreconf
	# Upstream sucks - they do autoconf and THEN replace the version variables.
	. ./RELEASE
	sed -i \
		-e "s/__EDIT_DB_VERSION_MAJOR__/$DB_VERSION_MAJOR/g" \
		-e "s/__EDIT_DB_VERSION_MINOR__/$DB_VERSION_MINOR/g" \
		-e "s/__EDIT_DB_VERSION_PATCH__/$DB_VERSION_PATCH/g" \
		-e "s/__EDIT_DB_VERSION_STRING__/$DB_VERSION_STRING/g" \
		-e "s/__EDIT_DB_VERSION_UNIQUE_NAME__/$DB_VERSION_UNIQUE_NAME/g" \
		-e "s/__EDIT_DB_VERSION__/$DB_VERSION/g" configure
}

multilib_src_configure() {
	local myconf=''

	# use `set` here since the java opts will contain whitespace
	set --
	if use java ; then
		set -- "$@" \
			--with-java-prefix="${JAVA_HOME}" \
			--with-javac-flags="$(java-pkg_javac-args)"
	fi

	# Add linker versions to the symbols. Easier to do, and safer than header file
	# mumbo jumbo.
	if use userland_GNU ; then
		append-ldflags -Wl,--default-symver
	fi

	# Bug #270851: test needs TCL support
	if use tcl || use test ; then
		myconf="${myconf} --enable-tcl"
		myconf="${myconf} --with-tcl=/usr/$(get_libdir)"
	else
		myconf="${myconf} --disable-tcl"
	fi

	cd "${BUILD_DIR}"
	ECONF_SOURCE="${S}"/../dist \
	STRIP="true" \
	econf \
		--enable-compat185 \
		--enable-o_direct \
		--without-uniquename \
		$(use arm && echo --with-mutex=ARM/gcc-assembly) \
		$(use amd64 && echo --with-mutex=x86/gcc-assembly) \
		$(use_enable cxx) \
		$(use_enable cxx stl) \
		$(use_enable java) \
		${myconf} \
		$(use_enable test) \
		"$@"
}

multilib_src_install() {
	default
	db_src_install_usrbinslot
	db_src_install_headerslot
	multilib_prepare_wrappers

	if use java && multilib_is_native_abi; then
		java-pkg_regso "${ED}"/usr/"$(get_libdir)"/libdb_java*.so
		java-pkg_dojar "${ED}"/usr/"$(get_libdir)"/*.jar
		rm -f "${ED}"/usr/"$(get_libdir)"/*.jar
	fi
}

multilib_src_install_all() {
	db_src_install_doc
	multilib_parallel_foreach_abi db_src_install_usrlibcleanup

	dodir /usr/sbin
	# This file is not always built, and no longer exists as of db-4.8
	[[ -f "${ED}"/usr/bin/berkeley_db_svc ]] && \
	mv "${ED}"/usr/bin/berkeley_db_svc "${ED}"/usr/sbin/berkeley_db"${SLOT/./}"_svc
}

pkg_postinst() {
	multilib_parallel_foreach_abi db_fix_so
}

pkg_postrm() {
	multilib_parallel_foreach_abi db_fix_so
}
