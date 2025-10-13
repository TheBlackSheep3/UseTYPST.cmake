## Purpose

This tool aims to integrate Typst documents into a CMake project, making it easier to manage documentation alongside the source code. By leveraging CMake or other build systems (such as Makefiles and Cargo), we can automate the Typst document build process, reducing the burden on developers.

## Sample Project Structures

We propose a clear project structure that organizes Typst documents and related source code coherently. For example:

```
MyProject/
├── cmake/
│   └── UseTYPST.cmake
├── CMakeLists.txt
├── doc.typ
├── main.cpp
└── main.hpp
```

A 'Sample Project' can be found [here](https://github.com/TheBlackSheep3/UseTYPST.cmake/tree/main/SampleProject)

## Build Process Integration

To automate the Typst document build process, we propose using CMake with a custom module (`UseTYPST.cmake`). This module provides functions to add Typst document targets to the build process.
The `UseTYPST.cmake` module can be found [here](https://github.com/TheBlackSheep3/UseTYPST.cmake/blob/main/UseTYPST.cmake).
A 'Sample Project' is [here](https://github.com/TheBlackSheep3/UseTYPST.cmake/tree/main/SampleProject)

## Example `CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.20...4.1)
project(MyProject)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(UseTYPST)
add_typst_document(DOCUMENT document ROOT_FILE doc.typ)
add_executable(main main.cpp)
```

## Usage Example

Here is an example of how to use the UseTYPST.cmake module in a CMake project:

```cmake
add_typst_document(DOCUMENT my_document ROOT_FILE root.typ)
```

This will create a custom target `my_document` that compiles `root.typ` into a PDF named `my_document.pdf`.

## Parameters
The function provided by `UseTYPST.cmake` is able to accept a number of arguments. These arguments are documented in the following table.

|     Argument      | Description                                                                                                                                                                                                                                                   | Required |
|:-----------------:|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |:--------:|
|    `DOCUMENT`     | Name of the created target and the compiled document.                                                                                                                                                                                                         |    ✅    |
|    `ROOT_FILE`    | File name of the root typst file. It is expected to be a relative path, relative to the `CMakeLists.txt` invoking `add_typst_document`.                                                                                                                       |    ✅    | 
|  `OUTPUT_FORMAT`  | The output format of the document. Supported values are `html`, `pdf`, `png` and `svg`. The option is case insesitive. (default `pdf`)                                                                                                                        |    ❌    |
| `KEY_VALUE_PAIRS` | List of key value pairs which are passed to typst using the `--input` option and available in typst through the `sys.inputs` dictionary. See [System Functions – Typst Documentation](https://typst.app/docs/reference/foundations/sys) for more information. |    ❌    |
|     `DEPENDS`     | The CMake targets the document depends on. This can be useful for generated graphics.                                                                                                                                                                         |    ❌    |
|      `PAGES`      | Which pages of the document are to be exported into the final document. The value gets directly passed to the `--pages` option of typst.                                                                                                                      |    ❌    |

To access files in the `CMAKE_BINARY_DIR` it is passed to typst using the `--input` option. Though it is not passed as an absolute path but as a relative path in relation to `CMAKE_SOURCE_DIR` which is passed to typst as the root directory using the `--root` option. The relative path to `CMAKE_BINARY_DIR` can be accessed in typst through `sys.inputs.root_output_dir`. The relative path is prepended with a `/` so typst interprets it relative to the project root.

## Options
`UseTYPST.cmake` defines the option `ADD_TYPST_DOCUMENT_TO_ALL_TARGET` which controls whether the typst documents get added to the CMake ALL target. It is `OFF` by default.
