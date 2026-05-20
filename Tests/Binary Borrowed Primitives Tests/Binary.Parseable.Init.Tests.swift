// Binary.Parseable.UInt8.Tests.swift
//
// Tests for the endianness-aware init?(bytes:endianness:) on
// Binary.Parseable conformers with FixedWidthInteger RawValue. The init is
// byte-domain ([Byte]) only post-W2 byte cascade; the prior @_disfavoredOverload
// UInt8 forwarder was deleted as redundant migration-debt baggage. Callers
// holding `[UInt8]` bridge via `Array<Byte>(uint8s)` at the call site.

import Binary_Parseable_Primitives
import Testing

private struct Word: RawRepresentable, Binary.Parseable {
    var rawValue: UInt32
    init?(rawValue: UInt32) { self.rawValue = rawValue }
    init(_ raw: UInt32) { self.rawValue = raw }
}

@Suite("Binary.Parseable init?(bytes:endianness:)")
struct BinaryParseableInitBytesTests {

    @Test
    func `init?(bytes: [Byte], endianness:) decodes little-endian`() throws {
        let bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
        let word = try #require(Word(bytes: bytes, endianness: .little))
        #expect(word.rawValue == 0x1234_5678)
    }

    @Test
    func `init?(bytes: [Byte], endianness:) decodes big-endian`() throws {
        let bytes: [Byte] = [0x12, 0x34, 0x56, 0x78]
        let word = try #require(Word(bytes: bytes, endianness: .big))
        #expect(word.rawValue == 0x1234_5678)
    }

    @Test
    func `init?(bytes: [Byte], endianness:) returns nil on wrong byte count`() {
        let tooFew: [Byte] = [0x12, 0x34]
        #expect(Word(bytes: tooFew, endianness: .little) == nil)
    }
}
