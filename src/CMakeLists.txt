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
                            RETURN_TARGETS libs
                            RETURN_SHARED_TARGET shared_lib)

if(UNIX)
    #For backtraces to be useful must export all symbols
    if(${CMAKE_VERSION} VERSION_GREATER "3.13.0")
        target_link_options(${shared_lib} INTERFACE -rdynamic)
    else()
        set_property(TARGET ${shared_lib} APPEND PROPERTY INTERFACE_LINK_LIBRARIES -rdynamic) #Older CMAKE don't have INTERFACE_LINK_OPTIONS
    endif()
endif()
