# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
PYTHON_COMPAT=( python2_7 )
inherit multiprocessing pax-utils python-any-r1 qt5-build-multilib

DESCRIPTION="Library for rendering dynamic web content in Qt5 C++ and QML applications"

if [[ ${QT5_BUILD_TYPE} == release ]]; then
	KEYWORDS="amd64 ~arm ~arm64 x86"
fi

IUSE="alsa bindist designer examples geolocation pax_kernel pulseaudio +system-ffmpeg +system-icu widgets"
REQUIRED_USE="designer? ( widgets ) examples? ( widgets )"

RDEPEND="
	app-arch/snappy:=[${MULTILIB_USEDEP}]
	dev-libs/glib:2[${MULTILIB_USEDEP}]
	dev-libs/nspr[${MULTILIB_USEDEP}]
	dev-libs/nss[${MULTILIB_USEDEP}]
	~dev-qt/qtcore-${PV}[${MULTILIB_USEDEP}]
	~dev-qt/qtdeclarative-${PV}[${MULTILIB_USEDEP}]
	~dev-qt/qtgui-${PV}[${MULTILIB_USEDEP}]
	~dev-qt/qtnetwork-${PV}[${MULTILIB_USEDEP}]
	~dev-qt/qtprintsupport-${PV}[${MULTILIB_USEDEP}]
	~dev-qt/qtwebchannel-${PV}[qml,${MULTILIB_USEDEP}]
	dev-libs/expat[${MULTILIB_USEDEP}]
	dev-libs/libevent:=[${MULTILIB_USEDEP}]
	dev-libs/libxml2[icu,${MULTILIB_USEDEP}]
	dev-libs/libxslt[${MULTILIB_USEDEP}]
	dev-libs/re2:=[${MULTILIB_USEDEP}]
	media-libs/fontconfig[${MULTILIB_USEDEP}]
	media-libs/freetype[${MULTILIB_USEDEP}]
	media-libs/harfbuzz:=[${MULTILIB_USEDEP}]
	media-libs/libjpeg-turbo:=[${MULTILIB_USEDEP}]
	media-libs/libpng:0=[${MULTILIB_USEDEP}]
	>=media-libs/libvpx-1.5:=[svc,${MULTILIB_USEDEP}]
	media-libs/libwebp:=[${MULTILIB_USEDEP}]
	media-libs/mesa[egl,${MULTILIB_USEDEP}]
	media-libs/opus[${MULTILIB_USEDEP}]
	sys-apps/dbus[${MULTILIB_USEDEP}]
	sys-apps/pciutils[${MULTILIB_USEDEP}]
	sys-libs/libcap[${MULTILIB_USEDEP}]
	sys-libs/zlib[minizip,${MULTILIB_USEDEP}]
	virtual/libudev[${MULTILIB_USEDEP}]
	x11-libs/libdrm[${MULTILIB_USEDEP}]
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXcomposite[${MULTILIB_USEDEP}]
	x11-libs/libXcursor[${MULTILIB_USEDEP}]
	x11-libs/libXdamage[${MULTILIB_USEDEP}]
	x11-libs/libXext[${MULTILIB_USEDEP}]
	x11-libs/libXfixes[${MULTILIB_USEDEP}]
	x11-libs/libXi[${MULTILIB_USEDEP}]
	x11-libs/libXrandr[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	x11-libs/libXScrnSaver[${MULTILIB_USEDEP}]
	x11-libs/libXtst[${MULTILIB_USEDEP}]
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	designer? ( ~dev-qt/designer-${PV}[${MULTILIB_USEDEP}] )
	geolocation? ( ~dev-qt/qtpositioning-${PV}[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio:=[${MULTILIB_USEDEP}] )
	system-ffmpeg? ( media-video/ffmpeg:0=[${MULTILIB_USEDEP}] )
	system-icu? ( >=dev-libs/icu-60.2:=[${MULTILIB_USEDEP}] )
	widgets? (
		~dev-qt/qtdeclarative-${PV}[widgets,${MULTILIB_USEDEP}]
		~dev-qt/qtwidgets-${PV}[${MULTILIB_USEDEP}]
	)
	examples? (
		~dev-qt/qtquickcontrols2-${PV}[${MULTILIB_USEDEP}]
	)
"
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	>=app-arch/gzip-1.7
	dev-util/gperf
	dev-util/ninja
	dev-util/re2c
	sys-devel/bison
	pax_kernel? ( sys-apps/elfix )
"

PATCHES+=(
	"${FILESDIR}/${PN}-5.9.6-gcc8.patch" # bug 657124
	"${FILESDIR}/${P}-libxml2-disable-catalogs.patch" # bug 653078
	"${FILESDIR}/${P}-ffmpeg4.patch"
	"${FILESDIR}/${P}-eglGetProcAddress-fallback-lookup.patch" # 5.11 branch
	"${FILESDIR}/${P}-nouveau-disable-gpu.patch" # bug 609752
)

pkg_setup() {
	use examples && QT5_EXAMPLES_SUBDIRS=("examples")
}

src_prepare() {
	use pax_kernel && PATCHES+=( "${FILESDIR}/${PN}-5.9.3-paxmark-mksnapshot.patch" )

	# bug 620444 - ensure local headers are used
	find "${S}" -type f -name "*.pr[fio]" | xargs sed -i -e 's|INCLUDEPATH += |&$$QTWEBENGINE_ROOT/include |' || die

	qt_use_disable_config alsa webengine-alsa src/core/config/linux.pri
	qt_use_disable_config pulseaudio webengine-pulseaudio src/core/config/linux.pri

	qt_use_disable_mod designer webenginewidgets src/plugins/plugins.pro

	qt_use_disable_mod geolocation positioning \
		mkspecs/features/configure.prf \
		src/core/core_chromium.pri \
		src/core/core_common.pri

	qt_use_disable_mod widgets widgets src/src.pro

	qt5-build_src_prepare
}

multilib_src_configure() {
	export NINJA_PATH=/usr/bin/ninja
	export NINJAFLAGS="${NINJAFLAGS:--j$(makeopts_jobs) -l$(makeopts_loadavg "${MAKEOPTS}" 0) -v}"

	local myqmakeargs=(
		--
		-opus
		-printing-and-pdf
		-webp
		$(usex alsa '-alsa' '')
		$(usex bindist '' '-proprietary-codecs')
		$(usex pulseaudio '-pulseaudio' '')
		$(usex system-ffmpeg '-ffmpeg' '')
		$(usex system-icu '-webengine-icu' '')
	)
	qt5-build_src_configure
}

multilib_src_install() {
	qt5-build_src_install

	# bug 601472
	if [[ ! -f ${D%/}${QT5_LIBDIR}/libQt5WebEngine.so ]]; then
		die "${CATEGORY}/${PF} failed to build anything. Please report to https://bugs.gentoo.org/"
	fi
}

multilib_src_install_all() {
	default
	pax-mark m "${D%/}${QT5_LIBEXECDIR}"/QtWebEngineProcess
}
