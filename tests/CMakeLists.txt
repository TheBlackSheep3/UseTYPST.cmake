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
#   OUTPUT <expected output file>... (relative to the fixture's build dir)
# )
# Each output is checked by scripts/verify_outputs.cmake according to its
# file extension.
function(usetypst_add_fixture_test)
  cmake_parse_arguments(ARG "" "NAME;FIXTURE;TARGET" "OUTPUT" ${ARGN})

  set(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/${ARG_FIXTURE}")
  set(binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${ARG_FIXTURE}")
  list(TRANSFORM ARG_OUTPUT PREPEND "${binary_dir}/" OUTPUT_VARIABLE outputs)

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
        "-DOUTPUTS=${outputs}"
        -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/verify_outputs.cmake"
  )
  set_tests_properties(${ARG_NAME} PROPERTIES LABELS "integration")
endfunction()

# usetypst_add_failing_fixture_test(
#   NAME <test-name>
#   FIXTURE <dir under fixtures/>
#   EXPECT_ERROR <regex the failure output must match>
# )
# Passes only if the fixture fails AND the output matches EXPECT_ERROR,
# so an unrelated failure (e.g. typst not found) is still reported.
function(usetypst_add_failing_fixture_test)
  cmake_parse_arguments(ARG "" "NAME;FIXTURE;EXPECT_ERROR" "" ${ARGN})

  set(source_dir "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/${ARG_FIXTURE}")
  set(binary_dir "${CMAKE_CURRENT_BINARY_DIR}/${ARG_FIXTURE}")

  string(REPLACE "errors/" "" fixture_name "${ARG_FIXTURE}")
  add_test(NAME ${ARG_NAME}
    COMMAND ${CMAKE_CTEST_COMMAND}
      --build-and-test "${source_dir}" "${binary_dir}"
      --build-generator "${CMAKE_GENERATOR}"
      --build-makeprogram "${CMAKE_MAKE_PROGRAM}"
      --build-project "UseTYPST_${fixture_name}_test"
      --build-options ${USETYPST_TEST_CONFIGURE_OPTIONS}
  )
  set_tests_properties(${ARG_NAME} PROPERTIES
    PASS_REGULAR_EXPRESSION "ADD_TYPST_DOCUMENT: ${ARG_EXPECT_ERROR}"
    LABELS "integration;expected-failure"
  )
endfunction()

add_test(NAME typst.version
  COMMAND ${CMAKE_COMMAND} ${USETYPST_TEST_CONFIGURE_OPTIONS}
    -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/verify_version.cmake"
)
# Exit code 2 indicates test skip
set_tests_properties(typst.version PROPERTIES SKIP_RETURN_CODE 2)

usetypst_add_fixture_test(
  NAME typst.basic
  FIXTURE basic
  TARGET doc
  OUTPUT doc.pdf
)

usetypst_add_fixture_test(
  NAME typst.absolute_path
  FIXTURE absolute-path
  TARGET doc
  OUTPUT doc.pdf
)

usetypst_add_fixture_test(
  NAME typst.custom_target_name
  FIXTURE custom-target-name
  TARGET my_doc
  OUTPUT my_doc.pdf
)

usetypst_add_fixture_test(
  NAME typst.multi_file
  FIXTURE multi-file
  TARGET doc
  OUTPUT doc.pdf
)

usetypst_add_fixture_test(
  NAME typst.multi_formats
  FIXTURE multi-formats
  TARGET doc
  OUTPUT doc.pdf doc-1.png doc-1.svg
    $<$<VERSION_GREATER_EQUAL:${TYPST_VERSION},0.13>:doc.html>
)

usetypst_add_fixture_test(
  NAME typst.multi_pages
  FIXTURE multi-pages
  TARGET doc
  OUTPUT doc.pdf doc-1-of-2.png doc-2-of-2.png doc-1-of-2.svg doc-2-of-2.svg
    $<$<VERSION_GREATER_EQUAL:${TYPST_VERSION},0.13>:doc.html>
)

usetypst_add_fixture_test(
  NAME typst.enforce_single_file
  FIXTURE enforce-single-file
  TARGET doc
  OUTPUT doc.pdf doc.png doc.svg
    $<$<VERSION_GREATER_EQUAL:${TYPST_VERSION},0.13>:doc.html>
)

if(TYPST_VERSION VERSION_GREATER_EQUAL 0.13)
  usetypst_add_fixture_test(
    NAME typst.html
    FIXTURE html
    TARGET doc
    OUTPUT doc.html
  )
else()
  usetypst_add_failing_fixture_test(
    NAME typst.error.html
    FIXTURE html
    EXPECT_ERROR
    "output format html is only supported for typst version 0.13.0 upwards."
  )
endif()

usetypst_add_failing_fixture_test(
  NAME typst.error.missing_file
  FIXTURE errors/missing-file
  EXPECT_ERROR "does-not-exist\\.typ does not exist."
)

usetypst_add_failing_fixture_test(
  NAME typst.error.missing_typst
  FIXTURE errors/missing-typst
  EXPECT_ERROR "Could not find Typst executable."
)

file(GLOB invalid_targets
  RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/errors"
  "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/errors/invalid-target-*"
)
foreach(fixture IN LISTS invalid_targets)
  string(MAKE_C_IDENTIFIER "${fixture}" name)
  usetypst_add_failing_fixture_test(
    NAME typst.error.${name}
    FIXTURE errors/${fixture}
    EXPECT_ERROR "TARGET must be a valid CMake target name."
  )
endforeach()

usetypst_add_failing_fixture_test(
  NAME typst.error.duplicate_target
  FIXTURE errors/duplicate-target
  EXPECT_ERROR "target 'doc' already exists."
)

usetypst_add_failing_fixture_test(
  NAME typst.error.invalid_output_format
  FIXTURE errors/invalid-output-format
  EXPECT_ERROR "DEFAULT_FORMATS must consist of values 'html', 'pdf'"
)

# usetypst_add_rebuild_test(
#   NAME <test-name>
#   FIXTURE <dir under fixtures/>
#   TARGET <custom target created by add_typst_document>
#   OUTPUT <expected output file, relative to the fixture's build dir>
#   [MODIFY <file in the fixture to change before the second build>]
# )
# Builds the fixture twice. Without MODIFY the second build must not touch
# OUTPUT, with MODIFY it must regenerate it. See scripts/check_rebuild.cmake.
function(usetypst_add_rebuild_test)
  cmake_parse_arguments(ARG "" "NAME;FIXTURE;TARGET;OUTPUT;MODIFY" "" ${ARGN})

  add_test(NAME ${ARG_NAME}
    COMMAND ${CMAKE_COMMAND}
      "-DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/fixtures/${ARG_FIXTURE}"
      "-DWORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/rebuild/${ARG_NAME}"
      "-DGENERATOR=${CMAKE_GENERATOR}"
      "-DGENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}"
      "-DGENERATOR_TOOLSET=${CMAKE_GENERATOR_TOOLSET}"
      "-DMAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}"
      "-DCONFIG=$<CONFIG>"
      "-DMODULE_PATH=${PROJECT_SOURCE_DIR}"
      "-DTYPST_EXECUTABLE=${TYPST_EXECUTABLE}"
      "-DTARGET=${ARG_TARGET}"
      "-DOUTPUT=${ARG_OUTPUT}"
      "-DMODIFY=${ARG_MODIFY}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/check_rebuild.cmake"
  )
  set_tests_properties(${ARG_NAME} PROPERTIES LABELS "integration;rebuild")
endfunction()

usetypst_add_rebuild_test(
  NAME typst.rebuild.no_change
  FIXTURE multi-file
  TARGET doc
  OUTPUT doc.pdf
)

# One test per input of the multi-file fixture: the root file, an #include
# and an image. Every file in the fixture except CMakeLists.txt must be a
# dependency of the document.
file(GLOB rebuild_inputs
  RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/multi-file"
  "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/multi-file/*"
)
list(REMOVE_ITEM rebuild_inputs CMakeLists.txt)
foreach(input IN LISTS rebuild_inputs)
  string(MAKE_C_IDENTIFIER "${input}" name)
  usetypst_add_rebuild_test(
    NAME typst.rebuild.${name}
    FIXTURE multi-file
    TARGET doc
    OUTPUT doc.pdf
    MODIFY "${input}"
  )
endforeach()
