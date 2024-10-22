# SPDX-FileCopyrightText: © 2024 Daniel Just <justibus@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

find_package(OpenGL QUIET)

if(OpenGL_FOUND)
   message(STATUS "Found OpenGL: ${OPENGL_LIBRARIES}")
endif()

cmake_dependent_option(
	ENABLE_OPENGL "OpenGL may be used for UI acceleration" ON
	"OPENGL_FOUND" OFF
)
