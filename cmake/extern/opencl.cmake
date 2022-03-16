# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

find_package(OpenCL QUIET)

if(NOT OpenCL_FOUND AND MINGW)
	find_library(
		OpenCL_LIBRARY NAMES opencl opencl.a
		PATHS "${CMAKE_SOURCE_DIR}/src/acceleration/opencl/khronos"
		DOC "Local OpenCL library path"
	)

	find_path(
		OpenCL_INCLUDE_DIR NAMES opencl.h cl.h cl.hpp
		PATHS "${CMAKE_SOURCE_DIR}/src/acceleration/opencl/khronos/CL"
		DOC "Local OpenCL include path"
	)

	if(OpenCL_LIBRARY AND OpenCL_INCLUDE_DIR)
		set(OpenCL_FOUND ON)
		include_directories("${OpenCL_INCLUDE_DIR}")
		message(STATUS "Found OpenCL in ${OpenCL_LIBRARY} and ${OpenCL_INCLUDE_DIR}.")
	endif()
endif()


