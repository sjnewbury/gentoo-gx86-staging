# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/libsdl/libsdl-1.2.15-r4.ebuild,v 1.10 2013/09/26 17:28:03 ago Exp $

EAPI=5
inherit autotools flag-o-matic multilib toolchain-funcs eutils multilib-minimal

DESCRIPTION="Simple Direct Media Layer"
HOMEPAGE="http://www.libsdl.org/"
SRC_URI="http://www.libsdl.org/release/SDL-${PV}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd"
# WARNING:
# If you turn on the custom-cflags use flag in USE and something breaks,
# you pick up the pieces.  Be prepared for bug reports to be marked INVALID.
IUSE="oss alsa nas X dga xv xinerama fbcon directfb ggi svga tslib aalib opengl libcaca +sound +video +joystick custom-cflags pulseaudio ps3 static-libs"

RDEPEND="sound? ( >=media-libs/audiofile-0.1.9[${MULTILIB_USEDEP}] )
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	nas? (
		media-libs/nas[${MULTILIB_USEDEP}]
		x11-libs/libXt[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
	)
	X? (
		x11-libs/libXt[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
	)
	directfb? ( >=dev-libs/DirectFB-0.9.19[${MULTILIB_USEDEP}] )
	ggi? ( >=media-libs/libggi-2.0_beta3[${MULTILIB_USEDEP}] )
	svga? ( >=media-libs/svgalib-1.4.2[${MULTILIB_USEDEP}] )
	aalib? ( media-libs/aalib[${MULTILIB_USEDEP}] )
	libcaca? ( >=media-libs/libcaca-0.9-r1[${MULTILIB_USEDEP}] )
	opengl? ( virtual/opengl[${MULTILIB_USEDEP}] virtual/glu[${MULTILIB_USEDEP}] )
	ppc64? ( ps3? ( sys-libs/libspe2 ) )
	tslib? ( x11-libs/tslib[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	nas? (
		x11-base/xorg-proto
	)
	X? (
		x11-base/xorg-proto
	)
	x86? ( || ( >=dev-lang/yasm-0.6.0 >=dev-lang/nasm-0.98.39-r3 ) )"

# Unfortunately necessary
MULTILIB_WRAPPED_HEADERS=(
		/usr/include/SDL/SDL_endian.h
		/usr/include/SDL/SDL_syswm.h
		/usr/include/SDL/SDL_keysym.h
		/usr/include/SDL/SDL_config.h
		/usr/include/SDL/SDL_config.h
		/usr/include/SDL/SDL_getenv.h
		/usr/include/SDL/SDL_platform.h
		/usr/include/SDL/SDL_types.h
		/usr/include/SDL/SDL_byteorder.h
		/usr/include/SDL/SDL_stdinc.h
		/usr/include/SDL/begin_code.h
		/usr/include/SDL/close_code.h
		/usr/include/SDL/SDL_error.h
		/usr/include/SDL/SDL_version.h
)        

S=${WORKDIR}/SDL-${PV}
ECONF_SOURCE=${S}

pkg_setup() {
	if use custom-cflags ; then
		ewarn "Since you've chosen to use possibly unsafe CFLAGS,"
		ewarn "don't bother filing libsdl-related bugs until trying to remerge"
		ewarn "libsdl without the custom-cflags use flag in USE."
	fi
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${P}-sdl-config.patch \
		"${FILESDIR}"/${P}-resizing.patch \
		"${FILESDIR}"/${P}-joystick.patch \
		"${FILESDIR}"/${P}-gamma.patch \
		"${FILESDIR}"/${P}-const-xdata32.patch
	AT_M4DIR="/usr/share/aclocal acinclude" eautoreconf
}

multilib_src_configure() {
	local myconf=
	if [[ $(tc-arch) != "x86" ]] ; then
		myconf="${myconf} --disable-nasm"
	else
		myconf="${myconf} --enable-nasm"
	fi
	use custom-cflags || strip-flags
	use sound || myconf="${myconf} --disable-audio"
	use video \
		&& myconf="${myconf} --enable-video-dummy" \
		|| myconf="${myconf} --disable-video"
	use joystick || myconf="${myconf} --disable-joystick"

	local directfbconf="--disable-video-directfb"
	if use directfb ; then
		# since DirectFB can link against SDL and trigger a
		# dependency loop, only link against DirectFB if it
		# isn't broken #61592
		echo 'int main(){}' > directfb-test.c
		$(tc-getCC) directfb-test.c -ldirectfb 2>/dev/null \
			&& directfbconf="--enable-video-directfb" \
			|| ewarn "Disabling DirectFB since libdirectfb.so is broken"
	fi

	myconf="${myconf} ${directfbconf}"

#	Would be nice to avoid wrapping headers, but some programs assume location
#		--includedir="/usr/$(get_libdir)/${PN}/include" \

	econf \
		--disable-rpath \
		--disable-arts \
		--disable-esd \
		--enable-events \
		--enable-cdrom \
		--enable-threads \
		--enable-timers \
		--enable-file \
		--enable-cpuinfo \
		--disable-alsa-shared \
		--disable-esd-shared \
		--disable-pulseaudio-shared \
		--disable-arts-shared \
		--disable-nas-shared \
		--disable-osmesa-shared \
		$(use_enable oss) \
		$(use_enable alsa) \
		$(use_enable pulseaudio) \
		$(use_enable nas) \
		$(use_enable X video-x11) \
		$(use_enable dga) \
		$(use_enable xv video-x11-xv) \
		$(use_enable xinerama video-x11-xinerama) \
		$(use_enable X video-x11-xrandr) \
		$(use_enable dga video-dga) \
		$(use_enable fbcon video-fbcon) \
		$(use_enable ggi video-ggi) \
		$(use_enable svga video-svga) \
		$(use_enable aalib video-aalib) \
		$(use_enable libcaca video-caca) \
		$(use_enable opengl video-opengl) \
		$(use_enable ps3 video-ps3) \
		$(use_enable tslib input-tslib) \
		$(use_with X x) \
		$(use_enable static-libs static) \
		--disable-video-x11-xme \
		${myconf}
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	multilib_prepare_wrappers

	if ! multilib_is_native_abi ; then
		mv "${ED}"/usr/bin/sdl-config "${ED}"/usr/bin/sdl-config.${ABI}
	fi
}

multilib_src_install_all() {
	use static-libs || prune_libtool_files --all
	dodoc BUGS CREDITS README README-SDL.txt README.HG TODO WhatsNew
	dohtml -r ./
}
