cmake_minimum_required(VERSION 3.20...4.4)
project(UseTYPST_missing-typst_test NONE)

# CMAKE_MODULE_PATH is passed in by tests/CMakeLists.txt and points at the
# repository root, so this tests the real module rather than a copy.
include(UseTYPST)

# Intentionally set path to typst executable as empty string.
# add_typst_document() is expected to report an error at configure time.
set(TYPST_EXECUTABLE "")
add_typst_document(doc.typ)
