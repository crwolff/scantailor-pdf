# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# Try searching for Eigen in system
find_package(Eigen3 NO_MODULE QUIET)

if(TARGET Eigen3::Eigen)

	message(STATUS "Found Eigen")
	# Use target Eigen3::Eigen to link against

else()
	## Make Eigen available ourselves
	# Check if we built the package already
	find_package(Eigen3
		NO_MODULE				# Don't use installed modules for the search
		NO_DEFAULT_PATH		# Only search in ${EXTERN}
		HINTS ${EXTERN}
		QUIET
	)

	if(TARGET Eigen3::Eigen)

		message(STATUS "Found Eigen")
		# Use target Eigen3::Eigen to link against

	else()

		set(HAVE_DEPENDENCIES FALSE)
	
		# Try to download Eigen3 and extract it so find_package() can find it if needed
		ExternalProject_Add(
			eigen-extern
			URL https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip
			URL_HASH SHA256=1ccaabbfe870f60af3d6a519c53e09f3dcf630207321dffa553564a8e75c4fc8
			DOWNLOAD_DIR ${DOWNLOAD_DIR}
			PREFIX ${EXTERN}
			CMAKE_ARGS
				-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
				-DCMAKE_PREFIX_PATH=<INSTALL_DIR>
				-DCMAKE_BUILD_TYPE=Release
			UPDATE_COMMAND ""  # Don't rebuild on main project recompilation
			DEPENDS boost-extern
		)

	endif()
endif()
