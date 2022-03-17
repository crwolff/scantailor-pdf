# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(USE_SYSTEM_LIBS AND NOT STATIC_BUILD)

	# There is no FindPoDoFo module, so we need to do it manually
	find_path(PODOFO_INCLUDE_DIR podofo/podofo.h)
	find_library(PODOFO_LIBRARY NAMES podofo)
	
	if (PODOFO_INCLUDE_DIR-NOTFOUND or PODOFO_LIBRARY-NOTFOUND)
		message(FATAL_ERROR "Could not find PoDoFo library. Make sure it is installed. You may also set PODOFO_ROOT or CMAKE_PREFIX_PATH to point to the library location.")
	endif()
	
	add_library(podofo SHARED IMPORTED)
	set_property(TARGET podofo PROPERTY IMPORTED_LOCATION "${PODOFO_LIBRARY}")
	list(APPEND ALL_EXTERN_INC_DIRS ${PODOFO_INCLUDE_DIR})
	set(LIB_PODOFO podofo)
	
else() # Local static build
	
	# TODO: Filenames for other platforms and dynamic library
	set(PODOFO_FILE_NAME "")
	if(MSVC)
		set(PODOFO_FILE_NAME "libpodofo.lib")
	elseif(MINGW)
		set(PODOFO_FILE_NAME "libpodofo.a")
	endif()
	
	ExternalProject_Add(
		podofo-extern
		PREFIX ${EXTERN}
		URL http://sourceforge.net/projects/podofo/files/podofo/0.9.7/podofo-0.9.7.tar.gz/download
		URL_MD5 a3a947e40fc12e0f731b2711e395f236
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DPODOFO_BUILD_LIB_ONLY=ON -DPODOFO_BUILD_SHARED=OFF -DPODOFO_BUILD_STATIC=ON -DFREETYPE_INCLUDE_DIR_FT2BUILD=${EXTERN_INC_DIR}/freetype2 -DFREETYPE_INCLUDE_DIR_FTHEADER=${EXTERN_INC_DIR}/freetype2/freetype -DCMAKE_CXX_FLAGS=-Wno-unknown-pragmas -DCMAKE_DISABLE_FIND_PACKAGE_LIBCRYPTO=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_LIBIDN=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_OpenSSL=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_LUA=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_UNISTRING=TRUE
		# Remove FindZlib.cmake from podofo. It's outdated and can't find our zlib even with the right prefix.
		PATCH_COMMAND ${CMAKE_COMMAND} -E rm <SOURCE_DIR>/cmake/modules/FindZLIB.cmake
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE}
	)	

	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(podofo STATIC IMPORTED)
	set_property(TARGET podofo PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${PODOFO_FILE_NAME}")
	list(APPEND ALL_EXTERN_INC_DIRS ${EXTERN_INC_DIR}/podofo)
	add_dependencies(podofo podofo-extern)
	target_link_libraries(podofo INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE})
	set(LIB_PODOFO podofo)

endif()

