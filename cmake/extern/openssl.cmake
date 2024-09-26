# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only


if(NOT WIN32 AND NOT STATIC_BUILD)

	find_package(OpenSSL REQUIRED)
	set(LIB_SSL OpenSSL::SSL)
	list(APPEND ALL_EXTERN_INC_DIRS ${OPENSSL_INCLUDE_DIRS})
	
else() # Local build, only static
	
	if(MSVC)
		set(OPENSSL_SOURCE_DIR ${EXTERN}/src/openssl-extern-static)
		set(OPENSSL_CONFIGURE_COMMAND d:/devel/perl5.38/perl/bin/perl.exe ${OPENSSL_SOURCE_DIR}/Configure VC-WIN64A)
		set(OPENSSL_BUILD_COMMAND nmake)
		set(OPENSSL_TEST_COMMAND nmake test)
		set(OPENSSL_INSTALL_COMMAND nmake install)
	endif()

	ExternalProject_Add(
		openssl-extern-static
		PREFIX ${EXTERN}
		URL https://github.com/openssl/openssl/releases/download/openssl-3.3.2/openssl-3.3.2.tar.gz
		URL_HASH SHA256=2e8a40b01979afe8be0bbfb3de5dc1c6709fedb46d6c89c10da114ab5fc3d281
		CONFIGURE_COMMAND
			${OPENSSL_CONFIGURE_COMMAND}
			--prefix=${EXTERN}
			no-apps
			no-shared
		BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
		TEST_COMMAND ${OPENSSL_TEST_COMMAND}
		INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
		UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
	)
	
	
	# TODO: Check that these filenames are correct.
	if(MSVC)
		set(ST_SSL_STATIC "libssl.lib")
		set(ST_CRYP_STATIC "libcrypto.lib")
	else()
		set(ST_SSL_STATIC "libssl.a")
		set(ST_CRYP_IMPLIB "libcrypto.a")
	endif()
	
	
	# We can't use the external target directly (utility target), so 
	# create a new target and depend it on the external target.
	add_library(openssl-static STATIC IMPORTED)
	add_library(crypto-static STATIC IMPORTED)

	set_property(
		TARGET openssl-static crypto-static APPEND PROPERTY IMPORTED_CONFIGURATIONS $<CONFIG>
	)
	
	
	# Static properties
	set_target_properties(openssl-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_SSL_STATIC}"
	)
	set_target_properties(crypto-static PROPERTIES
		MAP_IMPORTED_CONFIG_DEBUG Release
		MAP_IMPORTED_CONFIG_MINSIZEREL Release
		MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
		IMPORTED_LOCATION "${EXTERN_LIB_DIR}/${ST_CRYP_STATIC}"
	)
	
	add_dependencies(openssl-static openssl-extern)
	add_dependencies(crypto-static openssl-extern)
	
	set(LIB_SSL openssl-static)
	set(LIB_CRYP crypto-static)

endif()
