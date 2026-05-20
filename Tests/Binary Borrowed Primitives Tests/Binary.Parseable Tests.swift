// Binary.Parseable Tests.swift
// swift-binary-primitives
//
// Tests demonstrating the Binary.Parseable protocol for byte deserialization
// and round-trip identity with Binary.Serializable.

import Binary_Parseable_Primitives
import Binary_Primitives_Test_Support
import Testing

@testable import Binary_Parseable_Primitives

@Suite("Binary.Parseable")
struct BinaryParseableTests {

    // MARK: - Round-trip identity

    @Test("UInt32 round-trip preserves value (little-endian)")
    func uint32RoundTripLittleEndian() throws {
        let original: UInt32 = 0x1234_5678
        let bytes = original.bytes(endianness: .little)
        #expect(bytes == [0x78, 0x56, 0x34, 0x12])
        let decoded = try #require(UInt32(bytes: bytes, endianness: .little))
        #expect(decoded == original)
    }

    @Test("UInt32 round-trip preserves value (big-endian)")
    func uint32RoundTripBigEndian() throws {
        let original: UInt32 = 0x1234_5678
        let bytes = original.bytes(endianness: .big)
        #expect(bytes == [0x12, 0x34, 0x56, 0x78])
        let decoded = try #require(UInt32(bytes: bytes, endianness: .big))
        #expect(decoded == original)
    }

    // MARK: - Endianness asymmetry

    @Test("UInt32 little- and big-endian byte arrays differ")
    func uint32EndiannessDiffers() {
        let v: UInt32 = 0x1234_5678
        let le = v.bytes(endianness: .little)
        let be = v.bytes(endianness: .big)
        #expect(le != be)
        #expect(le.reversed() == be)
    }

    @Test("Decoding with wrong endianness yields wrong value")
    func uint32WrongEndianness() throws {
        let original: UInt32 = 0x1234_5678
        let leBytes = original.bytes(endianness: .little)
        let asBE = try #require(UInt32(bytes: leBytes, endianness: .big))
        #expect(asBE == 0x7856_3412) // byte-reversed interpretation
        #expect(asBE != original)
    }

    @Test("UInt32 init returns nil on wrong byte count")
    func uint32WrongLength() {
        let tooFew: [Byte] = [0x12, 0x34]
        #expect(UInt32(bytes: tooFew, endianness: .big) == nil)
    }

    // MARK: - parse(from:) cursor semantics

    @Test("UInt32.parse(from:) decodes little-endian and consumes 4 bytes")
    func uint32ParseFromLittleEndian() throws {
        var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
        let value = try UInt32.parse(from: &bytes)
        #expect(value == 0x1234_5678)
        #expect(bytes.isEmpty)
    }

    @Test("UInt32.parse(from:) advances cursor past consumed bytes")
    func uint32ParseFromAdvancesCursor() throws {
        var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12, 0xAA, 0xBB]
        let value = try UInt32.parse(from: &bytes)
        #expect(value == 0x1234_5678)
        #expect(bytes == [0xAA, 0xBB])
    }

    @Test("UInt32.parse(from:) throws .insufficient when source is short")
    func uint32ParseFromInsufficient() {
        var bytes: [Byte] = [0x12, 0x34]
        #expect(throws: Binary.Parse.Failure.insufficient(needed: 4)) {
            _ = try UInt32.parse(from: &bytes)
        }
    }

    // MARK: - Round-trip via Serializable + Parseable

    @Test("UInt32 round-trip Serializable → Parseable (little-endian)")
    func uint32RoundTripSerializeParseLittle() throws {
        let original: UInt32 = 0x1234_5678
        var buffer: [Byte] = []
        buffer.append(contentsOf: original.bytes(endianness: .little))
        let decoded = try UInt32.parse(from: &buffer)
        #expect(decoded == original)
        #expect(buffer.isEmpty)
    }

    @Test("UInt32 round-trip via raw .little encoding then .little parse")
    func uint32RoundTripLittleEndianViaParse() throws {
        let original: UInt32 = 0xDEAD_BEEF
        var buffer: [Byte] = Array<Byte>(original.bytes(endianness: .little))
        let decoded = try UInt32.parse(from: &buffer)
        #expect(decoded == original)
    }

    @Test("UInt32 round-trip via raw .big encoding then explicit .big parse")
    func uint32RoundTripBigEndianViaInit() throws {
        let original: UInt32 = 0xDEAD_BEEF
        let bytes = original.bytes(endianness: .big)
        let decoded = try #require(UInt32(bytes: bytes, endianness: .big))
        #expect(decoded == original)
    }

    // Dual-conformance witness test (DualWord: Binary.Serializable + Binary.Parseable)
    // moved to swift-binary-serializer-primitives Tests when Binary Serializable
    // Primitives relocated. Single-conformance Binary.Parseable witnessing on
    // UInt32 continues in this file's other tests.

    // MARK: - Byte-collection conformances

    @Test("Array<Byte>.parse consumes all remaining bytes")
    func arrayBytesParse() throws {
        var source: [Byte] = [0x01, 0x02, 0x03, 0x04]
        let decoded = try [Byte].parse(from: &source)
        #expect(decoded == [0x01, 0x02, 0x03, 0x04])
        #expect(source.isEmpty)
    }

    @Test("ContiguousArray<Byte>.parse consumes all remaining bytes")
    func contiguousArrayBytesParse() throws {
        var source: [Byte] = [0xAA, 0xBB, 0xCC]
        let decoded = try ContiguousArray<Byte>.parse(from: &source)
        let expected: [Byte] = [0xAA, 0xBB, 0xCC]
        #expect(Array<Byte>(decoded) == expected)
        #expect(source.isEmpty)
    }

    @Test("ArraySlice<Byte>.parse consumes all remaining bytes")
    func arraySliceBytesParse() throws {
        var source: [Byte] = [0xDE, 0xAD, 0xBE, 0xEF]
        let decoded = try ArraySlice<Byte>.parse(from: &source)
        let expected: [Byte] = [0xDE, 0xAD, 0xBE, 0xEF]
        #expect(Array<Byte>(decoded) == expected)
        #expect(source.isEmpty)
    }
}
