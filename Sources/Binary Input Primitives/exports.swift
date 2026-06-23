// Core dissolved (L1 core-dissolution sweep 2026-06-23): Input re-exported the
// dissolved `Binary Parser Primitives Core` funnel; import its two funneled
// externals directly per [MOD-038] to preserve this shim's re-export surface.
@_exported public import Binary_Primitives
@_exported public import Parser_Primitives
// Byte.Input is the canonical byte-stream input type, owned by
// byte-parser-primitives. Re-export so consumers of Binary Input Primitives
// see Byte.Input and — transitively via byte-parser-primitives' own
// re-exports — the Input.Protocol / Collection.Protocol conformances on
// Input.Slice / Array.Indexed that Byte.Input is built on. The Binary
// Input Primitives target exists as a thin re-export shim for
// source-compatibility.
@_exported public import Byte_Parser_Primitives
