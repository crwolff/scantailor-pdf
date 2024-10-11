# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

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
	
	set(DISABLE_FIND_PACKAGE)
	if(WIN32)
		set(DISABLE_FIND_PACKAGE -DCMAKE_DISABLE_FIND_PACKAGE_Libidn=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_Fontconfig=TRUE)
	else()
		set(DISABLE_FIND_PACKAGE -DCMAKE_DISABLE_FIND_PACKAGE_Libidn=TRUE)
	endif()

	ExternalProject_Add(
		podofo-extern
		PREFIX ${EXTERN}
		URL https://github.com/podofo/podofo/archive/refs/tags/0.10.4.tar.gz
		URL_HASH SHA256=6b1b13cdfb2ba5e8bbc549df507023dd4873bc946211bc6942183b8496986904
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DPODOFO_BUILD_LIB_ONLY=ON
			-DPODOFO_BUILD_STATIC=${STATIC_BOOL}
			${DISABLE_FIND_PACKAGE}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} ${LIB_SSL} ${LIB_CRYP} ${LIB_LZMA}
	)

	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_PODOFO_STATIC "podofo.lib")				#checked
		set(ST_PODOFO_PRIVATE "podofo_private.lib")	#checked
		set(ST_PODOFO_IMPLIB "podofo.lib")				#checked
		set(ST_PODOFO_SHARED "podofo.dll")				#checked
	elseif(MINGW)
		set(ST_PODOFO_STATIC "libpodofo.a")				#checked
		set(ST_PODOFO_PRIVATE "libpodofo_private.a")	#checked
		set(ST_PODOFO_IMPLIB "libpodofo.dll.a")
		set(ST_PODOFO_SHARED "libpodofo.dll")
	elseif(APPLE)
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.dylib")
	else() # *nix and the rest
		set(ST_PODOFO_STATIC "libpodofo.a")
		set(ST_PODOFO_SHARED "libpodofo.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(podofo ${LIB_TYPE} IMPORTED)
	set_target_properties(podofo PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/podofo
	)
	target_link_libraries(podofo INTERFACE ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} ${LIB_SSL} ${LIB_CRYP} ${LIB_LZMA})
	
	if(WIN32)
		target_link_libraries(podofo INTERFACE kernel32 user32 gdi32 winspool comdlg32 advapi32 shell32 ole32 oleaut32 uuid ws2_32 Crypt32)
	endif()
	
	
	if(BUILD_SHARED_LIBS)
		set_target_properties(podofo PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_BIN_DIR}/${ST_PODOFO_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_PODOFO_IMPLIB}"
			)

	else() # Static

		set_target_properties(podofo PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_PODOFO_STATIC}"
		)
		target_compile_definitions(podofo INTERFACE PODOFO_STATIC)
		
		# For static we also need the private lib
		add_library(podofo-private ${LIB_TYPE} IMPORTED)
		set_target_properties(podofo-private PROPERTIES
			IMPORTED_CONFIGURATIONS $<CONFIG>
			MAP_IMPORTED_CONFIG_DEBUG Release
			MAP_IMPORTED_CONFIG_MINSIZEREL Release
			MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
			INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/podofo
		)
		set_target_properties(podofo-private PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_PODOFO_PRIVATE}"
		)
		target_link_libraries(podofo-private INTERFACE ${LIB_ZLIB} ${LIB_PNG} ${LIB_TIFF} ${LIB_FREETYPE} ${LIB_XML2} ${LIB_SSL} ${LIB_CRYP} ${LIB_LZMA})
		if(WIN32)
			target_link_libraries(podofo-private INTERFACE kernel32 user32 gdi32 winspool comdlg32 advapi32 shell32 ole32 oleaut32 uuid ws2_32 Crypt32)
		endif()

		target_compile_definitions(podofo-private INTERFACE PODOFO_STATIC)
		target_link_libraries(podofo INTERFACE podofo-private)
		add_dependencies(podofo-private podofo-extern)
	
	endif()

	add_dependencies(podofo podofo-extern)
	set(LIB_PODOFO podofo)

endif()
