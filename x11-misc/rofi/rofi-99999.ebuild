# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit meson git-r3 toolchain-funcs

DESCRIPTION="A window switcher, run dialog and dmenu replacement"
HOMEPAGE="https://github.com/lbonn/rofi"
EGIT_REPO_URI="https://github.com/lbonn/rofi"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="test windowmode drun wayland X"
RESTRICT="!test? ( test )"
EGIT_OVERRIDE_BRANCH_LBONN_ROFI="wayland"

RDEPEND="
	dev-libs/glib:2
	gnome-base/librsvg:2
	media-libs/freetype
	X? (
		x11-libs/cairo[X,xcb(+)]
		x11-libs/libXft
		x11-libs/libXinerama
		x11-libs/libxcb
		x11-libs/libxkbcommon[X]
		x11-libs/pango[X]
		x11-libs/xcb-util
		x11-libs/xcb-util-wm
		x11-libs/xcb-util-xrm
		x11-libs/startup-notification
	)
	wayland? (
		dev-libs/wayland
		x11-libs/cairo
		x11-libs/pango
	)
"
DEPEND="
	${RDEPEND}
	virtual/pkgconfig
	X? ( x11-base/xorg-proto )
	wayland? ( dev-libs/wayland-protocols )
	test? ( >=dev-libs/check-0.11 )
"
PATCHES=(
	"${FILESDIR}"/${PN}-0.15.12-Werror.patch
	"${FILESDIR}"/${PN}-1.5.0-gtk-settings-test.patch
)

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	tc-export CC
	local emesonargs=(
		$(meson_use drun)
		$(meson_use windowmode window)
		$(meson_feature test check)
		$(meson_feature wayland)
		$(meson_feature X xcb)
	)
	meson_src_configure
}
