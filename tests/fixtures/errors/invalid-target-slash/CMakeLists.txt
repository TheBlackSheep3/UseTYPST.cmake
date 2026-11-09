cmake_minimum_required(VERSION 3.20...4.4)
project(UseTYPST_invalid-target-slash_test NONE)

# CMAKE_MODULE_PATH is passed in by tests/CMakeLists.txt and points at the
# repository root, so this tests the real module rather than a copy.
include(UseTYPST)

# Intentionally set invalid target name.
# add_typst_document() is expected to report an error at configure time.
add_typst_document(doc.typ TARGET "my_docs/doc")
