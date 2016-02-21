# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/rtmpdump/rtmpdump-2.4_p20131018.ebuild,v 1.2 2013/11/02 16:43:18 hwoarang Exp $

EAPI="4"

inherit multilib toolchain-funcs unpacker multilib-minimal

DESCRIPTION="Open source command-line RTMP client intended to stream audio or video flash content"
HOMEPAGE="http://rtmpdump.mplayerhq.hu/"
SRC_URI="http://dev.gentoo.org/~hwoarang/distfiles/${P}.tar.gz"

# the library is LGPL-2.1, the command is GPL-2
LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="gnutls polarssl ssl"

DEPEND="ssl? (
		gnutls? ( net-libs/gnutls[${MULTILIB_USEDEP}] )
		polarssl? ( !gnutls? ( >=net-libs/polarssl-0.14.0[${MULTILIB_USEDEP}] ) )
		!gnutls? ( !polarssl? ( dev-libs/openssl[${MULTILIB_USEDEP}] ) )
	)
	sys-libs/zlib"
RDEPEND="${DEPEND}"
S="${WORKDIR}/${P}"

pkg_setup() {
	if ! use ssl && ( use gnutls ||	use polarssl ) ; then
		ewarn "USE='gnutls polarssl' are ignored without USE='ssl'."
		ewarn "Please review the local USE flags for this package."
	fi
}

src_unpack() {
	# tarball unpacks to current dir
	mkdir -p "${S}"
	cd "${S}"
	unpacker "${A}"
}

rtmpdump_fixup_makefile() {
	# fix Makefile ( bug #298535 , bug #318353 and bug #324513 )
	sed -i 's/\$(MAKEFLAGS)//g' Makefile \
		|| die "failed to fix Makefile"
	sed -i -e 's:OPT=:&-fPIC :' \
		-e 's:OPT:OPTS:' \
		-e 's:CFLAGS=.*:& $(OPT):' librtmp/Makefile \
		|| die "failed to fix Makefile"
}

src_prepare() {
	multilib_copy_sources
	multilib_parallel_foreach_abi rtmpdump_fixup_makefile
}

multilib_src_compile() {
	if use ssl ; then
		if use gnutls ;	then
			crypto="GNUTLS"
		elif use polarssl ; then
			crypto="POLARSSL"
		else
			crypto="OPENSSL"
		fi
	fi
	#fix multilib-script support. Bug #327449
	sed -i "/^libdir/s:lib$:$(get_libdir)$:" librtmp/Makefile
	emake CC="$(tc-getCC)" LD="$(tc-getLD)" \
		OPT="${CFLAGS}" XLDFLAGS="${LDFLAGS}" CRYPTO="${crypto}" SYS=posix
}

multilib_src_install() {
	mkdir -p "${ED}"/${DESTTREE}/$(get_libdir)
	emake DESTDIR="${ED}" prefix="${DESTTREE}" mandir="${DESTTREE}/share/man" \
	CRYPTO="${crypto}" install
}

multilib_src_install_all() {
	dodoc README ChangeLog rtmpdump.1.html rtmpgw.8.html
}