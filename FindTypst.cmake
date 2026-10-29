include(FindPackageHandleStandardArgs)



#
# User-overridable cache variable
#
set(TYPST_ROOT "" CACHE PATH "Root directory of typst installation")

#
# User-overridable cache variable
#
set(TYPST_EXECUTABLE "${TYPST_EXECUTABLE}" CACHE FILEPATH "Path to the typst executable")

#
# Find executable if not explicitly specified
#
if(NOT TYPST_EXECUTABLE)
    find_program(
        TYPST_EXECUTABLE
        NAMES typst
        HINTS "${TYPST_ROOT}"
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
      "([0-9]+)\\.([0-9]+)\\.([0-9]+)"
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

#
# Standard package handling
#
find_package_handle_standard_args(
  Typst
  REQUIRED_VARS TYPST_EXECUTABLE
  VERSION_VAR TYPST_VERSION
)

mark_as_advanced(TYPST_EXECUTABLE)
