# BacktraceException/src
# Main CMake for BacktraceException libraries


set(SRCS BacktraceException.cpp)
set(PUBLIC_HEADER_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/../include)

include(AddSharedStaticLibraries)
add_shared_static_libraries("${SRCS}" BacktraceException) 

foreach(target ${LIB_TARGETS})
    target_compile_features(${target} PUBLIC cxx_std_11)
    target_include_directories(${target} PUBLIC $<BUILD_INTERFACE:${PUBLIC_HEADER_SRC_DIR}> 
                                                $<INSTALL_INTERFACE:include>)
    target_link_libraries(${target} PUBLIC Boost::iostreams)
    if(WIN32)
        target_compile_definitions(${target} PRIVATE WIN32)
    elseif(UNIX AND NOT APPLE)
        target_compile_definitions(${target} PRIVATE LINUX)
    endif()
endforeach()

install(TARGETS ${LIB_TARGETS} EXPORT ${PROJECT_NAME}Targets
        LIBRARY DESTINATION lib COMPONENT Runtime
        ARCHIVE DESTINATION lib COMPONENT Development)

install(DIRECTORY ${PUBLIC_HEADER_SRC_DIR}/ DESTINATION include COMPONENT Development)
