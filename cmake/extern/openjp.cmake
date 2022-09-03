# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

    include(FindOpenJPEG)
    find_package(OpenJPEG REQUIRED)		# This only finds shared libs
    set(LIB_OPENJP ${OPENJPEG_LIBRARIES})
    list(APPEND ALL_EXTERN_INC_DIRS ${OPENJPEG_INCLUDE_DIR})
	
else() # Local build
		
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_OPENJP_STATIC "libopenjp2-static.lib")
		set(ST_OPENJP_SHARED "libopenjp2.lib")
		set(ST_OPENJP_DLL "libopenjp2.dll")
	elseif(MINGW)
		set(ST_OPENJP_STATIC "libopenjp2.a")
		set(ST_OPENJP_SHARED "libopenjp2.dll.a")
		set(ST_OPENJP_DLL "libopenjp2.dll")
	elseif(APPLE)
		set(ST_OPENJP_STATIC "libopenjp2.a")
		set(ST_OPENJP_SHARED "libopenjp2.dylib")
	else() # *nix and the rest
		set(ST_OPENJP_STATIC "libopenjp2.a")
		set(ST_OPENJP_SHARED "libopenjp2.so")
	endif()
	
	ExternalProject_Add(
		openjp2-extern
		PREFIX ${EXTERN}
		URL https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.0.tar.gz
		URL_HASH SHA256=0333806d6adecc6f7a91243b2b839ff4d2053823634d4f6ed7a59bc87409122a
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DBUILD_SHARED_LIBS=${SHARED_BOOL} -DBUILD_STATIC_LIBS=${STATIC_BOOL} -DBUILD_CODEC=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.	
	if(STATIC_BUILD)
		add_library(openjp2 STATIC IMPORTED)
		add_definitions(-DOPJ_STATIC)
		set_property(TARGET openjp2
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_STATIC}"
		)
	else() # Shared
		add_library(openjp2 SHARED IMPORTED)
		if(WIN32)
			# For some reason, we can't 
			set_target_properties(openjp2 PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_OPENJP_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_OPENJP_SHARED}"
			)
		else() # *nix
			set_property(TARGET openjp2
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_OPENJP_SHARED}"
			)
		endif()
	endif()
	
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/openjpeg-2.5)
	add_dependencies(openjp2 openjp2-extern)
	set(LIB_OPENJP openjp2)

endif()

