# Usage: cmake -DOUTPUT=<path/to/file.pdf> -P verify_pdf.cmake
# Fails if the file is missing, empty, or does not start with a PDF header.

if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "verify_pdf.cmake: OUTPUT not set")
endif()

if(NOT EXISTS "${OUTPUT}")
  message(FATAL_ERROR "Expected output does not exist: ${OUTPUT}")
endif()

file(SIZE "${OUTPUT}" size)
if(size EQUAL 0)
  message(FATAL_ERROR "Output is empty: ${OUTPUT}")
endif()

# Read as hex: text mode mangles binary content. 255044462d == "%PDF-"
file(READ "${OUTPUT}" header LIMIT 5 HEX)
if(NOT header STREQUAL "255044462d")
  message(FATAL_ERROR "Output is not a PDF (first bytes: ${header}): ${OUTPUT}")
endif()

message(STATUS "OK: ${OUTPUT} (${size} bytes)")
