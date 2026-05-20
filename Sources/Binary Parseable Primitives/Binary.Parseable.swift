// Binary.Parseable.swift
// Streaming byte deserialization protocol — symmetric peer of Binary.Serializable.

extension Binary {
    /// A type that can parse itself from a byte stream.
    ///
    /// Symmetric peer of ``Binary/Serializable``. Siblings are flat top-level
    /// protocols per family-Codable convention [FAM-001/006]: no associated
    /// types, no refinement of canonical-attachment protocols. Where
    /// ``Binary/Serializable`` writes bytes via `serialize(_:into:)`,
    /// `Binary.Parseable` reads bytes via `parse(from:)`.
    ///
    /// ## Symmetry with Binary.Serializable
    ///
    /// A type may conform to both protocols. The serialize side is naturally
    /// infallible (just append bytes); the parse side is naturally fallible
    /// (validate, bounds-check, throw on malformed/insufficient input).
    /// `parse(from:)` advances `source` past consumed bytes on success,
    /// providing cursor semantics atop the same `RangeReplaceableCollection`
    /// substrate `serialize(_:into:)` uses.
    ///
    /// ## Endianness
    ///
    /// Endianness is NOT a parameter on the protocol surface (see [FAM-005]).
    /// Multi-byte-word conformers may either pick a canonical endianness for
    /// the protocol requirement and expose alternates via convenience overloads,
    /// or use endianness-aware convenience inits provided by the integer
    /// RawRepresentable default extension (mirroring the FixedWidthInteger
    /// default extension on `Binary.Serializable`).
    ///
    /// ## Failure type
    ///
    /// The protocol's typed failure is ``Binary/Parse/Failure``, sibling to
    /// the existing ``Binary/Parse/Error`` (whole-buffer post-condition).
    /// Swift currently disallows types nested in protocols, so the failure
    /// lives at the ``Binary/Parse`` namespace alongside ``Binary/Parse/Error``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// extension UInt32: Binary.Parseable {
    ///     public static func parse<Source: RangeReplaceableCollection>(
    ///         from source: inout Source
    ///     ) throws(Binary.Parse.Failure) -> UInt32
    ///     where Source.Element == Byte {
    ///         // canonical little-endian; convenience overloads cover .big
    ///         guard source.count >= 4 else { throw .insufficient(needed: 4) }
    ///         let bytes = Array<UInt8>(source.prefix(4))
    ///         source.removeFirst(4)
    ///         return UInt32(bytes: bytes, endianness: .little)!
    ///     }
    /// }
    ///
    /// var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
    /// let value = try UInt32.parse(from: &bytes) // 0x12345678
    /// // bytes is now empty
    /// ```
    public protocol Parseable: Sendable {
        /// Parses a value from a byte source, consuming the prefix on success.
        ///
        /// On success, `source` is advanced past the bytes consumed by parsing
        /// (cursor semantics via `removeFirst`). On failure, `source` is
        /// unmodified.
        ///
        /// - Parameter source: A byte source. Acts as a cursor: parsing
        ///   consumes bytes from the front.
        /// - Returns: The parsed value.
        /// - Throws: ``Binary/Parse/Failure`` describing the parse defect.
        static func parse<Source: RangeReplaceableCollection>(
            from source: inout Source
        ) throws(Binary.Parse.Failure) -> Self
        where Source.Element == Byte
    }
}
