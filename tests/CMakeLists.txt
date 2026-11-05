include(CTest)
if(BUILD_TESTING)
  add_test(NAME typst.basic
    ${CMAKE_CTEST_COMMAND} --build-and-test
    "${CMAKE_CURRENT_SOURCE_DIR}/fixtures/basic"
    "${CMAKE_CURRENT_BINARY_DIR}/basic"
    --build-generator ${CMAKE_GENERATOR}
    --build-options -DCMAKE_MODULE_PATH="${PROJECT_SOURCE_DIR}/cmake"
    --test-command ${CMAKE_COMMAND}
      -DOUT="${CMAKE_CURRENT_BINARY_DIR}/basic/doc.pdf"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/verify_output.cmake"
  )
endif()
