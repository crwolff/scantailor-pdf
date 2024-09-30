# SPDX-FileCopyrightText: ©2022-4 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	include(FindOpenOPENJP)
	find_package(OpenOPENJP REQUIRED)		# This only finds shared libs
	set(LIB_OPENJP OpenOPENJP::OpenOPENJP)
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
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=${SHARED_BOOL}
			-DBUILD_STATIC_LIBS=${STATIC_BOOL}
			-DBUILD_CODEC=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_OPENJP_STATIC "libopenjp2-static.lib")
		set(ST_OPENJP_IMPLIB "libopenjp2.lib")
		set(ST_OPENJP_SHARED "libopenjp2.dll")
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
	if(${BUILD_SHARED_LIBS})
		add_library(openjp2 SHARED IMPORTED)
		set_target_properties(openjp2 PROPERTIES
			IMPORTED_CONFIGURATIONS $<CONFIG>
			MAP_IMPORTED_CONFIG_DEBUG Release
			MAP_IMPORTED_CONFIG_MINSIZEREL Release
			MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
			INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/openjpeg-2.5
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_OPENJP_IMPLIB}" 
		)		
		add_dependencies(openjp2 openjp2-extern)
		set(LIB_OPENJP openjp2)
	else()
		add_library(openjp2-static STATIC IMPORTED)
		set_target_properties(openjp2-static PROPERTIES
			IMPORTED_CONFIGURATIONS $<CONFIG>
			MAP_IMPORTED_CONFIG_DEBUG Release
			MAP_IMPORTED_CONFIG_MINSIZEREL Release
			MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
			INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/openjpeg-2.5
			IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_STATIC}"
		)
		add_dependencies(openjp2-static openjp2-extern)
		set(LIB_OPENJP openjp2-static)
	endif()

endif()

