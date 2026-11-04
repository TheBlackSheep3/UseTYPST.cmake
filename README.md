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
add_typst_document(doc.typ TARGET document)
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

| Argument                         | Description                                                                                                                                                                                                                                                    | Required   |
| :-----------------:              | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------: |
| `<typst_file>`                   | Filename of the root Typst file. (positional argument)                                                                                                                                                                                                         | ✅         |
| `TARGET <target_name>`           | Name of the created target and the compiled document.                                                                                                                                                                                                          | ❌         |
| `DEFAULT_FORMATS <format>...`    | The default output targets of the document. Supported values are `html`, `pdf`, `png` and `svg`. The option is case insesitive. (default `pdf`)                                                                                                                | ❌         |
| `TYPST_ROOT <root_directory>`    | The project root of the Typst document. (default `CMAKE_SOURCE_DIR`)                                                                                                                                                                                           | ❌         |
| `KEY_VALUE_PAIRS <key=value>...` | List of key value pairs which are passed to Typst using the `--input` option and available in Typst through the `sys.inputs` dictionary. See [System Functions – Typst Documentation](https://typst.app/docs/reference/foundations/sys) for more information.  | ❌         |
| `DEPENDS <depend>...`            | The files or CMake targets the document depends on. This can be useful for generated graphics.                                                                                                                                                                 | ❌         |
| `PAGES <pages>`                  | Which pages of the document are to be exported into the final document. The value gets directly passed to the `--pages` option of Typst.                                                                                                                       | ❌         |
| `FONT_DIRS <dir>...`             | Directories for additional fonts.                                                                                                                                                                                                                              | ❌         |
| `EXCLUDE_FROM_ALL`               | Exclude created target from CMakes `ALL` target.                                                                                                                                                                                                               | ❌         |

## Options
If `TYPST_OUTPUT_DIRECTORY` is specified compiled documents will be placed there. If this variable is not defined, documents are placed inside `CMAKE_CURRENT_BINARY_DIR`.
