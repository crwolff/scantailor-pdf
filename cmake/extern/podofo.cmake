# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(podofo REQUIRED)
	add_library(podofo ALIAS podofo_shared)
	
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
			add_library(podofo ALIAS podofo_shared)
			target_link_libraries(podofo_shared INTERFACE OpenSSL::Crypto Freetype::Freetype)
		else()
			add_library(podofo ALIAS podofo_static)
			set_target_properties(podofo_static podofo_private PROPERTIES
				INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/podofo
				INTERFACE_COMPILE_DEFINITIONS PODOFO_STATIC
			)
			# Fix podofo not linking against OpenSSL::Crypto
			target_link_libraries(podofo_static INTERFACE OpenSSL::Crypto Freetype::Freetype)
		endif()

	
		message(STATUS "Found PoDoFo in ${podofo_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(podofo-extern DEPENDS podofo)


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
				-DZLIB_USE_STATIC_LIBS=${ZLIB_USE_STATIC_LIBS}
			BUILD_COMMAND
				${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
			INSTALL_COMMAND
				${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS zlib-extern png-extern tiff-extern freetype-extern xml2-extern lzma-extern openssl-extern
		)

	endif()
endif()
