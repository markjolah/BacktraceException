# BacktraceException/test

set(TEST_SRCS testBacktraceException.cpp)

set(TEST_EXE testBacktraceException)
add_executable(${TEST_EXE} ${TEST_SRCS})
target_link_libraries(${TEST_EXE} BacktraceException::BacktraceException)
target_link_options(${TEST_EXE} PRIVATE $<$<CONFIG:Debug>:-rdynamic>)
