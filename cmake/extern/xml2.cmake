# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(LibXml2 REQUIRED)		# This only finds shared libs
	
else() # Local build
	
	# Check if we built the package already
	find_package(LibXml2
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(LibXml2_FOUND)

		# Use target LibXml2::LibXml2

		message(STATUS "Found LibXml2 in ${LibXml2_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(xml2-extern DEPENDS LibXml2::LibXml2)

	else()	# LibXml2 has not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		ExternalProject_Add(
			xml2-extern
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
		
		# podofo under msvc can't find libxml2s.lib; create hardlink from static lib to shared name
		if(NOT BUILD_SHARED_LIBS AND MSVC)
			ExternalProject_Add_Step(
				xml2-extern podofo-compat-install
				DEPENDEES install
				# create a hardlink with the name of the shared implib
				COMMAND ${CMAKE_COMMAND} -E create_hardlink ${EXTERN_LIB_DIR}/libxml2s.lib ${EXTERN_LIB_DIR}/libxml2.lib
			)
		endif()

	endif()
endif()
