include_directories(BEFORE ..)

set(
	sources
	${CMAKE_SOURCE_DIR}/src/tests/main.cpp
	TestHessians.cpp
)

source_group("Sources" FILES ${sources})

set(
	libs
	math ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY}
	${Boost_PRG_EXECUTION_MONITOR_LIBRARY} ${EXTRA_LIBS}
)

add_executable(adiff_tests ${sources})
target_link_libraries(adiff_tests ${libs})

if(NOT STATIC_BUILD)
	# We want the executable located where we copy all the DLLs.
	set_target_properties(
		adiff_tests PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
	)
endif()

add_test(NAME adiff_tests COMMAND adiff_tests --log_level=message)
