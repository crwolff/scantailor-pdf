# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(LibXml2 REQUIRED)		# This only finds shared libs
	set(LIB_XML2 LibXml2::LibXml2)
	list(APPEND ALL_EXTERN_INC_DIRS ${LIBXML2_INCLUDE_DIRS})
	
else() # Local build, both shared and static
	
	## Can't build shared and static libs at the same time.
	# Shared
	ExternalProject_Add(
		xml2-extern
		PREFIX ${EXTERN}
		URL https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.4.tar.xz
		URL_HASH SHA256=65d042e1c8010243e617efb02afda20b85c2160acdbfbcb5b26b80cec6515650
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=ON
			-DLIBXML2_WITH_ICONV=OFF
			-DLIBXML2_WITH_PROGRAMS=OFF
			-DLIBXML2_WITH_PYTHON=OFF
			-DLIBXML2_WITH_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	# Static
	ExternalProject_Add(
		xml2-extern-static
		PREFIX ${EXTERN}
		URL https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.4.tar.xz
		URL_HASH SHA256=65d042e1c8010243e617efb02afda20b85c2160acdbfbcb5b26b80cec6515650
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=${EXTERN}
			-DCMAKE_BUILD_TYPE=Release   # Only build release type for external libs
			-DBUILD_SHARED_LIBS=OFF
			-DLIBXML2_WITH_ICONV=OFF
			-DLIBXML2_WITH_PROGRAMS=OFF
			-DLIBXML2_WITH_PYTHON=OFF
			-DLIBXML2_WITH_TESTS=OFF
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_XML2_STATIC "libxml2s.lib")	#checked
		set(ST_XML2_IMPLIB "libxml2.lib")	#checked
		set(ST_XML2_SHARED "libxml2.dll")	#checked
	elseif(MINGW)
		set(ST_XML2_STATIC "libxml2s.a")
		set(ST_XML2_IMPLIB "libxml2.dll.a")
		set(ST_XML2_SHARED "libxml2.dll")
	elseif(APPLE)
		set(ST_XML2_STATIC "libxml2.a")
		set(ST_XML2_SHARED "libxml2.dylib")
	else() # *nix and the rest
		set(ST_XML2_STATIC "libxml2.a")
		set(ST_XML2_SHARED "libxml2.so")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(xml2 SHARED IMPORTED)
	add_library(xml2-static STATIC IMPORTED)

	set_property(
		TARGET xml2 xml2-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	# Shared properties
	set_target_properties(xml2 PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_XML2_SHARED}"
		# Ignored on non-WIN32 platforms
		IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_XML2_IMPLIB}" 
	)
	
	# Static properties
	set_target_properties(xml2-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_XML2_STATIC}"
	)
	
	add_dependencies(xml2 xml2-extern)
	add_dependencies(xml2-static xml2-extern-static)
	
	# Select the correct build type; this should switch the target,
	# if the user changes build type (e.g. -DBUILD_SHARED_LIBS=OFF)
	if(STATIC_BUILD)
		set(LIB_XML2 xml2-static)
	else()
		set(LIB_XML2 xml2)
	endif()

endif()
