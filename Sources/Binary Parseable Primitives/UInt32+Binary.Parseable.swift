// UInt32+Binary.Parseable.swift
// Binary.Parseable conformance for UInt32 (canonical little-endian).

extension UInt32: Binary.Parseable {
    /// Canonical little-endian parse for UInt32.
    ///
    /// For big-endian or runtime-selected endianness, callers compose
    /// `UInt32(bytes:endianness:)` (provided by the FixedWidthInteger
    /// integration in `Binary Primitives Core`) with manual cursor advancement.
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> UInt32
    where Source.Element == Byte {
        let size = MemoryLayout<UInt32>.size
        guard source.count >= size else { throw .insufficient(needed: size) }
        let bytes = [Byte](source.prefix(size))
        source.removeFirst(size)
        guard let value = UInt32(bytes: bytes, endianness: .little) else {
            throw .malformed
        }
        return value
    }
}
