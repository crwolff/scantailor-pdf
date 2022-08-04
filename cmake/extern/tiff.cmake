# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(TIFF REQUIRED)		# This only finds shared libs
	set(LIB_TIFF TIFF::TIFF)
	list(APPEND ALL_EXTERN_INC_DIRS ${TIFF_INCLUDE_DIRS})
	
else() # Local build
	
	# TODO: Filenames for other platforms and dynamic library
	if(MSVC)
		set(ST_TIFF_STATIC "tiff-static.lib")
		set(ST_TIFF_SHARED "tiff.lib")
		set(ST_TIFF_DLL "tiff.dll")
	elseif(MINGW)
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.dll.a")
		set(ST_TIFF_DLL "libtiff.dll")
	elseif(APPLE)
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.dylib")
	else() # *nix and the rest
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.so")
	endif()

	ExternalProject_Add(
		tiff-extern
		PREFIX ${EXTERN}
		URL https://download.osgeo.org/libtiff/tiff-4.4.0.zip
		URL_HASH SHA256=f9cefcbf7a7bc8462c04fae87de8717bab74ba53c306715a834a6e152bf80c81
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=${EXTERN} -DCMAKE_PREFIX_PATH=${EXTERN} -DBUILD_SHARED_LIBS=ON -Dwebp=OFF -Dlzma=ON -Dzstd=ON -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_ZSTD} ${LIB_LZMA}
	)
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	if(STATIC_BUILD)
		add_library(tiff STATIC IMPORTED)
		set_property(TARGET tiff
			PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_STATIC}"
		)
		if(MSVC)
			set_property(TARGET zlib PROPERTY DEBUG_POSTFIX "d")
		endif()
	else() # Shared
		add_library(tiff SHARED IMPORTED)
		if(WIN32)
			set_target_properties(tiff PROPERTIES
				IMPORTED_LOCATION "${EXTERN_BIN_DIR}/${ST_TIFF_DLL}"
				IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_TIFF_SHARED}"
			)
			if(MSVC)
				set_property(TARGET zlib PROPERTY DEBUG_POSTFIX "d")
			endif()
		else() # *nix
			set_property(TARGET tiff
				PROPERTY IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_SHARED}"
			)
		endif()
	endif()
	
	add_dependencies(tiff tiff-extern)
	target_link_libraries(tiff INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_LZMA} ${LIB_ZSTD})
	set(LIB_TIFF tiff)

endif()
