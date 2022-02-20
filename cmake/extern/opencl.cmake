# SPDX-FileCopyrightText: © 2022 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

## TODO: This needs a rework. Also find out, if we can get opencl to work on MinGW and other platforms 
IF(MSVC)
	INCLUDE(FindOpenCL)
	IF(NOT OpenCL_FOUND)
	  FIND_LIBRARY(
		 OpenCL_LIBRARY NAMES opencl libopencl
		 PATHS "${build_outer_dir}/opencl"
		 DOC "Local OpenCL library path"
	  )

	  FIND_PATH(
		 OpenCL_INCLUDE_DIR NAMES opencl.h cl.h cl.hpp
		 PATHS "${build_outer_dir}/opencl/cl"
		 DOC "Local OpenCL include path"
	  )

	  IF(OpenCL_LIBRARY AND OpenCL_INCLUDE_DIR)
	  SET(OpenCL_FOUND ON)
	  INCLUDE_DIRECTORIES("${OpenCL_INCLUDE_DIR}")
	  ENDIF()
	ENDIF()
ENDIF(MSVC)


