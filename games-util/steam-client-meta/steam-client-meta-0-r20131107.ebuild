# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit pax-utils

# Please report bugs/suggestions on: https://github.com/anyc/steam-overlay
# or come to #gentoo-gamerlay in freenode IRC

DESCRIPTION="Meta package for Valve's native Steam client"
HOMEPAGE="http://steampowered.com"
SRC_URI=""
LICENSE="metapackage"

SLOT="0"
KEYWORDS=""
IUSE="flash +steamruntime trayicon video_cards_intel"

RDEPEND="
		media-fonts/font-mutt-misc
		|| ( media-fonts/font-bitstream-100dpi media-fonts/font-adobe-100dpi )

		trayicon? ( sys-apps/dbus )

		amd64? (
			|| (
				app-emulation/emul-linux-x86-opengl
				virtual/opengl[abi_x86_32]
				)
			flash? (
				|| (
					<www-plugins/adobe-flash-11.2.202.310-r1[32bit]
					>=www-plugins/adobe-flash-11.2.202.310-r1[abi_x86_32]
					)
				)
			)

		x86? (
			virtual/opengl
			video_cards_intel? ( >=media-libs/mesa-9 )
			flash? ( www-plugins/adobe-flash )
			)

		!steamruntime? (
			amd64? (
				>=sys-devel/gcc-4.6.0[multilib]
				>=sys-libs/glibc-2.15[multilib]
				
				>=app-emulation/steam-runtime-bin-20131109
				=sys-fs/steam-runtime-udev-175[abi_x86_32,gudev]

				|| ( >=zapp-emulation/emul-linux-x86-baselibs-20121202
					(
						dev-libs/glib:2[abi_x86_32]
						dev-libs/dbus-glib[abi_x86_32]
						dev-libs/libgcrypt[abi_x86_32]
						virtual/libusb[abi_x86_32]
						dev-libs/nspr[abi_x86_32]
						dev-libs/nss[abi_x86_32]
						media-libs/fontconfig[abi_x86_32]
						media-libs/freetype:2[abi_x86_32]
						media-libs/libpng:1.2[abi_x86_32]
						net-misc/networkmanager[abi_x86_32]
						net-print/cups[abi_x86_32]
						sys-apps/dbus[abi_x86_32]
						>=sys-libs/zlib-1.2.4[abi_x86_32]
					)
				)

				|| ( >=zapp-emulation/emul-linux-x86-gtklibs-20121202
					(
						x11-libs/cairo[abi_x86_32]
						x11-libs/gdk-pixbuf[abi_x86_32]
						x11-libs/gtk+:2[abi_x86_32]
					)
				)

				|| ( >=zapp-emulation/emul-linux-x86-sdl-20121202
						media-libs/libsdl2[abi_x86_32]
				)

				|| ( >=zapp-emulation/emul-linux-x86-soundlibs-20121202
					(
						media-libs/openal[abi_x86_32]
						media-sound/pulseaudio[abi_x86_32]
						media-libs/alsa-lib[abi_x86_32]
					)
				)

				|| (
					>=zapp-emulation/emul-linux-x86-xlibs-20121202
					(
						x11-libs/libSM[abi_x86_32]
						x11-libs/libICE[abi_x86_32]
						x11-libs/libX11[abi_x86_32]
						x11-libs/libXext[abi_x86_32]
						x11-libs/libXfixes[abi_x86_32]
						media-libs/fontconfig[abi_x86_32]
						media-libs/freetype[abi_x86_32]
						x11-libs/libXi[abi_x86_32]
						x11-libs/libXinerama[abi_x86_32]
						x11-libs/libXrandr[abi_x86_32]
						x11-libs/libXrender[abi_x86_32]
					)
				)

				trayicon? ( dev-libs/libappindicator2[abi_x86_32] )
				)
			x86? (
				dev-libs/glib:2
				dev-libs/dbus-glib
				dev-libs/libgcrypt
				virtual/libusb
				dev-libs/nspr
				dev-libs/nss
				media-libs/alsa-lib
				media-libs/fontconfig
				media-libs/freetype:2
				media-libs/libpng:1.2
				media-libs/openal
				media-sound/pulseaudio
				net-misc/networkmanager
				net-print/cups
				sys-apps/dbus
				=sys-fs/steam-runtime-udev-175[gudev]
				>=sys-devel/gcc-4.6.0
				>=sys-libs/glibc-2.15
				>=sys-libs/zlib-1.2.4
				x11-libs/cairo
				x11-libs/gdk-pixbuf
				x11-libs/gtk+:2
				x11-libs/libSM
				x11-libs/libICE
				>=x11-libs/libX11-1.5
				x11-libs/libXext
				x11-libs/libXfixes
				x11-libs/libXi
				x11-libs/libXinerama
				x11-libs/libXrandr
				x11-libs/libXrender
				x11-libs/pango

				trayicon? ( dev-libs/libappindicator2 )
				)
			)
		"

pkg_postinst() {
	elog "This is only a meta package that pulls in the required"
	elog "dependencies for the steam client."
	elog ""

	if use flash; then
		elog "In order to use flash, link the 32bit libflashplayer.so to"
		elog "\${STEAM_FOLDER}/ubuntu12_32/plugins/"
		elog ""
	fi

	if host-is-pax; then
		elog "If you're using PAX, please see:"
		elog "http://wiki.gentoo.org/wiki/Steam#Hardened_Gentoo"
		elog ""
	fi

	ewarn "The steam client and the games are not controlled by"
	ewarn "portage. Updates are handled by the client itself."
}
