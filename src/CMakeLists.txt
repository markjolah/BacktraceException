#
# BacktraceException
#

set(BE_HDRS BacktraceException.h)

set(BE_SRCS BacktraceException.cpp)

add_library(BEObjects OBJECT ${BE_SRCS})
set_target_properties(BEObjects PROPERTIES POSITION_INDEPENDENT_CODE TRUE)
add_library(BEStatic STATIC $<TARGET_OBJECTS:BEObjects>)
set_target_properties(BEStatic PROPERTIES OUTPUT_NAME BacktraceException_static)
add_library(BEShared SHARED $<TARGET_OBJECTS:BEObjects>)
set_target_properties(BEShared PROPERTIES OUTPUT_NAME BacktraceException)
set_target_properties(BEStatic BEShared PROPERTIES PUBLIC_HEADER "${BE_HDRS}")


install(TARGETS BEStatic BEShared EXPORT ${EXPORT_TARGETS_NAME}
        LIBRARY DESTINATION lib COMPONENT Runtime
        ARCHIVE DESTINATION lib COMPONENT Development
        PUBLIC_HEADER DESTINATION include/${PROJECT_NAME} COMPONENT Development)
