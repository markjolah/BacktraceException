# doc/CMakeLists.txt
# Doxygen integration adds build targets
#  -- target: make doc    #Generate Doxygen Documentation
#  -- target: make pdf    #Build pdf documentation
#
# Required dependencies:
#  * LAPACK
#  * Doxygen
#  * graphviz
#
find_package(Doxygen)
if(DOXYGEN_FOUND)
    find_package(LATEX)
    set(PDF_DOC_NAME ${PROJECT_NAME}-${PROJECT_VERSION}-reference.pdf) #Name of pdf document to produce
    set(DOC_INSTALL_DIR share/${PROJECT_NAME}/doc)
    set(DOXYGEN_MDFILE_AS_MAINPAGE ${CMAKE_SOURCE_DIR}/README.md)
    set(DOXYGEN_INPUT ${CMAKE_SOURCE_DIR}/README.md
                      ${CMAKE_SOURCE_DIR}/src/
                      ${CMAKE_SOURCE_DIR}/include/ParallelRngManager)
    string(REPLACE ";" " " DOXYGEN_INPUT "${DOXYGEN_INPUT}")

    set(DOXYGEN_PDF_DIR ${CMAKE_BINARY_DIR}/doc/html/pdf)
    set(DOXYGEN_HTML_DIR ${CMAKE_BINARY_DIR}/doc/html)
    set(DOXYGEN_PDF_NAME refman.pdf) #Output name produced by doxygen pdf process.

    find_program(PERL_BINARY perl NO_CMAKE_FIND_ROOT_PATH)
    if(PERL_BINARY)
        set(DOXYGEN_PERL_PATH ${PERL_BINARY})
    endif()

    if(DOXYGEN_DOT_FOUND)
        set(DOXYGEN_HAVE_DOT YES)
    endif()

    find_program(DIA_BINARY dia NO_CMAKE_FIND_ROOT_PATH)
    if(DIA_BINARY)
        set(DOXYGEN_DIA_PATH ${DIA_BINARY})
    endif()

    set(DOXYFILE_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in) #Doxyfile.in - main project Doxygen configuration file location
    set(DOXYFILE_OUT ${CMAKE_BINARY_DIR}/doc/Doxyfile)
    configure_file(${DOXYFILE_IN} ${DOXYFILE_OUT} @ONLY)
    add_custom_target( doc VERBATIM
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYFILE_OUT}
        DEPENDS ${DOXYFILE_OUT} ${SRC_FILES}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generate Doxygen Documentation")
    if(LATEX_FOUND)
        add_custom_target( pdf VERBATIM
            COMMAND make ${DOXYGEN_PDF_NAME}
            COMMAND mv ${DOXYGEN_PDF_NAME} ${PDF_DOC_NAME}
            DEPENDS ${DOXYGEN_PDF_DIR}/refman.tex ${DOXYGEN_PDF_DIR}/Makefile
            WORKING_DIRECTORY ${DOXYGEN_PDF_DIR}
            COMMENT "Build pdf documentation")
        add_dependencies(pdf doc)
    else()
        message(STATUS "LATEX not found disabling pdf documentation")
    endif()
    install(FILES ${DOXYGEN_PDF_DIR}/${PDF_DOC_NAME} DESTINATION ${DOC_INSTALL_DIR} COMPONENT Documentation)
    install(DIRECTORY ${DOXYGEN_HTML_DIR} DESTINATION ${DOC_INSTALL_DIR} COMPONENT Documentation)
else()
    message(WARNING "Doxygen not found. Cannot build documentation.")
endif()
