# FindLibCXX.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# Find TARGETS
#   LibCXX::LibCXX
#

find_library(LIBCXX_LIBRARY NAMES c++)
find_library(LIBCXX_ABI_LIBRARY NAMES c++abi)
find_path(LIBCXX_INCLUDE_DIR NAMES "__cxxabi_config.h" PATH_SUFFIXES "c++/v1")

if(LIBCXX_INCLUDE_DIR)
    file(READ "${LIBCXX_INCLUDE_DIR}/__config" LIBCXX_CONFIG)
    set(LIBCXX_VER_REGEX "^#\s+define\s+_LIBCPP_VERSION\s+(\d)(\d)(\d)(\d)+")
    string(REGEX MATCH ${LIBCXX_VER_REGEX} LIBCXX_VER_SUBSTR ${LIBCXX_CONFIG})
    string(REGEX REPLACE ${LIBCXX_VER_REGEX} "\\1.\\2.\\3.\\4" LIBCXX_VERSION_STRING ${LIBCXX_VER_SUBSTR})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  TRNG
  REQUIRED_VARS
    LIBCXX_LIBRARY
    LIBCXX_ABI_LIBRARY
    LIBCXX_INCLUDE_DIR
  VERSION_VAR
    LIBCXX_VERSION_STRING
)

mark_as_advanced( LIBCXX_LIBRARY
                  LIBCXX_ABI_LIBRARY
                  LIBCXX_INCLUDE_DIR
                  LIBCXX_VERSION_STRING)

add_library(LibCXX::LibCXX SHARED IMPORTED)
set_target_properties(LibCXX::LibCXX PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES CXX
        IMPORTED_LOCATION ${LIBCXX_LIBRARY}
        INTERFACE_COMPILE_OPTIONS $<$<CXX_COMPILER_ID:GNU>:-nostdinc++> $<$<CXX_COMPILER_ID:Clang>:-stdlib=libc++>
        INTERFACE_LINK_LIBRARIES ${LIBCXX_ABI_LIBRARY} $<$<CXX_COMPILER_ID:GNU>:-nodefaultlibs -lm -lc -lgcc_s -lgcc>
        INTERFACE_INCLUDE_DIRECTORIES ${LIBCXX_INCLUDE_DIR})
