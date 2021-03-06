message(STATUS "LAPACKE enable")

option(LAPACKE_STANDALONE_BUILD "Build liblapacke only" ON)

if (LAPACKE_STANDALONE_BUILD)
  cmake_minimum_required(VERSION 2.8.12)
  project(lapacke C)
else (LAPACKE_STANDALONE_BUILD)
  enable_language(C)
  set(LAPACK_INSTALL_EXPORT_NAME lapacke-targets)
  
  # Create a header file lapacke_mangling.h for the routines called in my C programs
  include(FortranCInterface)
  ## Ensure that the fortran compiler and c compiler specified are compatible
  FortranCInterface_VERIFY()
  FortranCInterface_HEADER(${LAPACK_BINARY_DIR}/include/lapacke_mangling.h
    MACRO_NAMESPACE "LAPACK_"
    SYMBOL_NAMESPACE "LAPACK_")
  if(NOT FortranCInterface_GLOBAL_FOUND OR NOT FortranCInterface_MODULE_FOUND)
    message(WARNING "Reverting to pre-defined include/lapacke_mangling.h")
    configure_file(include/lapacke_mangling_with_flags.h.in
                   ${LAPACK_BINARY_DIR}/include/lapacke_mangling.h)
  endif()
  
  include_directories(include ${LAPACK_BINARY_DIR}/include)
endif (LAPACKE_STANDALONE_BUILD)

add_subdirectory(include)
add_subdirectory(src)
add_subdirectory(utils)

option(LAPACKE_BUILD_SINGLE "Build LAPACKE single precision real" ON)
option(LAPACKE_BUILD_DOUBLE "Build LAPACKE double precision real" ON)
option(LAPACKE_BUILD_COMPLEX "Build LAPACKE single precision complex" ON)
option(LAPACKE_BUILD_COMPLEX16 "Build LAPACKE double precision complex" ON)

macro(append_subdir_files variable dirname)
  get_directory_property(holder DIRECTORY ${dirname} DEFINITION ${variable})
  foreach(depfile ${holder})
    list(APPEND ${variable} "${dirname}/${depfile}")
  endforeach()
endmacro()

message(STATUS "Build LAPACKE single precision real: ${LAPACKE_BUILD_SINGLE}")
message(STATUS "Build LAPACKE double precision real: ${LAPACKE_BUILD_DOUBLE}")
message(STATUS "Build LAPACKE single precision complex: ${LAPACKE_BUILD_COMPLEX}")
message(STATUS "Build LAPACKE double precision complex: ${LAPACKE_BUILD_COMPLEX16}")

append_subdir_files(LAPACKE_INCLUDE "include")
append_subdir_files(SOURCES "src")
if (LAPACKE_BUILD_SINGLE)
  append_subdir_files(SOURCES_SINGLE "src")
  list(APPEND SOURCES ${SOURCES_SINGLE})
endif()
if (LAPACKE_BUILD_DOUBLE)
  append_subdir_files(SOURCES_DOUBLE "src")
  list(APPEND SOURCES ${SOURCES_DOUBLE})
endif()
if (LAPACKE_BUILD_COMPLEX)
  append_subdir_files(SOURCES_COMPLEX "src")
  list(APPEND SOURCES ${SOURCES_COMPLEX})
endif()
if (LAPACKE_BUILD_COMPLEX16)
  append_subdir_files(SOURCES_COMPLEX16 "src")
  list(APPEND SOURCES ${SOURCES_COMPLEX16})
endif()
append_subdir_files(DEPRECATED "src")
append_subdir_files(EXTENDED "src")
append_subdir_files(MATGEN "src")
append_subdir_files(UTILS "utils")

if(BUILD_DEPRECATED)
  list(APPEND SOURCES ${DEPRECATED})
endif()
if(USE_XBLAS)
  list(APPEND SOURCES ${EXTENDED})
endif()
if(LAPACKE_WITH_TMG)
  list(APPEND SOURCES ${MATGEN})
endif()
list(APPEND SOURCES ${UTILS})

add_library(lapacke ${SOURCES})
set_target_properties(
  lapacke PROPERTIES
  LINKER_LANGUAGE C
  VERSION ${LAPACK_VERSION}
  SOVERSION ${LAPACK_MAJOR_VERSION}
  )
target_include_directories(lapacke PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)
if(WIN32 AND NOT UNIX)
  target_compile_definitions(lapacke PUBLIC HAVE_LAPACK_CONFIG_H LAPACK_COMPLEX_STRUCTURE)
  message(STATUS "Windows BUILD")
endif()

if(LAPACKE_WITH_TMG)
  target_link_libraries(lapacke PRIVATE tmglib)
endif()
target_link_libraries(lapacke PRIVATE ${LAPACK_LIBRARIES})

if (NOT LAPACKE_STANDALONE_BUILD)
  lapack_install_library(lapacke)
  install(
    FILES ${LAPACKE_INCLUDE} ${LAPACK_BINARY_DIR}/include/lapacke_mangling.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT Development
    )
endif (NOT LAPACKE_STANDALONE_BUILD)

if(BUILD_TESTING)
  add_subdirectory(example)
endif()

if (NOT LAPACKE_STANDALONE_BUILD)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/lapacke.pc.in ${CMAKE_CURRENT_BINARY_DIR}/lapacke.pc @ONLY)
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/lapacke.pc
    DESTINATION ${PKG_CONFIG_DIR}
    COMPONENT Development
    )
  
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/lapacke-config-version.cmake.in
    ${LAPACK_BINARY_DIR}/lapacke-config-version.cmake @ONLY)
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/lapacke-config-build.cmake.in
    ${LAPACK_BINARY_DIR}/lapacke-config.cmake @ONLY)
  
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/lapacke-config-install.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/lapacke-config.cmake @ONLY)
  install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/lapacke-config.cmake
    ${LAPACK_BINARY_DIR}/lapacke-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/lapacke-${LAPACK_VERSION}
    COMPONENT Development
    )
  
  install(EXPORT lapacke-targets
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/lapacke-${LAPACK_VERSION}
    COMPONENT Development
    )
endif (NOT LAPACKE_STANDALONE_BUILD)
