# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

find_package(Eigen QUIET)

if(Eigen_FOUND)

	message(STATUS "Found Eigen: ${EIGEN_INCLUDE_DIRS}")

else()

	set(HAVE_DEPENDENCIES FALSE)
	
	# Try to download Eigen3 and extract it so find_package() can find it if needed
	if(NOT EXISTS " ${EXTERN}/src/eigen-3.4.0")
		file(DOWNLOAD https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip
			${DOWNLOAD_DIR}/eigen-3.4.0.zip
			EXPECTED_HASH SHA256=1ccaabbfe870f60af3d6a519c53e09f3dcf630207321dffa553564a8e75c4fc8
			SHOW_PROGRESS
		)
		file(ARCHIVE_EXTRACT
			INPUT ${DOWNLOAD_DIR}/eigen-3.4.0.zip
			DESTINATION ${EXTERN}/src
		)
	endif()
	
	set(EIGEN_INCLUDE_DIR_HINTS ${EXTERN}/src/eigen-3.4.0 CACHE FILEPATH "Eigen include dir hint" FORCE)
endif()
