@_exported public import Binary_Parser_Primitives_Core
// Byte.Input is the underlying of Binary.Bytes.Input (typealias chain).
// Re-export so consumers of Binary Input Primitives see Byte.Input and
// — transitively via byte-parser-primitives' own re-exports — the
// Input.Protocol / Collection.Protocol conformances on Input.Slice /
// Array.Indexed that Byte.Input is built on.
@_exported public import Byte_Parser_Primitives
