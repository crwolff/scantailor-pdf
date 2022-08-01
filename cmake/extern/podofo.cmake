# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
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
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PODOFO_STATIC "podofo-static.lib")
		set(ST_PODOFO_SHARED "podofo.lib")
		set(ST_PODOFO_DLL "podofo.dll")
	elseif(MINGW)
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.dll.a")
		set(ST_PODOFO_DLL "libpodofo.dll")
	elseif(APPLE)
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.dylib")
	else() # *nix and the rest
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.so")
	endif()
	
	ExternalProject_Add(
		podofo-extern
		PREFIX ${EXTERN}
		URL http://sourceforge.net/projects/podofo/files/podofo/0.9.8/podofo-0.9.8.tar.gz/download
		URL_MD5 f6d3d5f917c7150c44fc6a15848442dd
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DPODOFO_BUILD_LIB_ONLY=ON -DPODOFO_BUILD_SHARED=${SHARED_BOOL} -DPODOFO_BUILD_STATIC=${STATIC_BOOL} -DFREETYPE_INCLUDE_DIR_FT2BUILD=${EXTERN_INC_DIR}/freetype2 -DFREETYPE_INCLUDE_DIR_FTHEADER=${EXTERN_INC_DIR}/freetype2/freetype -DCMAKE_CXX_FLAGS=-Wno-unknown-pragmas -DCMAKE_DISABLE_FIND_PACKAGE_LIBCRYPTO=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_LIBIDN=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_UNISTRING=TRUE
		# Remove FindZlib.cmake from podofo. It's outdated and can't find our zlib even with the right prefix.
		PATCH_COMMAND ${CMAKE_COMMAND} -E rm <SOURCE_DIR>/cmake/modules/FindZLIB.cmake
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_PODOFO} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE}
	)
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.	
	if(STATIC_BUILD)
		add_library(podofo STATIC IMPORTED)
		set_property(TARGET podofo
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PODOFO_STATIC}"
		)
	else() # Shared
		add_library(podofo SHARED IMPORTED)
		if(WIN32)
			set_target_properties(podofo PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_PODOFO_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PODOFO_SHARED}"
			)
		else() # *nix
			set_property(TARGET podofo
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_PODOFO_SHARED}"
			)
		endif()
	endif()
	
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/podofo)
	add_dependencies(podofo podofo-extern)
	target_link_libraries(podofo INTERFACE ${LIB_ZLIB} ${LIB_PODOFO} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE})
	set(LIB_PODOFO podofo)

endif()

