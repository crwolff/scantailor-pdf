# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(Freetype REQUIRED)		# This only finds shared libs
	# list(APPEND ALL_EXTERN_INC_DIRS ${FREETYPE_INCLUDE_DIRS})
	
else() # Local build
	
	# Check if we built the package already
	find_package(Freetype
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(Freetype_FOUND)

		message(STATUS "Found Freetype in ${Freetype_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(freetype-extern DEPENDS Freetype::Freetype)

	else()	# Freetype has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			freetype-extern
			URL https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz
			URL_HASH SHA256=0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			PREFIX ${EXTERN}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DFT_DISABLE_BZIP2=TRUE
				-DFT_DISABLE_BROTLI=TRUE
				-DFT_DISABLE_HARFBUZZ=TRUE
				-DZLIB_USE_STATIC_LIBS=${ZLIB_USE_STATIC_LIBS}
				-DBUILD_SHARED_LIBS=${SHARED_BOOL}
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS zlib-extern png-extern
		)

	endif()
endif()
