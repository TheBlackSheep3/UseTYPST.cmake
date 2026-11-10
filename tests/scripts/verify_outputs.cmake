# Usage: cmake -DOUTPUTS=<file>[;<file>...] -P verify_outputs.cmake
# Fails if any file is missing, empty, or its content does not match its
# extension:
#   .pdf   starts with "%PDF-"
#   .png   starts with the PNG signature
#   .svg   contains an <svg> element
#   .html  contains an <html> element
# Files with other extensions are only checked for existence and size.

if(NOT DEFINED OUTPUTS OR OUTPUTS STREQUAL "")
  message(FATAL_ERROR "verify_outputs.cmake: OUTPUTS not set")
endif()

foreach(output IN LISTS OUTPUTS)
  if(NOT EXISTS "${output}")
    message(SEND_ERROR "Expected output does not exist: ${output}")
    continue()
  endif()

  file(SIZE "${output}" size)
  if(size EQUAL 0)
    message(SEND_ERROR "Output is empty: ${output}")
    continue()
  endif()

  cmake_path(GET output EXTENSION LAST_ONLY ext)
  string(TOLOWER "${ext}" ext)

  if(ext STREQUAL ".pdf" OR ext STREQUAL ".png")
    # Binary formats: compare the leading bytes as hex, because text mode
    # mangles binary content.
    if(ext STREQUAL ".pdf")
      set(magic "255044462d")          # %PDF-
    else()
      set(magic "89504e470d0a1a0a")    # \x89PNG\r\n\x1a\n
    endif()
    string(LENGTH "${magic}" hex_len)
    math(EXPR byte_count "${hex_len} / 2")
    file(READ "${output}" header LIMIT ${byte_count} HEX)
    if(NOT header STREQUAL magic)
      message(SEND_ERROR
        "Output is not a valid ${ext} file (first bytes: ${header}): ${output}")
      continue()
    endif()
  elseif(ext STREQUAL ".svg" OR ext STREQUAL ".html")
    # Text formats: look for the root element near the start of the file.
    file(READ "${output}" head LIMIT 1024)
    string(TOLOWER "${head}" head)
    if(ext STREQUAL ".svg")
      set(element "<svg")
    else()
      set(element "<html")
    endif()
    string(FIND "${head}" "${element}" pos)
    if(pos EQUAL -1)
      message(SEND_ERROR
        "Output has no ${element}> element near its start: ${output}")
      continue()
    endif()
  endif()

  message(STATUS "OK: ${output} (${size} bytes)")
endforeach()
