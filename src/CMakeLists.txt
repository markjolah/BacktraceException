#
# BacktraceException
#

set(HDRS BacktraceException.h)

set(SRCS BacktraceException.cpp)

if(BUILD_SHARED_LIBS)
    add_library(${PROJECT_NAME} SHARED ${SRCS})
    set(LIB_TARGETS ${PROJECT_NAME})
endif()

if(BUILD_STATIC_LIBS)
    add_library(${PROJECT_NAME}_static STATIC ${SRCS})
    set(LIB_TARGETS ${LIB_TARGETS} ${PROJECT_NAME}_static)
    set_target_properties(${PROJECT_NAME}_static PROPERTIES OUTPUT_NAME ${PROJECT_NAME})
endif()
foreach(target ${LIB_TARGETS})
    target_compile_features(${target} PUBLIC cxx_std_11) #Declare C++11 required for building
    set_target_properties(${target} PROPERTIES PUBLIC_HEADER "${HDRS}")
    target_include_directories(${target} INTERFACE $<INSTALL_INTERFACE:include>)
endforeach()

install(TARGETS ${LIB_TARGETS} EXPORT ${EXPORT_TARGETS_NAME}
        LIBRARY DESTINATION lib COMPONENT Runtime
        ARCHIVE DESTINATION lib COMPONENT Development
        PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
