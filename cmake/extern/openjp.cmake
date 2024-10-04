# SPDX-FileCopyrightText: ©2022-4 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(OpenJPEG REQUIRED)		# This only finds shared libs
	include_directories(${OPENJPEG_INCLUDE_DIRS})
	set(LIB_OPENJP openjp2)
	list(APPEND ALL_EXTERN_INC_DIRS ${OPENOPENJP_INCLUDE_DIR})
	
else() # Local build

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
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_OPENJP_STATIC "openjp2.lib")		#checked
		set(ST_OPENJP_IMPLIB "openjp2.lib")		#checked
		set(ST_OPENJP_SHARED "openjp2.dll")		#checked
	elseif(MINGW)
		set(ST_OPENJP_STATIC "libopenjp2.a")		#checked
		set(ST_OPENJP_IMPLIB "libopenjp2.dll.a")
		set(ST_OPENJP_SHARED "libopenjp2.dll")
	elseif(APPLE)
		set(ST_OPENJP_STATIC "libopenjp2.a")
		set(ST_OPENJP_SHARED "libopenjp2.dylib")
	else() # *nix and the rest
		set(ST_OPENJP_STATIC "libopenjp2.a")
		set(ST_OPENJP_SHARED "libopenjp2.so")
	endif()


	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(openjp2 ${LIB_TYPE} IMPORTED)
	set_target_properties(openjp2 PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/openjpeg-2.5
	)

	if(BUILD_SHARED_LIBS)
		set_target_properties(openjp2 PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_OPENJP_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_OPENJP_IMPLIB}"
		)
	else()
		set_target_properties(openjp2 PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_OPENJP_STATIC}"
		)
	endif()

	add_dependencies(openjp2 openjp2-extern)
	set(LIB_OPENJP openjp2)

endif()

