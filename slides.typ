#import "@preview/polylux:0.4.0": *

#set page(paper: if sys.inputs.keys().contains("format") { sys.inputs.format } else { "presentation-16-9" })
#set text(size: 24pt)

#slide[
	#set align(horizon)
	= My cool presentation
	Example presentation to show some features of `UseTYPST.cmake`

	#datetime(day: 3, month: 11, year: 2026).display("[day padding:zero]. [month repr:long] [year]")
]

#slide[
	= Introduction
	`UseTYPST.cmake` aims to integrate Typst documents into a CMake project. It makes it easier to manage documentation alongside the source code.
	#align(horizon + center)[
		#image("subdir/CMake_Typst.svg", height: 40%)
	]
]

#slide[
	= Usage
	To use it just include the script in your `CMakeLists.txt` and invoke `add_typst_document()` like so

	#align(horizon)[
		```cmake
		include(UseTYPST.cmake)
		add_typst_document(doc.typ TARGET document)
		```
	]
]

#slide[
	= Parameters
	- positional argument, file name of the root typst file _required_
	- `TARGET` name of the document
	- `DEFAULT_FOMATS` output formats which are added to the default target (default `pdf`)
	- `TYPST_ROOT` typst project root (default `CMAKE_SOURCE_DIR`)
	- `PAGES` which pages of the document to export
	- `KEY_VALUE_PAIRS` list of key value pairs passed to typst
	- `DEPENDS` CMake targets or files the document depends on
	- `FONT_DIRS` additional search paths for fonts
	- `EXCLUDE_FROM_ALL` do not include default target into the ALL target created by cmake
]
