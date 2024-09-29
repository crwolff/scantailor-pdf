# SPDX-FileCopyrightText: ©2022-4 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	include(FindOpenOPENJP)
	find_package(OpenOPENJP REQUIRED)		# This only finds shared libs
	set(LIB_OPENJP OpenOPENJP::OpenOPENJP)
	list(APPEND ALL_EXTERN_INC_DIRS ${OPENOPENJP_INCLUDE_DIR})
	
else() # Local build
		
	# Shared and static
	ExternalProject_Add(
		openjp2-extern
		PREFIX ${EXTERN}
		URL https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.2.tar.gz
		URL_HASH SHA256=90e3896fed910c376aaf79cdd98bdfdaf98c6472efd8e1debf0a854938cbda6a
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=ON
			-DBUILD_STATIC_LIBS=ON
			-DBUILD_CODEC=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_OPENJP_STATIC "libopenjp2-static.lib")
		set(ST_OPENJP_IMPLIB "libopenjp2.lib")
		set(ST_OPENJP_SHARED "libopenjp2.dll")
	elseif(MINGW)
		set(ST_OPENJP_STATIC "libopenjp2.a")
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
	add_library(openjp2 SHARED IMPORTED)
	add_library(openjp2-static STATIC IMPORTED)

	set_property(
		TARGET openjp2 openjp2-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(openjp2 PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_OPENJP_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(openjp2-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_STATIC}"
	)
	
	add_dependencies(openjp2 openjp2-extern)
	add_dependencies(openjp2-static openjp2-extern)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_OPENJP openjp2-static)
	else()
		set(LIB_OPENJP openjp2)
	endif()

endif()

