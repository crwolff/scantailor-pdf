# SPDX-FileCopyrightText: ©2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(OpenJPEG REQUIRED)		# This only finds shared libs
	# include_directories(${OPENJPEG_INCLUDE_DIRS})
	# list(APPEND ALL_EXTERN_INC_DIRS ${OPENOPENJP_INCLUDE_DIR})
	
else() # Local build

	# Check if we built the package already
	find_package(OpenJPEG
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(OpenJPEG_FOUND)

		# Fix static linking definition
		if(NOT BUILD_SHARED_LIBS)
			set_target_properties(openjp2 PROPERTIES
				INTERFACE_COMPILE_DEFINITIONS OPJ_STATIC
			)
		endif()

		message(STATUS "Found OpenJPEG in ${OpenJPEG_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(openjp2-extern DEPENDS openjp2)

	else()	# openjp2 has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			openjp2-extern
			PREFIX ${EXTERN}
			URL https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.2.tar.gz
			URL_HASH SHA256=90e3896fed910c376aaf79cdd98bdfdaf98c6472efd8e1debf0a854938cbda6a
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DBUILD_SHARED_LIBS=${SHARED_BOOL}
				-DBUILD_STATIC_LIBS=${STATIC_BOOL}
				-DBUILD_CODEC=OFF
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)

	endif()
endif()

