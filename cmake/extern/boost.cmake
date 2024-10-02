# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# Suppress a warning
set(Boost_NO_WARN_NEW_VERSIONS 1)

if(POLICY CMP0167)
	# Use BoostConfig.cmake (since 1.70) from boost itself instead of the FindBoost package from cmake
	cmake_policy(SET CMP0167 NEW)
endif()
if(POLICY CMP0144)
	# Use BOOST_ROOT Variable
	cmake_policy(SET CMP0144 NEW)
endif()


if(NOT WIN32 AND BUILD_SHARED_LIBS)

	find_package(Boost REQUIRED COMPONENTS test_exec_monitor unit_test_framework)
	
else() # Local static build
	
	set(Boost_USE_STATIC_LIBS ON)
	set(Boost_USE_STATIC_RUNTIME ON)
	
	# Instead of manually searching for the library files, we let find_package() do it.
	# Set search directory hint
	if(EXISTS ${EXTERN}/lib/cmake/Boost-1.86.0)

		set(BOOST_ROOT ${EXTERN})
		find_package(Boost REQUIRED COMPONENTS test_exec_monitor unit_test_framework)	
	
	else() # Boost has not been built yet. Configure for build.
	
		message(STATUS "Boost has not been fully built yet. "
							"After the first build without errors, just rerun the cmake configuration and "
							"generation steps and it should find Boost and build fine.")
		set(HAVE_DEPENDENCIES FALSE)
		
		set(BOOST_64BIT_FLAGS "")
		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			list(APPEND BOOST_64BIT_FLAGS "address-model=64")
		endif()
		
		set(BOOST_TOOLSET msvc)	# Assume MSVC
		set(BOOST_BOOTSTRAP "bootstrap")

		if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
			 CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
			set(BOOST_TOOLSET clang)
		elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
			set(BOOST_TOOLSET gcc)
		endif()	# MSVC is assumed and set above
		
		if(UNIX)
			set(BOOST_BOOTSTRAP "./bootstrap.sh")
		endif()
				
		ExternalProject_Add(
			boost-extern
			PREFIX ${EXTERN}
			URL https://archives.boost.io/release/1.86.0/source/boost_1_86_0.7z
			URL_HASH SHA256=413ee9d5754d0ac5994a3bf70c3b5606b10f33824fdd56cf04d425f2fc6bb8ce
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			CONFIGURE_COMMAND ""
			BUILD_COMMAND ""  # All steps are done below because of working directory
			INSTALL_COMMAND ""
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
		)
				
		## Consider switching to an in source tree build. This below is tedious.
		# Boost needs the cwd to be its source dir but ExernelProject_Add() uses
		# <BINARY_DIR>. For out of source tree builds, we have to add extra steps.
		ExternalProject_Add_Step(boost-extern bootstrap
			DEPENDEES configure
			DEPENDERS build
			COMMAND ${BOOST_BOOTSTRAP} ${BOOST_TOOLSET}
			WORKING_DIRECTORY <SOURCE_DIR>
		)
		
		ExternalProject_Add_Step(boost-extern b2
			DEPENDEES bootstrap
			DEPENDERS install
			COMMAND ./b2 --with-test toolset=${BOOST_TOOLSET} threading=multi link=static runtime-link=static variant=release ${BOOST_64BIT_FLAGS} --build-dir=<BINARY_DIR> --stagedir=${EXTERN}
			WORKING_DIRECTORY <SOURCE_DIR>
		)

	endif()
endif()

set(LIB_BOOST Boost_LIBRARIES)
list(APPEND ALL_EXTERN_INC_DIRS ${Boost_INCLUDE_DIR})
add_definitions(-DBOOST_MULTI_INDEX_DISABLE_SERIALIZATION)
