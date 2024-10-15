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

	# Check if we built the package already
	find_package(podofo
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		PATH_SUFFIXES lib share
		QUIET
	)

	if(podofo_FOUND)
		
		if(BUILD_SHARED_LIBS)
			add_library(podofo ALIAS podofo::podofo)
		else()
			add_library(podofo ALIAS podofo_static)
			target_link_libraries(podofo_static INTERFACE OpenSSL::Crypto)
			set_target_properties(podofo_static podofo_private PROPERTIES
				INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/podofo
				INTERFACE_COMPILE_DEFINITIONS "PODOFO_STATIC"
			)
		endif()
		message(STATUS "Found PoDoFo in ${podofo_DIR}")


	else() # PoDoFo has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

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
			PATCH_COMMAND ${CMAKE_COMMAND} -E copy ${EXTERN_PATCH_DIR}/podofo/CMakeLists.txt <SOURCE_DIR>
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
				-DPODOFO_BUILD_LIB_ONLY=ON
				-DPODOFO_BUILD_STATIC=${STATIC_BOOL}
				${DISABLE_FIND_PACKAGE}
				-DCOMPILE_DEFINITIONS=LIBXML_STATIC
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS zlib_extern png-extern tiff-extern freetype-extern xml2-extern lzma-extern openssl-extern
		)

	endif()
endif()
