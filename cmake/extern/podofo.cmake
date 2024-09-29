# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	# There is no FindPoDoFo module, so we need to do it manually
	find_path(PODOFO_INCLUDE_DIR podofo/podofo.h)
	find_library(PODOFO_LIBRARY NAMES podofo)
	
	if (NOT PODOFO_INCLUDE_DIR AND NOT PODOFO_LIBRARY)
		message(FATAL_ERROR "Could not find PoDoFo library. Make sure it is installed. You may also set PODOFO_ROOT or CMAKE_PREFIX_PATH to point to the library location.")
	endif()
	
	add_library(podofo SHARED IMPORTED)
	set_property(TARGET podofo PROPERTY IMPORTED_LOCATION "${PODOFO_LIBRARY}")
	list(APPEND ALL_EXTERN_INC_DIRS ${PODOFO_INCLUDE_DIR})
	set(LIB_PODOFO podofo)
	
else() # Local build
	
	ExternalProject_Add(
		podofo-extern
		PREFIX ${EXTERN}
		URL https://github.com/podofo/podofo/archive/refs/tags/0.10.4.tar.gz
		URL_HASH SHA256=6b1b13cdfb2ba5e8bbc549df507023dd4873bc946211bc6942183b8496986904
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DPODOFO_BUILD_LIB_ONLY=ON
#			-DPODOFO_BUILD_SHARED=ON
			-DPODOFO_BUILD_STATIC=ON
			-DCMAKE_DISABLE_FIND_PACKAGE_LIBCRYPTO=TRUE
			-DCMAKE_DISABLE_FIND_PACKAGE_LIBIDN=TRUE
			-DCMAKE_DISABLE_FIND_PACKAGE_UNISTRING=TRUE
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} openssl-extern-static
	)

	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PODOFO_STATIC "podofo-static.lib")
		set(ST_TIFF_IMPLIB "podofo.lib")
		set(ST_TIFF_SHARED "podofo.dll")
	elseif(MINGW)
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_TIFF_IMPLIB "libpodofo.dll.a")
		set(ST_TIFF_SHARED "libpodofo.dll")
	elseif(APPLE)
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.dylib")
	else() # *nix and the rest
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(podofo SHARED IMPORTED)
	add_library(podofo-static STATIC IMPORTED)

	set_property(
		TARGET podofo podofo-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(podofo PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PODOFO_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PODOFO_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(podofo-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PODOFO_STATIC}"
	)
	
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/podofo)
	
	add_dependencies(podofo podofo-extern)
	add_dependencies(podofo-static podofo-extern)
	
	target_link_libraries(podofo INTERFACE ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} ${LIB_SSL})
	target_link_libraries(podofo-static INTERFACE ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} ${LIB_SSL})

	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_PODOFO podofo-static)
	else()
		set(LIB_PODOFO podofo)
	endif()

endif()

