# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/util-linux/util-linux-2.24.ebuild,v 1.3 2013/11/09 09:10:56 polynomial-c Exp $

EAPI=5

PYTHON_COMPAT=( python2_7 python3_{2,3} )

inherit eutils toolchain-funcs libtool flag-o-matic bash-completion-r1 \
		python-single-r1 multilib-minimal

MY_PV=${PV/_/-}
MY_P=${PN}-${MY_PV}

if [[ ${PV} == 9999 ]] ; then
	inherit git-2 autotools
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
else
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~x86-linux"
	SRC_URI="mirror://kernel/linux/utils/util-linux/v${PV:0:4}/${MY_P}.tar.xz"
fi

DESCRIPTION="Various useful Linux utilities"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/util-linux/"

LICENSE="GPL-2 GPL-3 LGPL-2.1 BSD-4 MIT public-domain"
SLOT="0"
IUSE="bash-completion caps +cramfs cytune fdformat ncurses nls pam python selinux slang static-libs +suid test tty-helpers udev unicode"

RDEPEND="!sys-process/schedutils
	!sys-apps/setarch
	!<sys-apps/sysvinit-2.88-r5
	!sys-block/eject
	!<sys-libs/e2fsprogs-libs-1.41.8
	!<sys-fs/e2fsprogs-1.41.8
	!<app-shells/bash-completion-1.3-r2
	caps? ( sys-libs/libcap-ng )
	cramfs? ( sys-libs/zlib )
	ncurses? ( >=sys-libs/ncurses-5.2-r2 )
	pam? ( sys-libs/pam )
	python? ( ${PYTHON_DEPS} )
	selinux? ( sys-libs/libselinux[${MULTILIB_USEDEP}] )
	slang? ( sys-libs/slang )
	udev? ( virtual/udev )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	test? ( sys-devel/bc )
	virtual/os-headers"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	if [[ ${PV} == 9999 ]] ; then
		po/update-potfiles
		eautoreconf
	fi
	elibtoolize
}

lfs_fallocate_test() {
	# Make sure we can use fallocate with LFS #300307
	cat <<-EOF > "${T}"/fallocate.c
		#define _GNU_SOURCE
		#include <fcntl.h>
		main() { return fallocate(0, 0, 0, 0); }
	EOF
	append-lfs-flags
	$(tc-getCC) ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} "${T}"/fallocate.c -o /dev/null >/dev/null 2>&1 \
		|| export ac_cv_func_fallocate=no
	rm -f "${T}"/fallocate.c
}

multilib_src_configure() {
	lfs_fallocate_test
	export ac_cv_header_security_pam_misc_h=$(usex pam) #485486

	local myeconfargs=()
	# Common config opts for all ABIs (selinux affects built libs)
		myeconfargs+=(
			--enable-fs-paths-extra=/usr/sbin:/bin:/usr/bin
			$(use_with selinux)
			$(use_enable static-libs static)
			--disable-kill
			--disable-last
			--disable-login
			--disable-nologin
			--disable-reset
			--disable-su
		)
	if multilib_is_native_abi ; then
		myeconfargs+=(
			--with-bashcompletiondir="$(get_bashcompdir)"
			$(use_enable nls)
			$(use_enable bash-completion)
			$(use_enable caps setpriv)
			$(use_enable cramfs)
			$(use_enable cytune)
			$(use_enable fdformat)
			--with-ncurses=$(usex ncurses $(usex unicode auto yes) no)
			$(use_enable tty-helpers mesg)
			$(use_with python)
			$(use_enable tty-helpers wall)
			$(use_enable tty-helpers write)
			$(use_enable suid makeinstall-chown)
			$(use_enable suid makeinstall-setuid)
			$(use_with slang)
			$(use_with udev)
			$(tc-has-tls || echo --disable-tls)
			--enable-agetty
			--enable-partx
			--enable-raw
			--enable-rename
			--enable-schedutils
		)
	else
		# We just want to build libs, so disable as much as possible
		myeconfargs+=(
			--disable-nls
			--disable-bash-completion
			--disable-agetty
			--disable-bfs
			--disable-chfn-chsh
			--disable-cramfs
			--disable-cytune
			--disable-eject
			--disable-fallocate
			--disable-fdformat
			--disable-fsck
			--disable-hwclock
			--disable-kill
			--disable-last
			--disable-line
			--disable-login
			--disable-losetup
			--disable-mesg
			--disable-more
			--disable-mount
			--disable-mountpoint
			--disable-newgrp
			--disable-nologin
			--disable-nsenter
			--disable-partx
			--disable-pg
			--disable-pivot_root
			--disable-raw
			--disable-rename
			--disable-reset
			--disable-runuser
			--disable-schedutils
			--disable-setpriv
			--disable-setterm
			--disable-su
			--disable-sulogin
			--disable-switch_root
			--disable-tls
			--disable-tunelp
			--disable-ul
			--disable-unshare
			--disable-utmpdump
			--disable-uuidd
			--disable-vipw
			--disable-wall
			--disable-wdctl
			--disable-write
			--without-ncurses
			--without-python
			--without-slang
			--without-udev
		)
	fi
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install_all() {
	dodoc AUTHORS NEWS README* Documentation/{TODO,*.txt,releases/*}

	use python && python_optimize

	# need the libs in /
	gen_usr_ldscript -a blkid mount uuid

	# e2fsprogs-libs didnt install .la files, and .pc work fine
	prune_libtool_files
}

pkg_postinst() {
	if ! use tty-helpers; then
		elog "The mesg/wall/write tools have been disabled due to USE=-tty-helpers."
	fi

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "The agetty util now clears the terminal by default. You"
		elog "might want to add --noclear to your /etc/inittab lines."
	fi
}
