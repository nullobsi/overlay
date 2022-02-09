# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8


inherit meson git-r3

EGIT_REPO_URI="https://git.libcamera.org/libcamera/libcamera.git"
EGIT_BRANCH="master"

DESCRIPTION="An open source camera stack and framework for Linux, Android, and ChromeOS"

# Homepage, not used by Portage directly but handy for developer reference
HOMEPAGE="https://libcamera.org/"

LICENSE="Apache-2.0 BSD-2 BSD CC-BY-SA-4.0 CC0-1.0 GPL-2+ GPL-2 LGPL-2.1+ MIT"

SLOT="0"

KEYWORDS=""

# Comprehensive list of any and all USE flags leveraged in the ebuild,
# with some exceptions, e.g., ARCH specific flags like "amd64" or "ppc".
# Not needed if the ebuild doesn't use any USE flags.
IUSE="tools gstreamer docs ipu3 raspberrypi rkisp1 simple uvc vimc qt v4l2 ipa udev"

# A space delimited list of portage features to restrict. man 5 ebuild
# for details.  Usually not needed.
#RESTRICT="strip"


# Run-time dependencies. Must be defined to whatever this depends on to run.
# Example:
#    ssl? ( >=dev-libs/openssl-1.0.2q:0= )
#    >=dev-lang/perl-5.24.3-r1
# It is advisable to use the >= syntax show above, to reflect what you
# had installed on your system when you tested the package.  Then
# other users hopefully won't be caught without the right version of
# a dependency.
RDEPEND="dev-python/pyyaml dev-python/ply dev-python/jinja
	udev? ( virtual/libudev )
	ipa? (
		net-libs/gnutls dev-libs/openssl
		raspberrypi? ( dev-libs/boost )
	)
	docs? ( dev-python/sphinx app-doc/doxygen media-gfx/graphviz dev-texlive/texlive-latexextra )
	gstreamer? ( media-libs/gstreamer media-libs/gst-plugins-base )
	tools? ( dev-libs/libevent )
	qt? ( dev-qt/qtcore dev-qt/qtgui dev-qt/qtwidgets media-libs/tiff )
"

# Build-time dependencies that need to be binary compatible with the system
# being built (CHOST). These include libraries that we link against.
# The below is valid if the same run-time depends are required to compile.
DEPEND="${RDEPEND}"

# Build-time dependencies that are executed during the emerge process, and
# only need to be present in the native build system (CBUILD). Example:
#BDEPEND=""


src_configure() {
        local emesonargs=(
                $(meson_feature qt qcam)
                $(meson_feature tools cam)
#		$(meson_feature tools lc-compliance)
                $(meson_feature docs documentation)
		$(meson_feature gstreamer)
		$(meson_use v4l2)
		"-Dlc-compliance=disabled"
		"-Dwerror=false"
	)
	pipelines=()
	ipas=()
	if use ipu3; then
		pipelines+=("ipu3")
		use ipa && ipas+=("ipu3")
	fi
	if use raspberrypi; then
		pipelines+=("raspberrypi")
		use ipa && ipas+=("raspberrypi")
	fi
	if use uvc; then
		pipelines+=("uvcvideo")
	fi
	if use rkisp1; then
		pipelines+=("rkisp1")
		use ipa && ipas+=("rkisp1")
	fi
	if use simple; then
		pipelines+=("simple")
	fi
	if use vimc; then
		pipelines+=("vimc")
		use ipa && ipas+=("vimc")
	fi
        meson_src_configure -Dpipelines=$(IFS=, ; echo "${pipelines[*]}") -Dipas=$(IFS=, ; echo "${ipas[*]}")
}

# The following src_compile function is implemented as default by portage, so
# you only need to call it, if you need different behaviour.
#src_compile() {
	# emake is a script that calls the standard GNU make with parallel
	# building options for speedier builds (especially on SMP systems).
	# Try emake first.  It might not work for some packages, because
	# some makefiles have bugs related to parallelism, in these cases,
	# use emake -j1 to limit make to a single process.  The -j1 is a
	# visual clue to others that the makefiles have bugs that have been
	# worked around.

	#emake
#}

# The following src_install function is implemented as default by portage, so
# you only need to call it, if you need different behaviour.
#src_install() {
	# You must *personally verify* that this trick doesn't install
	# anything outside of DESTDIR; do this by reading and
	# understanding the install part of the Makefiles.
	# This is the preferred way to install.
	#emake DESTDIR="${D}" install

	# When you hit a failure with emake, do not just use make. It is
	# better to fix the Makefiles to allow proper parallelization.
	# If you fail with that, use "emake -j1", it's still better than make.

	# For Makefiles that don't make proper use of DESTDIR, setting
	# prefix is often an alternative.  However if you do this, then
	# you also need to specify mandir and infodir, since they were
	# passed to ./configure as absolute paths (overriding the prefix
	# setting).
	#emake \
	#	prefix="${D}"/usr \
	#	mandir="${D}"/usr/share/man \
	#	infodir="${D}"/usr/share/info \
	#	libdir="${D}"/usr/$(get_libdir) \
	#	install
	# Again, verify the Makefiles!  We don't want anything falling
	# outside of ${D}.
