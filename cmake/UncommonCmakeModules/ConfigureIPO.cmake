# FindTRNG.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENCE
#
# Find the TRNG (Tina's Random Number Generator Library)
# GIT: https://github.com/rabauke/trng4.git
# URL: https://www.numbercrunch.de/trng/
include(CheckIPOSupported)
check_ipo_supported(RESULT IPO_SUPPORTED OUTPUT IPO_SUPPORTED_ERROR)

if( IPO_SUPPORTED )
    message(STATUS "IPO / LTO enabled")
    set_property(DIRECTORY PROPERTY INTERPROCEDURAL_OPTIMIZATION ON) 
else()
    message(STATUS "IPO / LTO not supported: <${IPO_SUPPORTED_ERROR}>")
endif()
# 
