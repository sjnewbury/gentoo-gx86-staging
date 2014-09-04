# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-208-r2.ebuild,v 1.8 2014/07/26 09:12:07 ssuominen Exp $

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual to select between different udev daemon providers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

DEPEND=""
RDEPEND="|| ( >=sys-fs/udev-208-r1[${MULTILIB_USEDEP}] >=sys-apps/systemd-208:0[${MULTILIB_USEDEP}] >=sys-fs/eudev-1.3[${MULTILIB_USEDEP}] )"
