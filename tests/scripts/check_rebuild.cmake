# Checks incremental rebuilds of a fixture project.
#
# Usage:
#   cmake -DSOURCE_DIR=<fixture dir> -DWORK_DIR=<scratch dir>
#         -DGENERATOR=<generator> [-DGENERATOR_PLATFORM=<platform>]
#         [-DGENERATOR_TOOLSET=<toolset>] [-DMAKE_PROGRAM=<program>]
#         [-DCONFIG=<config>] -DMODULE_PATH=<dir containing UseTYPST.cmake>
#         [-DTYPST_EXECUTABLE=<typst>] -DTARGET=<target>
#         -DOUTPUT=<output file, relative to the build dir>
#         [-DMODIFY=<file, relative to the fixture dir>]
#         -P check_rebuild.cmake
#
# The fixture is copied to WORK_DIR, so the source tree is never modified.
# It is configured and built once, then built a second time:
#   - without MODIFY, the second build must leave OUTPUT untouched;
#   - with MODIFY, that file is touched first and OUTPUT must be regenerated.
#
# Rebuilds are detected by OUTPUT's modification time. Typst rewrites its
# output on every run, and the script waits a second between builds, so a
# second-resolution timestamp is enough.

foreach(var SOURCE_DIR WORK_DIR GENERATOR MODULE_PATH TARGET OUTPUT)
  if("${${var}}" STREQUAL "")
    message(FATAL_ERROR "check_rebuild.cmake: ${var} not set")
  endif()
endforeach()

set(src_dir "${WORK_DIR}/src")
set(bin_dir "${WORK_DIR}/build")
set(output "${bin_dir}/${OUTPUT}")

# Run a command and abort the test with its output if it fails.
function(run_step description)
  execute_process(
    COMMAND ${ARGN}
    RESULT_VARIABLE result
    OUTPUT_VARIABLE out
    ERROR_VARIABLE out
  )
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${description} failed (${result}):\n${out}")
  endif()
  set(last_step_output "${out}" PARENT_SCOPE)
endfunction()

function(get_output_mtime out_var)
  if(NOT EXISTS "${output}")
    message(FATAL_ERROR "Expected output was not produced: ${output}")
  endif()
  file(TIMESTAMP "${output}" mtime "%s" UTC)
  set(${out_var} "${mtime}" PARENT_SCOPE)
endfunction()

# Start from a fresh copy of the fixture.
file(REMOVE_RECURSE "${WORK_DIR}")
file(COPY "${SOURCE_DIR}/" DESTINATION "${src_dir}")

set(configure_args
  -S "${src_dir}" -B "${bin_dir}" -G "${GENERATOR}"
  "-DCMAKE_MODULE_PATH=${MODULE_PATH}"
)
if(GENERATOR_PLATFORM)
  list(APPEND configure_args -A "${GENERATOR_PLATFORM}")
endif()
if(GENERATOR_TOOLSET)
  list(APPEND configure_args -T "${GENERATOR_TOOLSET}")
endif()
if(MAKE_PROGRAM)
  list(APPEND configure_args "-DCMAKE_MAKE_PROGRAM=${MAKE_PROGRAM}")
endif()
if(TYPST_EXECUTABLE)
  list(APPEND configure_args "-DTYPST_EXECUTABLE=${TYPST_EXECUTABLE}")
endif()
if(CONFIG)
  # Used by single-config generators, ignored by multi-config ones.
  list(APPEND configure_args "-DCMAKE_BUILD_TYPE=${CONFIG}")
endif()

set(build_args --build "${bin_dir}" --target "${TARGET}")
if(CONFIG)
  list(APPEND build_args --config "${CONFIG}")
endif()

run_step("Configure" "${CMAKE_COMMAND}" ${configure_args})
run_step("Initial build" "${CMAKE_COMMAND}" ${build_args})
get_output_mtime(before)

# Make sure anything written from now on gets a newer timestamp.
execute_process(COMMAND "${CMAKE_COMMAND}" -E sleep 1)

if(MODIFY)
  set(modified "${src_dir}/${MODIFY}")
  if(NOT EXISTS "${modified}")
    message(FATAL_ERROR "MODIFY file does not exist in fixture: ${MODIFY}")
  endif()
  file(TOUCH "${modified}")
endif()

run_step("Second build" "${CMAKE_COMMAND}" ${build_args})
get_output_mtime(after)

if(MODIFY)
  if(NOT after GREATER before)
    message(FATAL_ERROR
      "${OUTPUT} was not rebuilt after changing ${MODIFY}.\n"
      "Second build output:\n${last_step_output}")
  endif()
  message(STATUS "OK: ${OUTPUT} was rebuilt after changing ${MODIFY}")
else()
  if(NOT after EQUAL before)
    message(FATAL_ERROR
      "${OUTPUT} was rebuilt although no input changed.\n"
      "Second build output:\n${last_step_output}")
  endif()
  message(STATUS "OK: ${OUTPUT} was not rebuilt")
endif()
