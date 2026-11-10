cmake_minimum_required(VERSION 3.20...4.4)
project(UseTYPST_multi-pages_test NONE)

# CMAKE_MODULE_PATH is passed in by tests/CMakeLists.txt and points at the
# repository root, so this tests the real module rather than a copy.
include(UseTYPST)

set(additional_option PAGES_TEMPLATE doc-{p}-of-{t})
# Defining formats as upper and lower case to verify case insensitivity
if(TYPST_VERSION VERSION_GREATER_EQUAL 0.13)
  add_typst_document(doc.typ DEFAULT_FORMATS png pdf html svg
    ${additional_option})
else()
  # Omitting 'html' for version under 0.13 because output format 'html' is not
  # supported.
  add_typst_document(doc.typ DEFAULT_FORMATS png pdf svg ${additional_option})
endif()
