# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PLOCALES="be bg ca cs de el en eo es et fa fi fr he hu it ja kk mk nl pl pt_BR pt ru sk sl sr@latin sv sw uk ur_PK vi zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit cmake plocale qmake-utils xdg

L10N_VER="1.5.1606.2"

DESCRIPTION="Qt XMPP client"
HOMEPAGE="https://psi-im.org"
SRC_URI="https://github.com/psi-plus/psi-plus-snapshots/archive/${PV}.tar.gz -> psi-plus-${PV}.tar.gz
	https://github.com/psi-plus/psi-plus-l10n/archive/${L10N_VER}.tar.gz -> psi-plus-l10n-${L10N_VER}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE="webengine debug psimedia plugins +hunspell enchant aspell dbus keyring extras X xscreensaver wayland crypt doc"

REQUIRED_USE="
	?? ( aspell enchant hunspell )
"
BDEPEND="
	virtual/pkgconfig
	doc? ( app-doc/doxygen )
	extras? ( >=sys-devel/qconf-2.4 )
"
DEPEND="
	app-crypt/qca:2[ssl]
	dev-qt/qtconcurrent:5
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtmultimedia:5
	dev-qt/qtnetwork:5
	dev-qt/qtsql:5[sqlite]
	dev-qt/qtsvg:5
	dev-qt/qtwidgets:5
	dev-qt/qtx11extras:5
	dev-qt/qtxml:5
	net-dns/libidn:0
	net-libs/http-parser:=
	net-libs/usrsctp
	sys-libs/zlib[minizip]
	x11-libs/libX11
	x11-libs/libxcb
	aspell? ( app-text/aspell )
	dbus? ( dev-qt/qtdbus:5 )
	enchant? ( app-text/enchant:2 )
	hunspell? ( app-text/hunspell:= )
	keyring? ( dev-libs/qtkeychain:= )
	webengine? (
		dev-qt/qtwebchannel:5
		dev-qt/qtwebengine:5[widgets]
		net-libs/http-parser
	)
	plugins? (
		net-libs/libotr
		app-text/htmltidy
		dev-libs/openssl
		net-libs/libsignal-protocol-c
		dev-libs/libgcrypt
		dev-libs/libgpg-error
	)
	psimedia? (
		media-libs/gstreamer
		media-plugins/gst-plugins-meta
	)
"
RDEPEND="${DEPEND}
	dev-qt/qtimageformats
	crypt? ( app-crypt/qca[gpg] )
"

RESTRICT="test"

for x in ${PLOCALES}; do
        IUSE+=" l10n_${x}"
        BDEPEND+=" l10n_${x}? ( dev-qt/linguist-tools:5 )"
done
unset x

src_unpack() {
	default_src_unpack
	mv "${WORKDIR}/psi-plus-snapshots-${PV}" "${WORKDIR}/psi-plus-${PV}"
}

src_prepare() {
	mv ${S}
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DPRODUCTION=$(usex debug OFF ON)
		-DUSE_ASPELL=$(usex aspell)
		-DUSE_ENCHANT=$(usex enchant)
		-DUSE_HUNSPELL=$(usex hunspell)
		-DUSE_DBUS=$(usex dbus)
		-DINSTALL_PLUGINS_SDK=1
		-DUSE_KEYCHAIN=$(usex keyring)
		-DCHAT_TYPE=$(usex webengine webengine basic)
		-DUSE_XSS=$(usex xscreensaver)
		-DUSE_X11=$(usex X)
		-DLIMIT_X11_USAGE=$(usex wayland)
		-DPSI_PLUS=ON
		-DBUILD_PSIMEDIA=$(usex psimedia)
		-DENABLE_PLUGINS=$(usex plugins)
		-DUSE_CCACHE=OFF
		-DINSTALL_EXTRA_FILES=$(usex extras)
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	use doc && emake -C doc api_public
}

src_install() {
	cmake_src_install

	# this way the docs will be installed in the standard gentoo dir
	rm "${ED}"/usr/share/${PN}/{COPYING,README.html} || die "doc files set seems to have changed"
	newdoc iconsets/roster/README README.roster
	newdoc iconsets/system/README README.system
	newdoc certs/README README.certs
	dodoc README.html

	use doc && HTML_DOCS=( doc/api/. )
	einstalldocs

	# install translations
	local mylrelease="$(qt5_get_bindir)"/lrelease
	cd "${WORKDIR}/psi-plus-l10n-${L10N_VER}" || die
	insinto /usr/share/${PN}
	install_locale() {
		if use "l10n_${1}"; then
			"${mylrelease}" "translations/psi_${1}.ts" || die "lrelease ${1} failed"
			doins "translations/psi_${1}.qm"
		fi
	}
	plocale_for_each_locale install_locale
}

pkg_postinst() {
	xdg_pkg_postinst
	einfo "For GPG support make sure app-crypt/qca is compiled with gpg USE flag."
}
