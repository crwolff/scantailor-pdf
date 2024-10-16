# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(LibLZMA)		# This only finds shared libs
	if(LIBLZMA_FOUND)
		# list(APPEND ALL_EXTERN_INC_DIRS ${LIBLZMA_INCLUDE_DIRS})
	endif()
	
else() # Local build
	
	# Check if we built the package already
	find_package(LibLZMA
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(LibLZMA_FOUND)

		# Use target liblzma::liblzma
		# Fix static linking definition
		if(NOT BUILD_SHARED_LIBS)
		 	set_target_properties(liblzma::liblzma PROPERTIES
		 		INTERFACE_COMPILE_DEFINITIONS LZMA_API_STATIC
			)
		endif()

		message(STATUS "Found LibLZMA in ${LibLZMA_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(lzma-extern DEPENDS liblzma::liblzma)

	else()	# LibLZMA has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)
		
		ExternalProject_Add(
			lzma-extern
			URL https://github.com/tukaani-project/xz/releases/download/v5.6.2/xz-5.6.2.tar.xz
			URL_HASH SHA256=a9db3bb3d64e248a0fae963f8fb6ba851a26ba1822e504dc0efd18a80c626caf
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			PREFIX ${EXTERN}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DENABLE_NLS=OFF
				-DBUILD_SHARED_LIBS=${SHARED_BOOL}
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
	
	endif()
endif()
