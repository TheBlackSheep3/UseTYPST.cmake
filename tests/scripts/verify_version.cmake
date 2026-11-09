# Usage: cmake -P verify_version.cmake
# Fails with exit code 2 if environment variable with expected version is not
# set. Fails with exit code 1 if parsed and expected version do not match.

if(NOT DEFINED ENV{USE_TYPST_EXPECTED_TYPST_VERSION})
  message(WARNING "Not checking parsed typst version because"
    " USE_TYPST_EXPECTED_TYPST_VERSION is not set.")
  cmake_language(EXIT 2)
endif()

include(UseTYPST)

if(NOT ${TYPST_VERSION} VERSION_EQUAL $ENV{USE_TYPST_EXPECTED_TYPST_VERSION})
  message(FATAL_ERROR "Typst version ${TYPST_VERSION} does not match expected"
    " version $ENV{USE_TYPST_EXPECTED_TYPST_VERSION}.")
endif()

message(STATUS OK: Version ${TYPST_VERSION})
