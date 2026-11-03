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
#       depends on all formats specified by the DEFAULT_FORMATS argument. If this
#       argument is not provided the default is 'pdf'.
#
#       CMAKE_SOURCE_DIR is used as the Typst project root, unless TYPST_ROOT
#       is specified.
#
#       All pages are compiled, unless the PAGES argument is specified. See
#       `typst compile --help` for more information about the `--pages` option.
#
#       Key value pairs can be provided through the KEY_VALUE_PAIRS argument and
#       are visible in typst through `sys.inputs`.
#
#       If the typst document depends on other targets or files, this dependency
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

find_program(TYPST_EXECUTABLE typst)
set(TYPST_ALLOWED_FORMATS html pdf png svg)

function(ADD_TYPST_DOCUMENT arg_TYPST_FILE)
  # Ensure Typst is available
  if(TYPST_EXECUTABLE-NOTFOUND)
    message(FATAL_ERROR "Could not find typst executable")
  endif()

  # Ensure source file exists
  cmake_path(IS_PREFIX CMAKE_CURRENT_SOURCE_DIR "${arg_TYPST_FILE}" NORMALIZE is_absolute_under_current)
  if(is_absolute_under_current)
    cmake_path(NORMAL_PATH arg_TYPST_FILE OUTPUT_VARIABLE source_path)
  else()
    cmake_path(APPEND CMAKE_CURRENT_SOURCE_DIR "${arg_TYPST_FILE}" OUTPUT_VARIABLE source_path)
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

  if(DEFINED arg_TARGET)
    # Ensure TARGET is a target name if provided
    cmake_path(GET arg_TARGET STEM target_name)
    if(NOT "${arg_TARGET}" STREQUAL "${target_name}")
      message(SEND_ERROR "TARGET must not contain any directory components or file extensions.")
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

  set(formats_copy ${arg_DEFAULT_FORMATS})
  list(REMOVE_ITEM formats_copy ${TYPST_ALLOWED_FORMATS})
  if(formats_copy)
    message(SEND_ERROR "FORMAT must consist of values 'html', 'pdf', 'png' or 'svg'. ${formats_copy} is not valid")
  endif()

  unset(fonts)
  if (DEFINED arg_FONT_DIRS)
    cmake_path(CONVERT "${arg_FONT_DIRS}" TO_NATIVE_PATH_LIST font-list NORMALIZE)
    set(fonts "--font-path" "${font-list}")
  endif()

  # Determine target path
  cmake_path(GET source_path PARENT_PATH parent_source)
  if(TYPST_OUTPUT_DIRECTORY)
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "${TYPST_OUTPUT_DIRECTORY}" output_dir ${parent_source})
  else()
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}" output_dir ${parent_source})
  endif()
  foreach(format IN LISTS TYPST_ALLOWED_FORMATS)
    set(output "${output_dir}/${target_name}.${format}")
    set(dep_file "${output}.d")
    cmake_path(NATIVE_PATH output output)
    cmake_path(NATIVE_PATH dep_file dep_file)
    cmake_path(NATIVE_PATH source_path source)
    cmake_path(NATIVE_PATH arg_TYPST_ROOT root_dir)
    add_custom_command(
      OUTPUT "${output}"
      COMMAND ${TYPST_EXECUTABLE} compile ${arg_KEY_VALUE_PAIRS} --format ${format} ${arg_PAGES} --make-deps "${dep_file}" --root "${root_dir}" ${fonts} "${source}" "${output}"
      DEPENDS "${source}"
      DEPFILE "${dep_file}"
      VERBATIM
    )
    add_custom_target(${target_name}_${format} DEPENDS "${output}" ${arg_DEPENDS})
  endforeach()
  set(default_targets ${arg_DEFAULT_FORMATS})
  list(TRANSFORM default_targets PREPEND "${target_name}_")
  if(arg_EXCLUDE_FROM_ALL)
    add_custom_target(${target_name} DEPENDS ${default_targets})
  else()
    add_custom_target(${target_name} ALL DEPENDS ${default_targets})
  endif()
endfunction()
