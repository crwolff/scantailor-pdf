# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(ZLIB REQUIRED)		# This only finds shared libs
	set(LIB_ZLIB ZLIB::ZLIB)
	list(APPEND ALL_EXTERN_INC_DIRS ${ZLIB_INCLUDE_DIRS})
	
else() # Local build

	ExternalProject_Add(
		zlib-extern
		PREFIX ${EXTERN}
		URL https://www.zlib.net/zlib-1.3.1.tar.xz
		URL_HASH SHA256=38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32
		DOWNLOAD_DIR ${DOWNLOAD_DIR}
		CMAKE_ARGS
			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
			-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
			-DCMAKE_BUILD_TYPE=Release
		BUILD_COMMAND
			${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
		INSTALL_COMMAND
			${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)	
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_ZLIB_STATIC "zlibstatic.lib")	#checked
		set(ST_ZLIB_IMPLIB "zlib.lib")		 	#checked
		set(ST_ZLIB_SHARED "zlib.dll")			#checked
	elseif(MINGW)
		set(ST_ZLIB_STATIC "libzlibstatic.a")	#checked
		set(ST_ZLIB_IMPLIB "libzlib.dll.a")		#checked
		set(ST_ZLIB_SHARED "libzlib.dll")		#checked
	elseif(APPLE)
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.dylib")
	else() # *nix and the rest
		set(ST_ZLIB_STATIC "libz.a")
		set(ST_ZLIB_SHARED "libz.so")
	endif()
	
	
	# zlib installs both shared and static libs. If building static,
	# we need to remove the shared lib, so they don't get picked up by other packages
	if(NOT BUILD_SHARED_LIBS)
		ExternalProject_Add_Step(
			zlib-extern remove-shared
			DEPENDEES install
			COMMAND ${CMAKE_COMMAND} -E rm -f ${EXTERN_BIN_DIR}/${ST_ZLIB_SHARED}
			COMMAND ${CMAKE_COMMAND} -E rm -f ${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}
		)
		if(MSVC)
			# hardlink the static lib to the shared lib name so it gets picked up by qt5 for msvc
			ExternalProject_Add_Step(
				zlib-extern qt5-compat-install
				DEPENDEES remove-shared
				COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/${ST_ZLIB_STATIC} ${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}
			)
		endif()
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(zlib ${LIB_TYPE} IMPORTED)
	set_target_properties(zlib PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}
	)

	if(BUILD_SHARED_LIBS)
		set_target_properties(zlib PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_BIN_DIR}/${ST_ZLIB_SHARED}"
			# Ignored on non-WIN32 platforms
			IMPORTED_IMPLIB "${EXTERN_LIB_DIR}/${ST_ZLIB_IMPLIB}"
		)
	else()
		set_target_properties(zlib PROPERTIES
			IMPORTED_LOCATION_RELEASE "${EXTERN_LIB_DIR}/${ST_ZLIB_STATIC}"
		)
	endif()

	add_dependencies(zlib zlib-extern)
	set(LIB_ZLIB zlib)
	add_library(ZLIB::ZLIB ALIAS zlib)

endif()
