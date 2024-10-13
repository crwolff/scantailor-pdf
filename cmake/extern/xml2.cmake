# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(LibXml2 REQUIRED)		# This only finds shared libs
	set(LIB_XML2 LibXml2::LibXml2)
	list(APPEND ALL_EXTERN_INC_DIRS ${LIBXML2_INCLUDE_DIRS})
	
else() # Local build
	
	set(XML2-EXTERN xml2-extern)
		
	ExternalProject_Add(
		${XML2-EXTERN}
		URL https://download.gnome.org/sources/libxml2/2.13/libxml2-2.13.4.tar.xz
		URL_HASH SHA256=65d042e1c8010243e617efb02afda20b85c2160acdbfbcb5b26b80cec6515650
		PREFIX ${EXTERN}
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
			-DBUILD_SHARED_LIBS=${SHARED_BOOL}
			-DLIBXML2_WITH_ICONV=OFF
			-DLIBXML2_WITH_PROGRAMS=OFF
			-DLIBXML2_WITH_PYTHON=OFF
			-DLIBXML2_WITH_TESTS=OFF
		BUILD_COMMAND
			${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
		INSTALL_COMMAND
			${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)


	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_XML2_STATIC "libxml2s.lib")	#checked
		set(ST_XML2_IMPLIB "libxml2.lib")	#checked
		set(ST_XML2_SHARED "libxml2.dll")	#checked
	elseif(MINGW)
		set(ST_XML2_STATIC "libxml2.a")		#checked
		set(ST_XML2_IMPLIB "libxml2.dll.a")	#checked
		set(ST_XML2_SHARED "libxml2.dll")	#checked
	elseif(APPLE)
		set(ST_XML2_STATIC "libxml2.a")
		set(ST_XML2_SHARED "libxml2.dylib")
	else() # *nix and the rest
		set(ST_XML2_STATIC "libxml2.a")
		set(ST_XML2_SHARED "libxml2.so")
	endif()
	
	
	# podofo under msvc can't find libxml2s.lib; create hardlink from static lib to shared name
	if(NOT BUILD_SHARED_LIBS AND MSVC)
		ExternalProject_Add_Step(
			xml2-extern podofo-compat-install
			DEPENDEES install
			# create a hardlink with the name of the shared implib
			COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/${ST_XML2_STATIC} ${EXTERN_LIB_DIR}/${ST_XML2_IMPLIB}
		)
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(xml2 ${LIB_TYPE} IMPORTED)
	set_target_properties(xml2 PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/libxml2/libxml
	)
	
	if(WIN32)
		target_link_libraries(xml2 INTERFACE Bcrypt)
	endif()

	if(BUILD_SHARED_LIBS)
		set_target_properties(xml2 PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_BIN_DIR}/${ST_XML2_SHARED}"
			# Ignored on non-WIN32 platforms
			 IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_XML2_IMPLIB}"
		)
	else()
		set_target_properties(xml2 PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_XML2_STATIC}"
		)
	endif()

	add_dependencies(xml2 ${XML2-EXTERN})
	set(LIB_XML2 xml2)

endif()
