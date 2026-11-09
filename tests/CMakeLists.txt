# Integration tests for UseTYPST.cmake.
#
# Each fixture under fixtures/ is a standalone consumer project that includes
# the module from the repository root. `ctest --build-and-test` configures and
# builds it in its own build tree, then runs a verification script.

set(USETYPST_TEST_CONFIGURE_OPTIONS
  "-DCMAKE_MODULE_PATH=${PROJECT_SOURCE_DIR}"
)
if(TYPST_EXECUTABLE)
  # Reuse the typst found by the outer project so all tests use the same binary.
  list(APPEND USETYPST_TEST_CONFIGURE_OPTIONS "-DTYPST_EXECUTABLE=${TYPST_EXECUTABLE}")
endif()

# usetypst_add_fixture_test(
#   NAME <test-name>
#   FIXTURE <dir under fixtures/>
#   TARGET <custom target created by add_typst_document>
#   OUTPUT <expected output file, relative to the fixture's build dir>
# )
function(usetypst_add_fixture_test)
  cmake_parse_arguments(ARG "" "NAME;FIXTURE;TARGET;OUTPUT" "" ${ARGN})

  set(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/${ARG_FIXTURE}")
  set(binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${ARG_FIXTURE}")

  add_test(NAME ${ARG_NAME}
    COMMAND ${CMAKE_CTEST_COMMAND}
      --build-and-test "${source_dir}" "${binary_dir}"
      --build-generator "${CMAKE_GENERATOR}"
      --build-makeprogram "${CMAKE_MAKE_PROGRAM}"
      --build-project "UseTYPST_${ARG_FIXTURE}_test"
      --build-target "${ARG_TARGET}"
      # --build-options must be last before --test-command
      --build-options ${USETYPST_TEST_CONFIGURE_OPTIONS}
      --test-command "${CMAKE_COMMAND}"
        "-DOUTPUT=${binary_dir}/${ARG_OUTPUT}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/verify_pdf.cmake"
  )
  set_tests_properties(${ARG_NAME} PROPERTIES LABELS "integration")
endfunction()

usetypst_add_fixture_test(
  NAME typst.basic
  FIXTURE basic
  TARGET doc
  OUTPUT doc.pdf
)
