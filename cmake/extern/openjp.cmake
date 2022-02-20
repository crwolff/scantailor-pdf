# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	include(FindOpenJPEG)
	find_package(OpenJPEG REQUIRED)		# This only finds shared libs
	set(LIB_OPENJP ${OPENJPEG::OpenJPEG})
	list(APPEND ALL_EXTERN_INC_DIRS ${OPENJPEG_INCLUDE_DIR})
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(OPENJP_FILE_NAME "")
	if(MSVC)
		set(OPENJP_FILE_NAME "libopenjp2.lib")
	elseif(MINGW)
		set(OPENJP_FILE_NAME "libopenjp2.a")
	endif()
	
	ExternalProject_Add(
		openjp2-extern
		PREFIX ${EXTERN}
		URL https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.4.0.tar.gz
		URL_HASH SHA256=8702ba68b442657f11aaeb2b338443ca8d5fb95b0d845757968a7be31ef7f16d
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DBUILD_SHARED_LIBS=OFF -DBUILD_CODEC=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(openjp2 STATIC IMPORTED)
	set_property(TARGET openjp2 PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${OPENJP_FILE_NAME}")
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/openjpeg-2.4)
	add_dependencies(openjp2 openjp2-extern)
	set(LIB_OPENJP ${openjp2})

endif()

