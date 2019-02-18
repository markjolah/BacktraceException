# FindTRNG.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENSE
#
# Find the TRNG (Tina's Random Number Generator Library)
# GIT: https://github.com/rabauke/trng4.git
# URL: https://www.numbercrunch.de/trng/
find_path(TRNG_INCLUDE_DIR NAMES trng/lcg64.hpp PATHS ${TRNG_PREFIX_HINTS} PATH_SUFFIXES include)
find_library(TRNG_LIBRARY NAMES trng4 PATHS ${TRNG_PREFIX_HINTS} PATH_SUFFIXES lib lib64)

if(TRNG_INCLUDE_DIR)
    file(READ ${TRNG_INCLUDE_DIR}/trng/config.hpp TRNG_CONFIG)
    set(TRNG_VER_REGEX "TRNG_VERSION [0-9]+\\.[0-9]+")
    string(REGEX MATCH ${TRNG_VER_REGEX} TRNG_VER_SUBSTR ${TRNG_CONFIG})
    string(SUBSTRING ${TRNG_VER_SUBSTR} 13 -1 TRNG_VERSION_STRING)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
  TRNG
  REQUIRED_VARS
    TRNG_LIBRARY
    TRNG_INCLUDE_DIR
  VERSION_VAR
    TRNG_VERSION_STRING
)

mark_as_advanced(TRNG_INCLUDE_DIR
                 TRNG_LIBRARY
                 TRNG_VERSION_STRING)

if(TRNG_FOUND AND NOT TARGET TRNG::TRNG)
    get_filename_component(_lib_dir ${TRNG_LIBRARY} DIRECTORY)
    add_library(TRNG::TRNG INTERFACE IMPORTED)
    set_target_properties(TRNG::TRNG PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES ${TRNG_INCLUDE_DIR}
        INTERFACE_LINK_LIBRARIES ${TRNG_LIBRARY})
    unset(_lib_dir)
endif()
