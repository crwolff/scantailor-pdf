include_directories(BEFORE ..)

set(
	sources
	"${CMAKE_SOURCE_DIR}/tests/main.cpp"
	TestCopy.cpp
	TestTranspose.cpp
	TestGaussBlur.cpp
	TestDewarp.cpp
	TestAffineTransform.cpp
	TestRenderPolynomialSurface.cpp
	TestSavGolFilter.cpp
	TestBinaryFill.cpp
	TestBinaryRasterOp.cpp
	TestHitMissTransform.cpp
	Utils.cpp Utils.h
)
source_group("Sources" FILES ${sources})

set(
	libs
	opencl dewarping imageproc math foundation
	Qt5::Core ${OpenCL_LIBRARIES}
	${Boost_UNIT_TEST_FRAMEWORK_LIBRARY}
	${Boost_PRG_EXECUTION_MONITOR_LIBRARY} ${EXTRA_LIBS}
)

add_executable(opencl_tests ${sources})
target_link_libraries(opencl_tests ${libs})

# We want the executable located where we copy all the DLLs.
set_target_properties(
	opencl_tests PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

add_test(NAME opencl_tests COMMAND opencl_tests --log_level=message)
