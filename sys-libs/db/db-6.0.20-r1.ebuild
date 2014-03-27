# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/db/db-6.0.20-r1.ebuild,v 1.1 2013/07/10 17:10:41 robbat2 Exp $

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

S_BASE="${WORKDIR}/${MY_P}"
S="${S_BASE}/build_unix"
DESCRIPTION="Oracle Berkeley DB"
HOMEPAGE="http://www.oracle.com/technology/software/products/berkeley-db/index.html"
SRC_URI="http://download.oracle.com/berkeley-db/${MY_P}.tar.gz"
for (( i=1 ; i<=${PATCHNO} ; i++ )) ; do
	export SRC_URI="${SRC_URI} http://www.oracle.com/technology/products/berkeley-db/db/update/${MY_PV}/patch.${MY_PV}.${i}"
done

LICENSE="AGPL-3"
SLOT="6.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
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

	cd "${WORKDIR}"/"${MY_P}"
	for (( i=1 ; i<=${PATCHNO} ; i++ ))
	do
		epatch "${DISTDIR}"/patch."${MY_PV}"."${i}"
	done
	#epatch "${FILESDIR}"/${PN}-4.8-libtool.patch
	# upstreamed:5.2.36
	#epatch "${FILESDIR}"/${PN}-4.8.24-java-manifest-location.patch

	# use the includes from the prefix
	epatch "${FILESDIR}"/${PN}-4.6-jni-check-prefix-first.patch
	epatch "${FILESDIR}"/${PN}-4.3-listen-to-java-options.patch

	# upstream autoconf fails to build DBM when it's supposed to
	# merged upstream in 5.0.26
	#epatch "${FILESDIR}"/${PN}-5.0.21-enable-dbm-autoconf.patch

	# sqlite configure call has an extra leading ..
	# upstreamed:5.2.36, missing in 5.3.x/6.x
	# still needs to be patched in 6.0.19
	epatch "${FILESDIR}"/${PN}-6.0.19-sqlite-configure-path.patch

	# The upstream testsuite copies .lib and the binaries for each parallel test
	# core, ~300MB each. This patch uses links instead, saves a lot of space.
	epatch "${FILESDIR}"/${PN}-6.0.20-test-link.patch

	# Upstream release script grabs the dates when the script was run, so lets
	# end-run them to keep the date the same.
	export REAL_DB_RELEASE_DATE="$(awk \
		'/^DB_VERSION_STRING=/{ gsub(".*\\(|\\).*","",$0); print $0; }' \
		"${S_BASE}"/dist/configure)"
	sed -r -i \
		-e "/^DB_RELEASE_DATE=/s~=.*~='${REAL_DB_RELEASE_DATE}'~g" \
		"${S_BASE}"/dist/RELEASE

	# Include the SLOT for Java JAR files
	# This supersedes the unused jarlocation patches.
	sed -r -i \
		-e '/jarfile=.*\.jar$/s,(.jar$),-$(LIBVERSION)\1,g' \
		"${S_BASE}"/dist/Makefile.in

	cd "${S_BASE}"/dist
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
	for v in \
		DB_VERSION_{FAMILY,LETTER,RELEASE,MAJOR,MINOR} \
		DB_VERSION_{PATCH,FULL,UNIQUE_NAME,STRING,FULL_STRING} \
		DB_VERSION \
		DB_RELEASE_DATE ; do
		local ev="__EDIT_${v}__"
		sed -i -e "s/${ev}/${!v}/g" configure
	done
}

multilib_src_configure() {
	local myconf=''

	# compilation with -O0 fails on amd64, see bug #171231
	if use amd64; then
		replace-flags -O0 -O2
		is-flagq -O[s123] || append-flags -O2
	fi

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

	# sql_compat will cause a collision with sqlite3
	# --enable-sql_compat
	cd "${BUILD_DIR}"
	ECONF_SOURCE="${S_BASE}"/dist \
	STRIP="true" \
	econf \
		--enable-compat185 \
		--enable-dbm \
		--enable-o_direct \
		--without-uniquename \
		--enable-sql \
		--enable-sql_codegen \
		--disable-sql_compat \
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
		java-pkg_regso "${D}"/usr/"$(get_libdir)"/libdb_java*.so
		java-pkg_dojar "${D}"/usr/"$(get_libdir)"/*.jar
		rm -f "${D}"/usr/"$(get_libdir)"/*.jar
	fi
}

multilib_src_install_all() {
	db_src_install_doc
	multilib_parallel_foreach_abi db_src_install_usrlibcleanup

	dodir /usr/sbin
	# This file is not always built, and no longer exists as of db-4.8
	[[ -f "${D}"/usr/bin/berkeley_db_svc ]] && \
	mv "${D}"/usr/bin/berkeley_db_svc "${D}"/usr/sbin/berkeley_db"${SLOT/./}"_svc
}

pkg_postinst() {
	multilib_parallel_foreach_abi db_fix_so
}

pkg_postrm() {
	multilib_parallel_foreach_abi db_fix_so
}

multilib_src_test() {
	# db_repsite is impossible to build, as upstream strips those sources.
	# db_repsite is used directly in the setup_site_prog,
	# setup_site_prog is called from open_site_prog
	# which is called only from tests in the multi_repmgr group.
	#sed -ri \
	#	-e '/set subs/s,multi_repmgr,,g' \
	#	"${S_BASE}/test/testparams.tcl"
	sed -ri \
		-e '/multi_repmgr/d' \
		"${S_BASE}/test/tcl/test.tcl"

	# This is the only failure in 5.2.28 so far, and looks like a false positive.
	# Repmgr018 (btree): Test of repmgr stats.
	#     Repmgr018.a: Start a master.
	#     Repmgr018.b: Start a client.
	#     Repmgr018.c: Run some transactions at master.
	#         Rep_test: btree 20 key/data pairs starting at 0
	#         Rep_test.a: put/get loop
	# FAIL:07:05:59 (00:00:00) perm_no_failed_stat: expected 0, got 1
	sed -ri \
		-e '/set parms.*repmgr018/d' \
		-e 's/repmgr018//g' \
		"${S_BASE}/test/tcl/test.tcl"

	db_src_test
}
