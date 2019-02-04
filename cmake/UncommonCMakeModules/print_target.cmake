# print_target.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Useful debugging routines

macro(print_target target)
    message(STATUS "[TARGET: ${target} Properties]")
    get_property(_VAR TARGET ${target} PROPERTY INCLUDE_DIRECTORIES)
    message(STATUS "  >${target} INCLUDE_DIRECTORIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "  >${target} INTERFACE_INCLUDE_DIRECTORIES: ${_VAR}")    
    get_property(_VAR TARGET ${target} PROPERTY LINK_LIBRARIES)
    message(STATUS "  >${target} LINK_LIBRARIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES)
    message(STATUS "  >${target} INTERFACE_LINK_LIBRARIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY COMPILE_FEATURES)
    message(STATUS "  >${target} COMPILE_FEATURES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_COMPILE_FEATURES)
    message(STATUS "  >${target} INTERFACE_COMPILE_FEATURES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY COMPILE_OPTIONS)
    message(STATUS "  >${target} COMPILE_OPTIONS: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_COMPILE_OPTIONS)
    message(STATUS "  >${target} INTERFACE_COMPILE_OPTIONS: ${_VAR}")
    message(STATUS "")
endmacro()

macro(print_interface_target target)
    message(STATUS "[TARGET: ${target} Interface Properties]")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "  >${target} INTERFACE_INCLUDE_DIRECTORIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_LINK_LIBRARIES)
    message(STATUS "  >${target} INTERFACE_LINK_LIBRARIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_LINK_DIRECTORIES)
    message(STATUS "  >${target} INTERFACE_LINK_DIRECTORIES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_LINK_OPTIONS)
    message(STATUS "  >${target} INTERFACE_LINK_OPTIONS: ${_VAR}")


    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_COMPILE_FEATURES)
    message(STATUS "  >${target} INTERFACE_COMPILE_FEATURES: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_COMPILE_OPTIONS)
    message(STATUS "  >${target} INTERFACE_COMPILE_OPTIONS: ${_VAR}")
    get_property(_VAR TARGET ${target} PROPERTY INTERFACE_COMPILE_DEFINITIONS)
    message(STATUS "  >${target} INTERFACE_COMPILE_DEFINITIONS: ${_VAR}")
    message(STATUS "")
endmacro()

