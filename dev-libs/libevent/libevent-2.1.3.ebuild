# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libevent/libevent-2.1.3.ebuild,v 1.3 2014/01/18 04:51:21 vapier Exp $

EAPI=5
inherit eutils libtool multilib-minimal

MY_P="${P}-alpha"

DESCRIPTION="A library to execute a function when a specific event occurs on a file descriptor"
HOMEPAGE="http://libevent.org/"
SRC_URI="mirror://sourceforge/levent/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+ssl static-libs test"

DEPEND="ssl? ( dev-libs/openssl[${MULTILIB_USEDEP}] )"
RDEPEND="
	${DEPEND}
	!<=dev-libs/9libs-1.0
"

S=${WORKDIR}/${MY_P}
ECONF_SOURCE="${S}"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/event2/dns_compat.h
	/usr/include/event2/event-config.h
	/usr/include/evutil.h
	/usr/include/evrpc.h
	/usr/include/evdns.h
)

src_prepare() {
	elibtoolize

	# don't waste time building tests/samples
	sed -i \
		-e 's|^\(SUBDIRS =.*\)sample test\(.*\)$|\1\2|' \
		Makefile.in || die "sed Makefile.in failed"
}

multilib_src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable ssl openssl)
	# Build assumes in source build for test subdir
	mkdir test || die
}

multilib_src_test() {
	# The test suite doesn't quite work (see bug #406801 for the latest
	# installment in a riveting series of reports).
	:
	# emake -C test check | tee "${T}"/tests
}

DOCS="README ChangeLog*"

multilib_src_install_all() {
	prune_libtool_files
}
