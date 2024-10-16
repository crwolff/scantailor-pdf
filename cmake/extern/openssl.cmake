# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(OpenSSL REQUIRED)
	# list(APPEND ALL_EXTERN_INC_DIRS ${OPENSSL_INCLUDE_DIRS})
	
else() # Local build, only static
	
	# Check if we built the package already
	find_package(OpenSSL
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(OpenSSL_FOUND)

		message(STATUS "Found OpenSSL in ${OpenSSL_DIR}")
		# Needed for dependency satisfaction after external project has been built
		add_custom_target(openssl-extern DEPENDS OpenSSL::Crypto OpenSSL::SSL)

	else()	# OpenSSLhas not been built yet. Configure for build.
	
		set(HAVE_DEPENDENCIES FALSE)

		# Find Perl if Windows and not in MSYS
		if(MSVC)
			get_filename_component(
				ActivePerl_CurrentVersion
				"[HKEY_LOCAL_MACHINE\\SOFTWARE\\ActiveState\\ActivePerl;CurrentVersion]"
				NAME)
			set(ST_PERL_PATH
				${ST_PERL_PATH}
				"C:/Perl/bin"
				"C:/Strawberry/perl/bin"
				[HKEY_LOCAL_MACHINE\\SOFTWARE\\ActiveState\\ActivePerl\\${ActivePerl_CurrentVersion}]/bin
			)
			
			find_program(PERL_EXECUTABLE
				NAMES perl
				PATHS ${ST_PERL_PATH}
				REQUIRED
			)
		else()
			set(PERL_EXECUTABLE perl)
		endif()
		
		
		# Find number of available threads for multithreaded compilation of QT5
		include(ProcessorCount)
		ProcessorCount(N)
		math(EXPR THREADS "${N} - 1")
		if(NOT N EQUAL 0)
			set(JX "-j${THREADS}")
		endif()
		
		set(OPENSSL_SOURCE_DIR ${EXTERN}/src/openssl-extern)
		if(MSVC)
			set(OPENSSL_CONFIGURE_COMMAND ${PERL_EXECUTABLE} ${OPENSSL_SOURCE_DIR}/Configure VC-WIN64A)
			set(OPENSSL_BUILD_COMMAND nmake /C /S)
			set(OPENSSL_INSTALL_COMMAND nmake install)
		elseif(MINGW)
			set(OPENSSL_CONFIGURE_COMMAND perl ${OPENSSL_SOURCE_DIR}/Configure mingw64)
			set(OPENSSL_BUILD_COMMAND mingw32-make ${JX})
			set(OPENSSL_INSTALL_COMMAND mingw32-make install)
		else()
			set(OPENSSL_CONFIGURE_COMMAND ${OPENSSL_SOURCE_DIR}/Configure)
			set(OPENSSL_BUILD_COMMAND make ${JX})
			set(OPENSSL_INSTALL_COMMAND make install)
		endif()

		set(ssl-static)
		if(NOT BUILD_SHARED_LIBS)
			set(ssl-static no-shared)
		endif()

		ExternalProject_Add(
			openssl-extern
			PREFIX ${EXTERN}
			URL https://github.com/openssl/openssl/releases/download/openssl-3.3.2/openssl-3.3.2.tar.gz
			URL_HASH SHA256=2e8a40b01979afe8be0bbfb3de5dc1c6709fedb46d6c89c10da114ab5fc3d281
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			CONFIGURE_COMMAND
				${OPENSSL_CONFIGURE_COMMAND}
				--prefix=<INSTALL_DIR>
				--openssldir=<INSTALL_DIR>/SSL
				--libdir=lib
				--release
				no-apps
				${ssl-static}
				no-tests
				no-docs
			BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
			TEST_COMMAND ""
			INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)

	endif()
endif()
