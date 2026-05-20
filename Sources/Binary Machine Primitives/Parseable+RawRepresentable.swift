// Parseable+RawRepresentable.swift
// swift-binary-parser-primitives
//
// Default canonical Parseable conformances for RawRepresentable types,
// ported from the OLD Binary.Parseable's FixedWidthIntegerRaw default. Lets
// consumers write 'extension X: Parseable {}' (empty) when X is
// RawRepresentable<FixedWidthInteger> — symmetric peer of the new
// Serializable+RawRepresentable defaults in swift-binary-serializer-primitives.
//
// The default reads `MemoryLayout<RawValue>.size` bytes in canonical
// little-endian (matching the OLD Binary.Parseable+FixedWidthIntegerRaw
// behavior; the asymmetry with Serializable's native-endian default is
// preserved verbatim). Multi-byte-word conformers wanting big-endian as
// canonical override `static var parser` directly.

public import Byte_Parser_Primitives

extension Parseable where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {
    public static var parser: Binary.Parser<Self> {
        Binary.Parser { input throws(Binary.Machine.Fault) in
            let size = MemoryLayout<RawValue>.size
            var bytes: [Byte] = []
            bytes.reserveCapacity(size)
            let needCount = Index<Byte>.Count(Cardinal(UInt(size)))
            for _ in 0..<size {
                guard !input.isEmpty else {
                    let have = Index<Byte>.Count(Cardinal(UInt(bytes.count)))
                    throw .insufficientBytes(need: needCount, have: have)
                }
                bytes.append(input.removeFirst())
            }
            guard let raw = RawValue(bytes: bytes, endianness: .little) else {
                throw .malformed
            }
            guard let value = Self(rawValue: raw) else {
                throw .outOfRange
            }
            return value
        }
    }
}
