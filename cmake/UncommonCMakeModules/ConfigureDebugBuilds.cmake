# ConfigureDebugBuilds.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2018
# see file: LICENSE
#
# Configure common debugging flags and definitions for debug builds only.
#
# Controlling options:
#  OPT_DEBUG - If defined and disabled some more noisy options will be disabled.
#              These options default to ON if not OPT_DEBUG is defined.
#

#No optimization for debugging
add_compile_options($<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-O0>)

#Add warnings for debug configurations
add_compile_options($<$<CONFIG:Debug>:-W>)
add_compile_options($<$<CONFIG:Debug>:-Wall>)
add_compile_options($<$<CONFIG:Debug>:-Wextra>)

if(NOT DEFINED OPT_DEBUG OR OPT_DEBUG)
    set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:DEBUG>)
endif()

#Set the global debug postfix for libraries and executables
set(CMAKE_DEBUG_POSTFIX ".debug" CACHE STRING "Debug file extension")

#Limit # of errors reported by gcc
add_compile_options($<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU>>:-fmax-errors=5>)
