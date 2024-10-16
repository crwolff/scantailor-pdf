# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(zstd)		# This only finds shared libs
	
else() # Local build
	
	# Check if we built the package already
	find_package(zstd
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(zstd_FOUND)

		if(BUILD_SHARED_LIBS)
			add_library(zstd ALIAS zstd::libzstd_shared)
		else()
			add_library(zstd ALIAS zstd::libzstd_static)
		endif()

		message(STATUS "Found Zstd in ${zstd_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(zstd-extern DEPENDS zstd)

	else()	# zstd has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			zstd-extern
			PREFIX ${EXTERN}
			URL https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz
			URL_HASH SHA256=7c42d56fac126929a6a85dbc73ff1db2411d04f104fae9bdea51305663a83fd0
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			SOURCE_SUBDIR build/cmake
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DZSTD_BUILD_STATIC=${STATIC_BOOL}
				-DZSTD_BUILD_SHARED=${SHARED_BOOL}
				-DZSTD_BUILD_PROGRAMS=OFF
				-DZSTD_BUILD_TESTS=OFF
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
	endif()
endif()
