// Binary.Parseable+FixedWidthIntegerRaw.swift
// Default parse implementation for integer-RawValue Parseable conformers.

extension Binary.Parseable where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {
    /// Default parse: canonical little-endian read of `MemoryLayout<RawValue>.size` bytes.
    ///
    /// Mirrors ``Binary/Serializable``'s integer-RawValue default at
    /// `Binary.Serializable.swift:263-280`. Conformers wanting big-endian as
    /// canonical override this static method.
    @inlinable
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Self
    where Source.Element == Byte {
        let size = MemoryLayout<RawValue>.size
        guard source.count >= size else { throw .insufficient(needed: size) }
        let bytes = [Byte](source.prefix(size))
        source.removeFirst(size)
        guard let raw = RawValue(bytes: bytes, endianness: .little) else {
            throw .malformed
        }
        guard let value = Self(rawValue: raw) else { throw .outOfRange }
        return value
    }

    /// Endianness-aware convenience init for integer-RawValue parseables.
    ///
    /// Parses exactly `MemoryLayout<RawValue>.size` bytes in the given order.
    /// Returns `nil` if byte count mismatches or the resulting raw value
    /// does not initialize a valid Self.
    @inlinable
    public init?(bytes: [Byte], endianness: Binary.Endianness = .little) {
        guard let raw = Self.RawValue(bytes: bytes, endianness: endianness) else {
            return nil
        }
        guard let value = Self(rawValue: raw) else {
            return nil
        }
        self = value
    }

    // Stdlib-interop UInt8 init forwarder lives in
    // `Binary Primitives Standard Library Integration` per [API-BYTE-007].
}
