#import "@preview/polylux:0.4.0": *

#set page(paper: if sys.inputs.keys().contains("format") { sys.inputs.format } else { "presentation-16-9" })
#set text(size: 24pt)

#slide[
	#set align(horizon)
	= My cool presentation
	Example presentation to show some features of `UseTYPST.cmake`

	#datetime(day: 12, month: 10, year: 2025).display("[day padding:zero]. [month repr:long] [year]")
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
		add_typst_document(DOCUMENT document ROOT_FILE doc.typ)
		```
	]
]

#slide[
	= Parameters
	- `DOCUMENT` name of the document _required_
	- `ROOT_FILE` file name of the root typst file _required_
	- `OUTPUT_FOMAT` output format of the document (default `pdf`)
	- `KEY_VALUE_PAIRS` list of key value pairs passed to typst
	- `DEPENDS` CMake target the document depends on
	- `PAGES` which pages of the document to export
]
