if(__USE_TYPST_INCLUDED)
  return()
endif()
set(__USE_TYPST_INCLUDED TRUE)

set(_USE_TYPST_MINIMUM_CMAKE_VERSION 3.12)
if(CMAKE_VERSION VERSION_LESS _USE_TYPST_MINIMUM_CMAKE_VERSION)
  message(
    FATAL_ERROR
    "UseTYPST.cmake requires CMake ${_USE_TYPST_MINIMUM_CMAKE_VERSION} or newer"
    " because it uses:\n"
    "  - cmake_parse_arguments(PARSE_ARGV N ...) (3.7)\n"
    "  - list(TRANSFORM ...) (3.12)\n"
    "  - string(PREPEND ...) (3.10)\n"
    "  - add_custom_command(... DEPFILE ...) (3.7)\n"
    "Current version: ${CMAKE_VERSION}"
)
endif()

#
# User-overridable cache variable
#
set(
  TYPST_ROOT
  ""
  CACHE PATH
  "Root directory of typst installation"
)

#
# User-overridable cache variable
#
set(
  TYPST_EXECUTABLE
  ""
  CACHE FILEPATH
  "Path to the typst executable"
)

#
# Find executable if not explicitly specified, also respecting environment
# variable `TYPST_ROOT`
#
if(NOT TYPST_EXECUTABLE)
    find_program(
        TYPST_EXECUTABLE
        NAMES typst
        HINTS
          "${TYPST_ROOT}"
          "$ENV{TYPST_ROOT}"
        PATH_SUFFIXES bin
    )
endif()

#
# Probe version
#
if(TYPST_EXECUTABLE)
  execute_process(
    COMMAND "${TYPST_EXECUTABLE}" --version
    RESULT_VARIABLE _typst_result
    OUTPUT_VARIABLE _typst_output
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(_typst_result EQUAL 0)
    string(
      REGEX MATCH
      "^typst ([0-9]+)\\.([0-9]+)\\.([0-9]+)"
      _typst_version_match
      "${_typst_output}"
    )

    if(_typst_version_match)
      set(TYPST_VERSION_MAJOR "${CMAKE_MATCH_1}")
      set(TYPST_VERSION_MINOR "${CMAKE_MATCH_2}")
      set(TYPST_VERSION_PATCH "${CMAKE_MATCH_3}")

      set(
        TYPST_VERSION
        "${TYPST_VERSION_MAJOR}.${TYPST_VERSION_MINOR}.${TYPST_VERSION_PATCH}"
      )
    endif()
  endif()
endif()

mark_as_advanced(
  TYPST_ROOT
  TYPST_EXECUTABLE
)

function(ADD_TYPST_DOCUMENT)
  if(NOT TYPST_EXECUTABLE)
    message(FATAL_ERROR "Could not find typst executable")
  endif()

  if(TYPST_VERSION VERSION_LESS 0.13.0)
    message(FATAL_ERROR "Typst >= 0.13.0 required")
  endif()

  cmake_parse_arguments(
    TYPST_TARGET
    "NO_SYSTEM_FONTS;NO_EMBEDDED_FONTS;PRETTY_OUTPUT;NO_PDF_TAGS;EXCLUDE_FROM_ALL"
    "DOCUMENT;ROOT_FILE;OUTPUT_FORMAT;PAGES;PACKAGE_PATH;PACKAGE_CACHE_PATH;PNG_PPI;JOBS"
    "KEY_VALUE_PAIRS;DEPENDS;PDF_STANDARD"
    ${ARGN}
  )

  if (NOT DEFINED TYPST_TARGET_DOCUMENT OR NOT DEFINED TYPST_TARGET_ROOT_FILE)
    message(SEND_ERROR "ADD_TYPST_DOCUMENT requires DOCUMENT and ROOT_FILE")
    return()
  endif()

  if (NOT DEFINED TYPST_TARGET_OUTPUT_FORMAT)
    set(TYPST_TARGET_OUTPUT_FORMAT "pdf")
  endif()

  string(TOLOWER ${TYPST_TARGET_OUTPUT_FORMAT} TYPST_TARGET_OUTPUT_FORMAT)

  if (NOT (${TYPST_TARGET_OUTPUT_FORMAT} STREQUAL html OR ${TYPST_TARGET_OUTPUT_FORMAT} STREQUAL pdf OR ${TYPST_TARGET_OUTPUT_FORMAT} STREQUAL png OR ${TYPST_TARGET_OUTPUT_FORMAT} STREQUAL svg))
    message(SEND_ERROR "ADD_TYPST_DOCUMENT only supports output formats: html, pdf, png, svg")
    return()
  endif()

  if (DEFINED TYPST_TARGET_KEY_VALUE_PAIRS)
    list(TRANSFORM TYPST_TARGET_KEY_VALUE_PAIRS PREPEND "--input=")
  endif()

  if (DEFINED TYPST_TARGET_PAGES)
    string(PREPEND TYPST_TARGET_PAGES "--pages=")
  endif()

  if (${EXCLUDE_FROM_ALL})
    add_custom_target(${TYPST_TARGET_DOCUMENT} DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.${TYPST_TARGET_OUTPUT_FORMAT}" ${TYPST_TARGET_DEPENDS})
  else()
    add_custom_target(${TYPST_TARGET_DOCUMENT} ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.${TYPST_TARGET_OUTPUT_FORMAT}" ${TYPST_TARGET_DEPENDS})
  endif()

  if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${TYPST_TARGET_ROOT_FILE}")
    message(SEND_ERROR "Can not find root document file ${TYPST_TARGET_ROOT_FILE}")
    return()
  endif()

  cmake_path(SET TYPST_TARGET_ROOT_OUTPUT_DIR "${CMAKE_BINARY_DIR}")
  cmake_path(RELATIVE_PATH TYPST_TARGET_ROOT_OUTPUT_DIR BASE_DIRECTORY "${CMAKE_SOURCE_DIR}")
  # prepend '/' to relative path so typst evaluates them relative to root
  string(PREPEND TYPST_TARGET_ROOT_OUTPUT_DIR "/")

  if(TYPST_VERSION VERSION_LESS_EQUAL 0.13)
    set(deps_string --make-deps)
  else()
    set(deps_string --deps-format make --deps)
  endif()

  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.${TYPST_TARGET_OUTPUT_FORMAT}"
    COMMAND ${TYPST_EXECUTABLE} compile --input
    ${TYPST_TARGET_KEY_VALUE_PAIRS} --format ${TYPST_TARGET_OUTPUT_FORMAT}
    ${TYPST_TARGET_PAGES}
    ${deps_string} "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.d"
    --root "${CMAKE_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/${TYPST_TARGET_ROOT_FILE}"
    "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.${TYPST_TARGET_OUTPUT_FORMAT}"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${TYPST_TARGET_ROOT_FILE}"
    DEPFILE "${CMAKE_CURRENT_BINARY_DIR}/${TYPST_TARGET_DOCUMENT}.d"
  )
endfunction()
