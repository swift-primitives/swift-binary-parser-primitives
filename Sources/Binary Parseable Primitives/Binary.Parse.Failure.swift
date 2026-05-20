// Binary.Parse.Failure.swift
// Typed failure for Binary.Parseable.parse(from:) implementations.

public import Binary_Parse_Primitives

extension Binary.Parse {
    /// Typed failure for ``Binary/Parseable/parse(from:)`` implementations.
    ///
    /// Sibling-namespaced typed error for during-parse defects. Distinct from
    /// ``Binary/Parse/Error``, which is a whole-buffer post-condition check
    /// (`.end(remaining:)`). The two complement each other: callers compose
    /// `try X.parse(from: &buf)` for during-parse failures, then check
    /// `buf.isEmpty` or throw `Binary.Parse.Error.end(remaining:)` for any
    /// unconsumed tail.
    public enum Failure: Swift.Error, Sendable, Equatable {
        /// Source had fewer bytes than required.
        case insufficient(needed: Int)
        /// Source bytes were structurally malformed for this type.
        case malformed
        /// Parsed raw value did not initialize a valid instance of `Self`.
        case outOfRange
    }
}
