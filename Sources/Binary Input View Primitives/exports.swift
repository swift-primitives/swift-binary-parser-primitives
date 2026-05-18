@_exported public import Binary_Input_Primitives
// Byte.Input.View (= Cursor<Byte>) and its byte-domain extensions live in
// byte-parser-primitives per the 2026-05-18 binary-bytes-input-removal arc.
// Re-export Byte_Parser_Primitives so consumers of Binary Input View
// Primitives see the View type and its API. Binary_Input_Primitives's own
// exports.swift also re-exports Byte_Parser_Primitives transitively, so
// this is a defense-in-depth re-export.
@_exported public import Byte_Parser_Primitives
