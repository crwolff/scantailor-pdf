# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(OpenSSL REQUIRED)
	set(LIB_SSL OpenSSL::SSL)
	list(APPEND ALL_EXTERN_INC_DIRS ${OPENSSL_INCLUDE_DIRS})
	
else() # Local build, only static
	
	# Find Perl if Windows and not in MSYS
	if(MSVC)
		get_filename_component(
			ActivePerl_CurrentVersion
			"[HKEY_LOCAL_MACHINE\\SOFTWARE\\ActiveState\\ActivePerl;CurrentVersion]"
			NAME)
		set(ST_PERL_PATH ${ST_PERL_PATH}
			"C:/Perl/bin"
			"C:/Strawberry/perl/bin"
			[HKEY_LOCAL_MACHINE\\SOFTWARE\\ActiveState\\ActivePerl\\${ActivePerl_CurrentVersion}]/bin
		)
		
		# Append custom perl
		list(APPEND ST_PERL_PATH "d:/devel/perl-5.32p/perl/bin/")
		list(APPEND ST_PERL_PATH "d:/devel/perl5.38/perl/bin/")
		
		find_program(PERL_EXECUTABLE
			NAMES perl
			PATHS ${ST_PERL_PATH}
		)
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
			no-shared
			no-tests
			no-docs
		BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
		TEST_COMMAND ""
		INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_SSL_STATIC "libssl.lib")		#checked
		set(ST_CRYP_STATIC "libcrypto.lib")	#checked
	else()
		set(ST_SSL_STATIC "libssl.a")
		set(ST_CRYP_IMPLIB "libcrypto.a")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(openssl STATIC IMPORTED)
	add_library(crypto STATIC IMPORTED)
	
	set_target_properties(openssl crypto PROPERTIES
		IMPORTED_CONFIGURATIONS $<CONFIG>
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		INTERFACE_INCLUDE_DIRECTORIES ${EXTERN_INC_DIR}/openssl
	)
	set_target_properties(openssl PROPERTIES
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_SSL_STATIC}"
	)
	set_target_properties(crypto PROPERTIES
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_CRYP_STATIC}"
	)
	
	add_dependencies(openssl openssl-extern)
	add_dependencies(crypto openssl-extern)
	
	set(LIB_SSL openssl)
	set(LIB_CRYP crypto)

endif()
