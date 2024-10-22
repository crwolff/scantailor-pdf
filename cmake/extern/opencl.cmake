# SPDX-FileCopyrightText: © 2022-24 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

if(MINGW)
	# There are no official MinGW import libraries to link against; hint at our own.
	set(OpenCL_LIBRARY ${CMAKE_SOURCE_DIR}/src/acceleration/opencl/khronos/opencl.a)
	set(OpenCL_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/src/acceleration/opencl/khronos)
	find_package(OpenCL QUIET)

else()

	find_package(OpenCL QUIET)
	
endif()

if(OpenCL_FOUND)

	message(STATUS "Found OpenCL in ${OpenCL_LIBRARIES} (version ${OpenCL_VERSION_STRING})")

endif()

cmake_dependent_option(
	ENABLE_OPENCL "OpenCL may be used for acceleration of image processing" ON
	"OpenCL_FOUND" OFF
)
