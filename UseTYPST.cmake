# File: UseTypst.cmake
# CMAKE command to use the Typst compiler
# Contributors:
#   - YUGA <113231660+danfunc@users.noreply.github.com>
#   - Niklas Dießner <40034835+TheBlackSheep3@users.noreply.github.com>
#   - Timothy Lee <11895198+timothytylee@users.noreply.github.com>
#
# The following function is defined:
#
# add_typst_document(<typst_file>
#                    [TARGET <target_name>]
#                    [DEFAULT_FORMATS <format>...]
#                    [TYPST_ROOT <root_directory>]
#                    [PAGES <pages>]
#                    [KEY_VALUE_PAIRS <key=value>...]
#                    [DEPENDS <depend>...]
#                    [FONT_DIRS <dir>...]
#                    [EXCLUDE_FROM_ALL])
#
#       Adds a target for each output format that compiles <typst_file> to
#       <name>.<output_format>, where <name> is the base name of <typst_file>
#       and the supported output formats are 'html', 'pdf', 'png' and 'svg'.
#       The TARGET argument can be used to override the the target filename.
#       These targets are of the form <target_name>_<output_format>. In addition
#       to those targets a default target <target_name> gets included which
#       depends on all formats specified by the DEFAULT_FORMATS argument. If
#       this argument is not provided the default is 'pdf'.
#
#       CMAKE_SOURCE_DIR is used as the Typst project root, unless TYPST_ROOT
#       is specified.
#
#       All pages are compiled, unless the PAGES argument is specified. See
#       `typst compile --help` for more information about the `--pages` option.
#
#       Key value pairs can be provided through the KEY_VALUE_PAIRS argument and
#       are visible in Typst through `sys.inputs`.
#
#       If the Typst document depends on other targets or files, this dependency
#       can be specified with the DEPENDS argument.
#
#       Additional font directories which are searched recursively for fonts are
#       specified through the FONT_DIRS argument.
#
#       Unless the EXCLUDE_FROM_ALL opion is given, the default target is added
#       to the ALL target and built by default.
#
# The following variable can be set to customize the behaviour of
# add_typst_document():
#
# TYPST_OUTPUT_DIRECTORY
#       The directory where compiled documents are placed.  If this variable
#       is not defined, documents are placed inside CMAKE_CURRENT_BINARY_DIR.

if(__USE_TYPST_INCLUDED)
  return()
endif()
set(__USE_TYPST_INCLUDED TRUE)

option(DEBUG_USE_TYPST "Add debug output for UseTYPST.cmake module." FALSE)

if(DEBUG_USE_TYPST)
  include(CMakePrintHelpers)
endif()

set(__USE_TYPST_MINIMUM_CMAKE_VERSION 3.20)
set(__USE_TYPST_MINIMUM_TYPST_VERSION 0.13.0)
if(CMAKE_VERSION VERSION_LESS __USE_TYPST_MINIMUM_CMAKE_VERSION)
  message(
    FATAL_ERROR
    "UseTYPST.cmake requires CMake ${_USE_TYPST_MINIMUM_CMAKE_VERSION} or newer"
    " because it uses cmake_path()\n"
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
  "Root directory of Typst installation"
)

#
# User-overridable cache variable
#
set(
  TYPST_EXECUTABLE
  NOTFOUND
  CACHE FILEPATH
  "Path to the Typst executable"
)

# Find executable if not explicitly specified, also respecting environment
# variable `TYPST_ROOT`
find_program(
  TYPST_EXECUTABLE
  typst
  HINTS "${TYPST_ROOT}" ENV TYPST_ROOT
  PATH_SUFFIXES bin
)
if(DEBUG_USE_TYPST)
  cmake_print_variables(TYPST_EXECUTABLE)
endif()

# Probe version
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
  DEBUG_USE_TYPST
)

set(__TYPST_ALLOWED_FORMATS html pdf png svg)

function(ADD_TYPST_DOCUMENT arg_TYPST_FILE)
  # Ensure Typst is available
  if(NOT TYPST_EXECUTABLE)
    message(FATAL_ERROR "Could not find Typst executable")
  endif()

  # Check for available Typst version
  if(TYPST_VERSION VERSION_LESS __USE_TYPST_MINIMUM_TYPST_VERSION)
    message(
      WARNING
      "UseTYPST.cmake was developed and tested using Typst version "
      "${__USE_TYPST_MINIMUM_TYPST_VERSION} and up. Some options might not work"
      " propperly.\n"
      "Current version: ${TYPST_VERSION}"
    )
  endif()

  # Ensure source file exists
  cmake_path(
    IS_PREFIX
    CMAKE_CURRENT_SOURCE_DIR
    "${arg_TYPST_FILE}"
    NORMALIZE
    is_absolute_under_current
  )
  if(is_absolute_under_current)
    cmake_path(NORMAL_PATH arg_TYPST_FILE OUTPUT_VARIABLE source_path)
  else()
    cmake_path(
      APPEND
      CMAKE_CURRENT_SOURCE_DIR
      "${arg_TYPST_FILE}"
      OUTPUT_VARIABLE
      source_path
    )
  endif()

  if(NOT EXISTS "${source_path}")
    message(SEND_ERROR "${arg_TYPST_FILE} does not exist.")
  endif()

  # Parse optional arguments
  set(options EXCLUDE_FROM_ALL)
  set(oneValueArgs TARGET PAGES TYPST_ROOT)
  set(multiValueArgs KEY_VALUE_PAIRS DEPENDS FONT_DIRS DEFAULT_FORMATS)
  cmake_parse_arguments(PARSE_ARGV 1 arg
    "${options}" "${oneValueArgs}" "${multiValueArgs}"
  )
  if(TYPST_VERSION VERSION_GREATER_EQUAL 0.14)
    set(deps_string --deps-format make --deps)
  else()
    set(deps_string --make-deps)
  endif()

  if(DEFINED arg_TARGET)
    # Ensure TARGET is a target name if provided
    cmake_path(GET arg_TARGET STEM target_name)
    if(NOT "${arg_TARGET}" STREQUAL "${target_name}")
      message(
        SEND_ERROR
        "TARGET must not contain any directory components or file extensions."
      )
    endif()
  else()
    cmake_path(GET arg_TYPST_FILE STEM target_name)
  endif()

  if (DEFINED arg_PAGES)
    string(PREPEND arg_PAGES "--pages=")
  endif()

  if (DEFINED arg_KEY_VALUE_PAIRS)
    list(TRANSFORM arg_KEY_VALUE_PAIRS PREPEND "--input=")
  endif()

  if(NOT DEFINED arg_TYPST_ROOT)
    set(arg_TYPST_ROOT "${CMAKE_SOURCE_DIR}")
  endif()

  if(NOT DEFINED arg_DEFAULT_FORMATS)
    set(arg_DEFAULT_FORMATS pdf)
  endif()
  string(TOLOWER ${arg_DEFAULT_FORMATS} arg_DEFAULT_FORMATS)

  set(formats_copy ${arg_DEFAULT_FORMATS})
  list(REMOVE_ITEM formats_copy ${__TYPST_ALLOWED_FORMATS})
  if(formats_copy)
    message(
      SEND_ERROR
      "FORMAT must consist of values 'html', 'pdf', 'png' or 'svg'. "
      "${formats_copy} is not valid."
    )
  endif()

  unset(fonts)
  if (DEFINED arg_FONT_DIRS)
    cmake_path(
      CONVERT
      "${arg_FONT_DIRS}"
      TO_NATIVE_PATH_LIST
      font-list
      NORMALIZE)
    set(fonts "--font-path" "${font-list}")
  endif()

  # Determine target path
  cmake_path(GET source_path PARENT_PATH parent_source)
  if(TYPST_OUTPUT_DIRECTORY)
    set(root_out_dir "${TYPST_OUTPUT_DIRECTORY}")
  else()
    set(root_out_dir "${CMAKE_CURRENT_BINARY_DIR}")
  endif()
  string(REPLACE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${root_out_dir}"
    output_dir
    ${parent_source}
  )
  foreach(format IN LISTS __TYPST_ALLOWED_FORMATS)
    set(output "${output_dir}/${target_name}.${format}")
    set(dep_file "${output}.d")
    cmake_path(NATIVE_PATH output output)
    cmake_path(NATIVE_PATH dep_file dep_file)
    cmake_path(NATIVE_PATH source_path source)
    cmake_path(NATIVE_PATH arg_TYPST_ROOT root_dir)
    if(${format} STREQUAL pdf
        AND TYPST_VERSION VERSION_GREATER_EQUAL 0.14
        AND arg_PAGES)
      set(pdf_tags_string "--no-pdf-tags")
    else()
      unset(pdf_tags_string)
    endif()
    add_custom_command(
      OUTPUT "${output}"
      COMMAND ${TYPST_EXECUTABLE} compile ${arg_KEY_VALUE_PAIRS}
      --format ${format} ${arg_PAGES} ${deps_string} "${dep_file}"
      --root "${root_dir}" ${pdf_tags_string} ${fonts} "${source}" "${output}"
      DEPENDS "${source}"
      DEPFILE "${dep_file}"
      VERBATIM
    )
    add_custom_target(
      ${target_name}_${format}
      DEPENDS "${output}" ${arg_DEPENDS})
  endforeach()
  set(default_targets ${arg_DEFAULT_FORMATS})
  list(TRANSFORM default_targets PREPEND "${target_name}_")
  if(arg_EXCLUDE_FROM_ALL)
    add_custom_target(${target_name} DEPENDS ${default_targets})
  else()
    add_custom_target(${target_name} ALL DEPENDS ${default_targets})
  endif()
endfunction()
