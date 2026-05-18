@_exported public import Binary_Parser_Primitives_Core
// Byte.Input is the canonical byte-stream input type, owned by
// byte-parser-primitives. Re-export so consumers of Binary Input Primitives
// see Byte.Input and — transitively via byte-parser-primitives' own
// re-exports — the Input.Protocol / Collection.Protocol conformances on
// Input.Slice / Array.Indexed that Byte.Input is built on. The earlier
// `Binary.Bytes.Input` typealias to Byte.Input was removed 2026-05-18
// per the binary-bytes-input-removal arc (successor to the
// typed-input-unification arc); the Binary Input Primitives target now
// exists as a thin re-export shim for source-compatibility.
@_exported public import Byte_Parser_Primitives
