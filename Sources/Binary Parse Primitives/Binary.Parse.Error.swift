// Binary.Parse.Error.swift
// swift-binary-parser-primitives
//
// Error type for whole-buffer parsing — indicates parsing succeeded but
// bytes remain unconsumed (post-condition validation). Used by
// `Binary.Parse.Access.whole(_:)` in this same target.
//
// Relocated from swift-binary-primitives 2026-05-20 — the Parse error is
// a parser-domain post-condition concept, not a binary-domain primitive.

public import Byte_Primitives
public import Index_Primitives

extension Binary.Parse {
    /// Error indicating parsing did not consume entire input.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Parsing succeeded but bytes remain.
        ///
        /// - Parameter remaining: The number of unconsumed bytes.
        case end(remaining: Index<Byte>.Count)
    }
}
