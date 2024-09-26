# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(TIFF REQUIRED)		# This only finds shared libs
	set(LIB_TIFF TIFF::TIFF)
	list(APPEND ALL_EXTERN_INC_DIRS ${TIFF_INCLUDE_DIRS})
	
else() # Local build
	
	ExternalProject_Add(
		tiff-extern
		PREFIX ${EXTERN}
		URL https://download.osgeo.org/libtiff/tiff-4.7.0.tar.xz
		URL_HASH SHA256=273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_PREFIX_PATH=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=OFF
			-Dwebp=OFF
			-Dlzma=ON
			-Dzstd=ON
			-Dtiff-tools=OFF
			-Dtiff-tests=OFF
			-Dtiff-contrib=OFF
			-Dtiff-docs=OFF
			-DCMAKE_DISABLE_FIND_PACKAGE_GLUT=TRUE
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		DEPENDS ${LIB_ZLIB} ${LIB_JPEG} ${LIB_ZSTD} ${LIB_LZMA}
	)
	
	
	# TODO: Filenames for other platforms and dynamic library
	if(MSVC)
		set(ST_TIFF_STATIC "tiff.lib")
		set(ST_TIFF_IMPLIB "tiff.lib")
		set(ST_TIFF_SHARED "tiff.dll")
	elseif(MINGW)
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_IMPLIB "libtiff.dll.a")
		set(ST_TIFF_SHARED "libtiff.dll")
	elseif(APPLE)
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.dylib")
	else() # *nix and the rest
		set(ST_TIFF_STATIC "libtiff.a")
		set(ST_TIFF_SHARED "libtiff.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(tiff SHARED IMPORTED)
	add_library(tiff-static STATIC IMPORTED)

	set_property(
		TARGET tiff tiff-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(tiff PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_TIFF_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(tiff-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_TIFF_STATIC}"
	)
	
	add_dependencies(tiff tiff-extern)
	add_dependencies(tiff-static tiff-extern)
	
	target_link_libraries(tiff INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_LZMA} ${LIB_ZSTD})
	target_link_libraries(tiff-static INTERFACE ${LIB_ZLIB} ${LIB_JPEG} ${LIB_LZMA} ${LIB_ZSTD})

	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_TIFF tiff-static)
	else()
		set(LIB_TIFF tiff)
	endif()

endif()
