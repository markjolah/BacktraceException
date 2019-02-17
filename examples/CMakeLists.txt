# BacktraceException/examples
# build, but don't install examples

file(GLOB EXAMPLE_SRCS *.cpp)
foreach(_src IN LISTS EXAMPLE_SRCS)
    get_filename_component(_target ${_src} NAME_WE)
    add_executable(${_target} ${_src})
    target_link_libraries(${_target} BacktraceException::BacktraceException)
endforeach()
