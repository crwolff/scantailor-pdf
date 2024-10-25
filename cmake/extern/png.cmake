# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(PNG REQUIRED)		# This only finds shared libs
	
else() # Local build
	
	# Check if we built the package already
	find_package(png
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(png_FOUND)

		message(STATUS "Found png in ${png_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(png-extern DEPENDS PNG::PNG)

	else()	# png has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			png-extern
			PREFIX ${EXTERN}
			URL https://download.sourceforge.net/libpng/libpng-1.6.44.tar.xz
			URL_HASH SHA256=60c4da1d5b7f0aa8d158da48e8f8afa9773c1c8baa5d21974df61f1886b8ce8e
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DCMAKE_MODULE_PATH=
				-DZLIB_ROOT=${EXTERN}
				-DZLIB_USE_STATIC_LIBS=${ZLIB_USE_STATIC_LIBS}
				-DSKIP_INSTALL_EXECUTABLES=ON
				-DSKIP_INSTALL_PROGRAMS=ON
				-DPNG_TOOLS=OFF
				-DPNG_TESTS=OFF
				-DPNG_STATIC=${STATIC_BOOL}
				-DPNG_SHARED=${SHARED_BOOL}
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS zlib-extern lzma-extern
		)

		# Hardlink static lib to shared name so qt5 can pick up our png under msvc
		# if(NOT BUILD_SHARED_LIBS AND MSVC)
		# 	ExternalProject_Add_Step(
		# 		png-extern qt5-compat-install
		# 		DEPENDEES install
		# 		COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/${ST_PNG_STATIC} ${EXTERN_LIB_DIR}/${ST_PNG_IMPLIB}
		# 	)
		# endif()
	endif()
endif()
