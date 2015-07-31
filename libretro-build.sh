#! /usr/bin/env bash
# vim: set ts=3 sw=3 noet ft=sh : bash

SCRIPT="${0#./}"
BASE_DIR="${SCRIPT%/*}"
WORKDIR="$PWD"

if [ "$BASE_DIR" = "$SCRIPT" ]; then
	BASE_DIR="$WORKDIR"
else
	if [[ "$0" != /* ]]; then
		# Make the path absolute
		BASE_DIR="$WORKDIR/$BASE_DIR"
	fi
fi

. "$BASE_DIR/libretro-config.sh"

if [ -z "$RARCH_DIST_DIR" ]; then
	RARCH_DIR="$WORKDIR/dist"
	RARCH_DIST_DIR="$RARCH_DIR/$DIST_DIR"
fi

if [ -z "$JOBS" ]; then
	JOBS=7
fi

if [ "$HOST_CC" ]; then
	CC="${HOST_CC}-gcc"
	CXX="${HOST_CC}-g++"
	CXX11="${HOST_CC}-g++"
	STRIP="${HOST_CC}-strip"
fi

if [ -z "$MAKE" ]; then
	if uname -s | grep -i MINGW > /dev/null 2>&1; then
		MAKE=mingw32-make
	else
		if type gmake > /dev/null 2>&1; then
			MAKE=gmake
		else
			MAKE=make
		fi
	fi
fi

if [ -z "$CC" ]; then
	if [ $FORMAT_COMPILER_TARGET = "osx" ]; then
		CC=cc
	elif uname -s | grep -i MINGW32 > /dev/null 2>&1; then
		CC=mingw32-gcc
	else
		CC=gcc
	fi
fi

if [ -z "$CXX" ]; then
	if [ $FORMAT_COMPILER_TARGET = "osx" ]; then
		CXX=c++
		CXX11="clang++ -std=c++11 -stdlib=libc++"
		# FIXME: Do this right later.
		if [ "$ARCH" = "i386" ]; then
			CC="cc -arch i386"
			CXX="c++ -arch i386"
			CXX11="clang++ -arch i386 -std=c++11 -stdlib=libc++"
		fi
	elif uname -s | grep -i MINGW32 > /dev/null 2>&1; then
		CXX=mingw32-g++
		CXX11=mingw32-g++
	else
		CXX=g++
		CXX11=g++
	fi
fi

FORMAT_COMPILER_TARGET_ALT=$FORMAT_COMPILER_TARGET


if [ "$FORMAT_COMPILER_TARGET" = "ios" ]; then
	echo "iOS path: ${IOSSDK}"
	echo "iOS version: ${IOSVER}"
fi
echo "CC = $CC"
echo "CXX = $CXX"
echo "CXX11 = $CXX11"
echo "STRIP = $STRIP"


. "$BASE_DIR/libretro-build-common.sh"

# These are cores which only work properly right
# now on little-endian architecture systems

build_default_cores_little_endian_only() {
	libretro_build_core tgbdual
	if [ $platform != "psp1" ]; then
		libretro_build_core gpsp
		libretro_build_core o2em
	fi
	libretro_build_core 4do

	if [ $platform != "qnx" ]; then
		if [ $platform != "psp1" ]; then
			libretro_build_core desmume
		fi
		libretro_build_core picodrive
	fi

	# TODO - Verify endianness compatibility - for now exclude
	libretro_build_core virtualjaguar
	libretro_build_core prosystem
}

# These are C++11 cores

build_default_cores_cpp11() {
	libretro_build_core dinothawr
	libretro_build_core stonesoup
	libretro_build_core bsnes
	libretro_build_core bsnes_mercury
	libretro_build_core mame
}

# These are cores intended for platforms with a limited
# amount of RAM, where the full version would not fit
# into memory

build_default_cores_small_memory_footprint() {
	libretro_build_core fb_alpha_cps1
	libretro_build_core fb_alpha_cps2
	libretro_build_core fb_alpha_neo
}

build_default_cores_libretro_gl() {
	# Reasons for not compiling this yet on these targets (other than endianness issues)
	# 1) Wii/NGC - no PPC dynarec, no usable graphics plugins that work with GX
	# 2) PS3     - no PPC dynarec, PSGL is GLES 1.0 while graphics plugins right now require GL 2.0+/GLES2
	# 3) QNX     - Compilation issues, ARM NEON compiler issues
	if [ $platform != "qnx" ]; then
		libretro_build_core mupen64plus
	fi

	# Graphics require GLES 2/GL 2.0
	if [ $platform != "psp1" ]; then
		libretro_build_core 3dengine
	fi
}

# These build everywhere libretro-build.sh works
# (They also use rules builds, which will help later)

build_default_cores() {
	if [ $platform == "wii" ] || [ $platform == "ngc" ] || [ $platform == "psp1" ]; then
		build_default_cores_small_memory_footprint
	fi
	libretro_build_core 2048
	libretro_build_core bluemsx
	if [ $platform != "psp1" ] && [ $platform != "ngc" ] && [ $platform != "wii" ] && [ $platform != "ps3" ] && [ $platform != "sncps3" ]; then
		libretro_build_core dosbox
		libretro_build_core catsfc
	fi
	if [ $platform != "psp1" ]; then
		# Excluded for binary size reasons
		libretro_build_core fb_alpha
	fi
	libretro_build_core fceumm
	libretro_build_core fmsx
	libretro_build_core gambatte
	if [ $platform != "ngc" ] && [ $platform != "wii" ] && [ $platform != "ps3" ] && [ $platform != "sncps3" ]; then
		libretro_build_core handy
	fi
	libretro_build_core stella
	libretro_build_core nestopia
	libretro_build_core nxengine
	libretro_build_core prboom
	libretro_build_core quicknes
	libretro_build_core snes9x_next
	libretro_build_core tyrquake
	libretro_build_core vba_next
	libretro_build_core vecx

	if [ $platform != "psp1" ]; then
		# (PSP) Compilation issues
		libretro_build_core mgba
		# (PSP) Performance issues
		libretro_build_core genesis_plus_gx
	fi

	if [ $platform != "psp1" ] && [ $platform != "wii" ] && [ $platform != "ngc" ]; then
		# (PSP/NGC/Wii) Performance and/or binary size issues
		libretro_build_core bsnes_cplusplus98
		libretro_build_core mame078
		libretro_build_core mednafen_gba
	fi

	libretro_build_core mednafen_lynx
	libretro_build_core mednafen_ngp
	libretro_build_core mednafen_pce_fast

	libretro_build_core mednafen_supergrafx
	libretro_build_core mednafen_vb
	libretro_build_core mednafen_wswan

	libretro_build_core gw

	if [ $platform != "ps3" ] && [ $platform != "sncps3" ]; then
		libretro_build_core fuse
	fi

	if [ $platform != "ps3" ] && [ $platform != "sncps3" ] && [ $platform != "wii" ] && [ $platform != "ngc" ]; then
		build_default_cores_little_endian_only

		build_default_cores_libretro_gl

		libretro_build_core lutro

		# (PS3/NGC/Wii) Excluded for performance reasons
		libretro_build_core snes9x
		libretro_build_core vbam

		if [ $platform != "psp1" ]; then
			# The only reason ScummVM won't be compiled in yet is
			# 1) Wii/NGC/PSP - too big in binary size
			# 2) PS3 - filesystem API issues
			libretro_build_core scummvm

			# Excluded for performance reasons
			libretro_build_core mednafen_pcfx
			libretro_build_core mednafen_psx
			if [ $platform != "qnx" ]; then
				libretro_build_core mednafen_snes
			fi
		fi

		# Could work on PS3/Wii right now but way too slow right now,
		# and messed up big-endian colors
		libretro_build_core yabause

		# Compilation/port status issues
		libretro_build_core hatari
		libretro_build_core meteor

		if [ $platform != "qnx" ] && [ $platform != "psp1" ]; then
			build_default_cores_cpp11

			# Just basic compilation issues right now for these platforms
			libretro_build_core emux

			if [ $platform != "win" ]; then
				# Reasons for not compiling this on Windows yet -
				# (Windows) - Doesn't work properly
				# (QNX)     - Compilation issues
				# (PSP1)    - Performance/compilation issues
				# (Wii)     - Performance/compilation issues
				# (PS3)     - Performance/compilation issues
				libretro_build_core pcsx_rearmed
			fi

			if [ $platform != "ios" ]; then
				# Would need ffmpeg libraries baked in
				libretro_build_core ffmpeg
				libretro_build_core ppsspp

				libretro_build_core bnes
			fi
		fi

		build_libretro_test
	fi
}


mkdir -p "$RARCH_DIST_DIR"

if [ -n "$SKIP_UNCHANGED" ]; then
	[ -z "$BUILD_REVISIONS_DIR" ] && BUILD_REVISIONS_DIR="$WORKDIR/build-revisions"
	echo "mkdir -p \"$BUILD_REVISIONS_DIR\""
	mkdir -p "$BUILD_REVISIONS_DIR"
fi

if [ -n "$1" ]; then
	while [ -n "$1" ]; do
		case "$1" in
			--nologs)
				LIBRETRO_LOG_SUPER=""
				LIBRETRO_LOG_CORE=""
				;;
			*)
				# New style (just generic cores for now)
				want_cores="$want_cores $1"
				;;
		esac
		shift
	done
fi

libretro_log_init
if [ -n "$want_cores" ]; then
	for core in $want_cores; do
		libretro_build_core $core
	done
else
	build_default_cores
fi
summary
