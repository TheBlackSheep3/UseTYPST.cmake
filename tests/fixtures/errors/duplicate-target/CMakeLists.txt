cmake_minimum_required(VERSION 3.20...4.4)
project(UseTYPST_duplicate-target_test NONE)

# CMAKE_MODULE_PATH is passed in by tests/CMakeLists.txt and points at the
# repository root, so this tests the real module rather than a copy.
include(UseTYPST)

# Intentionally add duplicate target.
# add_typst_document() is expected to report an error at configure time.
add_typst_document(doc.typ)
add_typst_document(doc.typ)
