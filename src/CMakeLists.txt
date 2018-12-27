# BacktraceException/src
# Main CMake for BacktraceException libraries

set(SRCS BacktraceException.cpp)

include(AddSharedStaticLibraries)
# add_shared_static_libraries()
# * Add shared and static library targets to project namespace
# * Sets target_include_directories
# * Sets target_compile_features and target_link_libraries
# * Installs target libraries and headers
# * returns lsit SHARED_STATIC_LIB_TARGETS of created targets for adjusting additional target properties
add_shared_static_libraries(SOURCES ${SRCS}
                            COMPILE_FEATURES cxx_std_11
                            PUBLIC_HEADER_DIR ${CMAKE_SOURCE_DIR}/include
                            RETURN_TARGETS libs)
message(STATUS "Got libs:${libs}")
foreach(lib IN LISTS libs)
    target_link_options(${lib} INTERFACE -rdynamic) #For backtraces to be usefull must export all symbols
endforeach()
