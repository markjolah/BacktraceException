# AddSharedStaticLibraries.cmake
#
# Mark J. Olah (mjo@cs.unm DOT edu)
# Copyright 2017
# Licensed under the Apache License, Version 2.0
# https://www.apache.org/licenses/LICENSE-2.0
# See: LICENCE file
#
# Useage: AddSharedStaticLibraries(srcs namespace [LIBTARGET target_name] [STATIC_LIBTARGET target_name])
# srcs - The list of sources.
# namespace - The name of the namespace (without ::) intowhich the libraries will be exported
# LIBTARGET target_name - [Optional] The name of the library target to create and export (defaults to same as Namespace)
# STATIC_LIBTARGET target_name - [Optional] The name of the static library target to create 
#                                           and export when both shared and static are enabled.
#
# This function uses the options BUILD_SHARED_LIBS and BUILD_STATIC_LIBS to decide which shared or static
# versions of a library to create.  
# * BUILD_SHARED_LIBS works as expected for common cmake useage.  If "ON" then shared 
#     libraries are produced and exported.  If "OFF" then static libraries are produced and exported.
#     However, if BUILD_SHARED_LIBS is "ON" then BUILD_STATIC_LIBS can be used to simultaneously 
#     enable the build of the static libraries.  By default we build both.
# * POSITION_INDEPENDENT_CODE is enabled for static libraries by default.  This allows downstream
#     projects to link statically and be bundled into a client that is itself a shared library.  Also
#     no performance gains are likely being given up.

function(add_shared_static_libraries srcs namespace)

cmake_parse_arguments(PARSE_ARGV 2 "OPT" "" "LIBTARGET;STATIC_LIBTARGET" "")

if(OPT_LIBTARGET)
    set(libtarget ${OPT_LIBTARGET})
else()
    set(libtarget ${namespace})
endif()

if(OPT_STATIC_LIBTARGET)
    set(static_libtarget ${OPT_STATIC_LIBTARGET})
else()
    set(static_libtarget ${namespace}_static)
endif()
if(OPT_UNPARSED_ARGUMENTS)
    message(WARNING "AddSharedStaticLibrariesUnparsed: Unused arguments: ${OPT_UNPARSED_ARGUMENTS}")
endif()

set(LIB_TARGETS ${libtarget}) # List of targets to configure.  At most: the shared and static library targets.
if(BUILD_SHARED_LIBS)
    add_library(${libtarget} SHARED ${srcs})
    add_library(${namespace}::${libtarget} ALIAS ${libtarget})
    if(BUILD_STATIC_LIBS)
        add_library(${static_libtarget} STATIC ${srcs})
        add_library(${namespacee}::${static_libtarget} ALIAS ${static_libtarget})
        set_target_properties(${static_libtarget} PROPERTIES OUTPUT_NAME ${libtarget})
        set_target_properties(${static_libtarget} PROPERTIES POSITION_INDEPENDENT_CODE ON)
        list(APPEND LIB_TARGETS ${static_libtarget})
    endif()
else()
    add_library(${libtarget} STATIC ${srcs})
    add_library(${namespace}::${libtarget} ALIAS ${libtarget})
    set_target_properties(${libtarget} PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()

set(LIB_TARGETS ${LIB_TARGETS} PARENT_SCOPE ) #Return list of created library targets
endfunction()
