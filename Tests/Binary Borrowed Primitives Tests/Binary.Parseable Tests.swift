// Binary.Parseable Tests.swift
// swift-binary-primitives
//
// Tests demonstrating the Binary.Parseable protocol for byte deserialization
// and round-trip identity with Binary.Serializable.

import Binary_Primitives_Test_Support
import Testing

@testable import Binary_Parseable_Primitives

@Suite("Binary.Parseable")
struct BinaryParseableTests {

    // MARK: - Round-trip identity

    @Test
    func `UInt32 round-trip preserves value (little-endian)`() throws {
        let original: UInt32 = 0x1234_5678
        let bytes = original.bytes(endianness: .little)
        #expect(bytes == [0x78, 0x56, 0x34, 0x12])
        let decoded = try #require(UInt32(bytes: bytes, endianness: .little))
        #expect(decoded == original)
    }

    @Test
    func `UInt32 round-trip preserves value (big-endian)`() throws {
        let original: UInt32 = 0x1234_5678
        let bytes = original.bytes(endianness: .big)
        #expect(bytes == [0x12, 0x34, 0x56, 0x78])
        let decoded = try #require(UInt32(bytes: bytes, endianness: .big))
        #expect(decoded == original)
    }

    // MARK: - Endianness asymmetry

    @Test
    func `UInt32 little- and big-endian byte arrays differ`() {
        let v: UInt32 = 0x1234_5678
        let le = v.bytes(endianness: .little)
        let be = v.bytes(endianness: .big)
        #expect(le != be)
        #expect(le.reversed() == be)
    }

    @Test
    func `Decoding with wrong endianness yields wrong value`() throws {
        let original: UInt32 = 0x1234_5678
        let leBytes = original.bytes(endianness: .little)
        let asBE = try #require(UInt32(bytes: leBytes, endianness: .big))
        #expect(asBE == 0x7856_3412)  // byte-reversed interpretation
        #expect(asBE != original)
    }

    @Test
    func `UInt32 init returns nil on wrong byte count`() {
        let tooFew: [Byte] = [0x12, 0x34]
        #expect(UInt32(bytes: tooFew, endianness: .big) == nil)
    }

    // MARK: - parse(from:) cursor semantics

    @Test
    func `UInt32.parse(from:) decodes little-endian and consumes 4 bytes`() throws {
        var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
        let value = try UInt32.parse(from: &bytes)
        #expect(value == 0x1234_5678)
        #expect(bytes.isEmpty)
    }

    @Test
    func `UInt32.parse(from:) advances cursor past consumed bytes`() throws {
        var bytes: [Byte] = [0x78, 0x56, 0x34, 0x12, 0xAA, 0xBB]
        let value = try UInt32.parse(from: &bytes)
        #expect(value == 0x1234_5678)
        #expect(bytes == [0xAA, 0xBB])
    }

    @Test
    func `UInt32.parse(from:) throws .insufficient when source is short`() {
        var bytes: [Byte] = [0x12, 0x34]
        #expect(throws: Binary.Parse.Failure.insufficient(needed: 4)) {
            _ = try UInt32.parse(from: &bytes)
        }
    }

    // MARK: - Round-trip via Serializable + Parseable

    @Test
    func `UInt32 round-trip Serializable → Parseable (little-endian)`() throws {
        let original: UInt32 = 0x1234_5678
        var buffer: [Byte] = []
        buffer.append(contentsOf: original.bytes(endianness: .little))
        let decoded = try UInt32.parse(from: &buffer)
        #expect(decoded == original)
        #expect(buffer.isEmpty)
    }

    @Test
    func `UInt32 round-trip via raw .little encoding then .little parse`() throws {
        let original: UInt32 = 0xDEAD_BEEF
        var buffer: [Byte] = original.bytes(endianness: .little)
        let decoded = try UInt32.parse(from: &buffer)
        #expect(decoded == original)
    }

    @Test
    func `UInt32 round-trip via raw .big encoding then explicit .big parse`() throws {
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

    @Test
    func `Array<Byte>.parse consumes all remaining bytes`() throws {
        var source: [Byte] = [0x01, 0x02, 0x03, 0x04]
        let decoded = try [Byte].parse(from: &source)
        #expect(decoded == [0x01, 0x02, 0x03, 0x04])
        #expect(source.isEmpty)
    }

    @Test
    func `ContiguousArray<Byte>.parse consumes all remaining bytes`() throws {
        var source: [Byte] = [0xAA, 0xBB, 0xCC]
        let decoded = try ContiguousArray<Byte>.parse(from: &source)
        let expected: [Byte] = [0xAA, 0xBB, 0xCC]
        #expect([Byte](decoded) == expected)
        #expect(source.isEmpty)
    }

    @Test
    func `ArraySlice<Byte>.parse consumes all remaining bytes`() throws {
        var source: [Byte] = [0xDE, 0xAD, 0xBE, 0xEF]
        let decoded = try ArraySlice<Byte>.parse(from: &source)
        let expected: [Byte] = [0xDE, 0xAD, 0xBE, 0xEF]
        #expect([Byte](decoded) == expected)
        #expect(source.isEmpty)
    }
}
