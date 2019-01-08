# BacktraceException/test

set(TEST_SRCS testBacktraceException.cpp)
set(TEST_EXE testBacktraceException)
add_executable(${TEST_EXE} ${TEST_SRCS})
target_link_libraries(${TEST_EXE} BacktraceException::BacktraceException)
install(TARGETS ${TEST_EXE} RUNTIME DESTINATION bin COMPONENT development)
