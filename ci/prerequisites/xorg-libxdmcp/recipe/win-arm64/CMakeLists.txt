cmake_minimum_required(VERSION 3.20)
project(libXdmcp LANGUAGES C)

include(CTest)
include(GNUInstallDirs)

if(NOT WIN32)
  message(FATAL_ERROR "This build file is only for native Windows targets")
endif()

if(NOT XDMCP_SOURCE_DIR)
  message(FATAL_ERROR "XDMCP_SOURCE_DIR must point to the libXdmcp source tree")
endif()
if(NOT XDMCP_VERSION)
  message(FATAL_ERROR "XDMCP_VERSION must contain the packaged libXdmcp version")
endif()

# cmd.exe supplies backslashes; generated install scripts need CMake paths.
file(TO_CMAKE_PATH "${XDMCP_SOURCE_DIR}" XDMCP_SOURCE_DIR)

find_path(XORGPROTO_INCLUDE_DIR NAMES X11/Xmd.h REQUIRED)

add_library(Xdmcp SHARED
  "${XDMCP_SOURCE_DIR}/Array.c"
  "${XDMCP_SOURCE_DIR}/Fill.c"
  "${XDMCP_SOURCE_DIR}/Flush.c"
  "${XDMCP_SOURCE_DIR}/Key.c"
  "${XDMCP_SOURCE_DIR}/Read.c"
  "${XDMCP_SOURCE_DIR}/Unwrap.c"
  "${XDMCP_SOURCE_DIR}/Wrap.c"
  "${XDMCP_SOURCE_DIR}/Wraphelp.c"
  "${XDMCP_SOURCE_DIR}/Write.c"
)

target_include_directories(Xdmcp
  PRIVATE
    "${XDMCP_SOURCE_DIR}/include"
    "${XORGPROTO_INCLUDE_DIR}"
)
target_compile_definitions(Xdmcp PRIVATE
  HASXDMAUTH
  WIN32
  _CRT_SECURE_NO_WARNINGS
)
target_link_libraries(Xdmcp PRIVATE ws2_32)
set_target_properties(Xdmcp PROPERTIES
  ARCHIVE_OUTPUT_NAME Xdmcp
  RUNTIME_OUTPUT_NAME Xdmcp-6
  SOVERSION 6
  VERSION 6.0.0
  WINDOWS_EXPORT_ALL_SYMBOLS ON
)

install(TARGETS Xdmcp
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
install(
  FILES "${XDMCP_SOURCE_DIR}/include/X11/Xdmcp.h"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/X11"
)
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/xdmcp.pc.in"
  "${CMAKE_CURRENT_BINARY_DIR}/xdmcp.pc"
  @ONLY
)
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/xdmcp.pc"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
)

if(BUILD_TESTING)
  add_executable(xdmcp_array_test "${XDMCP_SOURCE_DIR}/test/Array.c")
  target_include_directories(xdmcp_array_test PRIVATE
    "${XDMCP_SOURCE_DIR}/include"
    "${XORGPROTO_INCLUDE_DIR}"
  )
  if(MSVC)
    target_compile_options(xdmcp_array_test PRIVATE /UNDEBUG)
  else()
    target_compile_options(xdmcp_array_test PRIVATE -UNDEBUG)
  endif()
  target_link_libraries(xdmcp_array_test PRIVATE Xdmcp)
  add_test(NAME xdmcp_array COMMAND xdmcp_array_test)
endif()
