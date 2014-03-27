# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/acl/acl-2.2.52.ebuild,v 1.1 2013/05/20 17:55:21 vapier Exp $

EAPI="4"

inherit eutils toolchain-funcs multilib-minimal

DESCRIPTION="access control list utilities, libraries and headers"
HOMEPAGE="http://savannah.nongnu.org/projects/acl"
SRC_URI="http://download.savannah.gnu.org/releases/${PN}/${P}.src.tar.gz
	nfs? ( http://www.citi.umich.edu/projects/nfsv4/linux/acl-patches/2.2.42-2/acl-2.2.42-CITI_NFS4_ALL-2.dif )"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~ia64-linux ~x86-linux"
IUSE="nfs nls static-libs"

RDEPEND=">=sys-apps/attr-2.4[${MULTILIB_USEDEP}]
	nfs? ( net-libs/libnfsidmap[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

src_prepare() {
	if use nfs ; then
		cp "${DISTDIR}"/acl-2.2.42-CITI_NFS4_ALL-2.dif . || die
		sed -i \
			-e '/^diff --git a.debian.changelog b.debian.changelog/,/^diff --git/d' \
			acl-2.2.42-CITI_NFS4_ALL-2.dif || die
		epatch acl-2.2.42-CITI_NFS4_ALL-2.dif
	fi
	sed -i \
		-e "/^PKG_DOC_DIR/s:@pkg_name@:${PF}:" \
		-e '/HAVE_ZIPPED_MANPAGES/s:=.*:=false:' \
		include/builddefs.in \
		|| die
	strip-linguas po

	multilib_copy_sources
}

multilib_src_configure() {
	unset PLATFORM #184564
	export OPTIMIZER=${CFLAGS}
	export DEBUG=-DNDEBUG
	local myeconfargs=()

	myeconfargs+=(
		--enable-shared $(use_enable static-libs static)
		--libexecdir="${EPREFIX}"/usr/$(get_libdir)
		--bindir="${EPREFIX}"/bin
	)

	multilib_build_binaries && myeconfargs+=( $(use_enable nls gettext) )

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install() {
	emake DIST_ROOT="${D}" install install-dev install-lib || die
}

multilib_src_install_all() {
	use static-libs || find "${ED}" -name '*.la' -delete

	# move shared libs to /
	gen_usr_ldscript -a acl
}
