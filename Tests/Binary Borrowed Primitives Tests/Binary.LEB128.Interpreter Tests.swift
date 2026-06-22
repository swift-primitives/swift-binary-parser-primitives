// Binary.LEB128.Interpreter Tests.swift
// swift-binary-parser-primitives
//
// Regression tests for the binary Machine `.uleb128`/`.sleb128` instructions,
// exercised through the borrowed byte-span interpreter — the parse* family on
// `Span.\`Protocol\` where Element == Byte` (a `Swift.Span<Byte>` obtained from
// `[Byte].span`). These instruction paths route through the shared
// Binary.LEB128.Decode core, so these tests pin that the re-point is
// behavior-preserving and that the core's overflow maps to Binary.Machine.Fault.
//
// The owned executor (Binary.Machine.Run) carries the byte-identical re-pointed
// logic over a different byte source and is compile-verified; it delegates to
// the same core, which is independently unit-tested in swift-binary-leb128-primitives.

import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Testing
// The parse engine attaches to `Span.\`Protocol\` where Element == Byte`; calling
// `someByteSpan.parse(...)` needs the `Swift.Span: Span.\`Protocol\`` conformance.
import Span_Protocol_Primitives

@testable import Binary_Parser_Primitives

@Suite("Binary.LEB128 Interpreter")
struct BinaryLEB128InterpreterTests {
    @Suite struct Prefix {}  // via byte-span parse (prefix)
    @Suite struct Whole {}   // via byte-span parseWhole (exact-length)
}

// MARK: - via byte-span parse (prefix)

extension BinaryLEB128InterpreterTests.Prefix {

    @Test
    func `uleb128 decodes known sequences`() throws {
        #expect(try ([0x00] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 0)
        #expect(try ([0x7F] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 127)
        #expect(try ([0x80, 0x01] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 128)
        #expect(try ([0xE5, 0x8E, 0x26] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 624485)
    }

    @Test
    func `sleb128 decodes known sequences`() throws {
        #expect(try ([0x00] as [Byte]).span.parse(Binary.Machine.sleb128Parser()) == 0)
        #expect(try ([0x7F] as [Byte]).span.parse(Binary.Machine.sleb128Parser()) == -1)
        #expect(try ([0x80, 0x7F] as [Byte]).span.parse(Binary.Machine.sleb128Parser()) == -128)
    }

    @Test
    func `uleb128 round-trips with the encoder`() throws {
        for v in [0, 1, 624485, UInt64.max] as [UInt64] {
            #expect(try ([Byte](leb128: v)).span.parse(Binary.Machine.uleb128Parser()) == v)
        }
    }

    @Test
    func `sleb128 round-trips with the encoder`() throws {
        for v in [0, 1, -1, -624485, Int64.min, Int64.max] as [Int64] {
            #expect(try ([Byte](leb128: v)).span.parse(Binary.Machine.sleb128Parser()) == v)
        }
    }

    @Test
    func `uleb128 over-long encoding faults`() {
        // 11-byte uleb (a byte past bit 64) is over-long under the strict core.
        let overLong = [Byte](repeating: 0x80, count: 10) + [0x01]
        do {
            _ = try overLong.span.parse(Binary.Machine.uleb128Parser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {
            // expected: over-long uleb faults under the strict core
        }
    }

    @Test
    func `uleb128 unterminated faults`() {
        let bytes: [Byte] = [0x80, 0x80]
        do {
            _ = try bytes.span.parse(Binary.Machine.uleb128Parser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {
            // expected: unterminated uleb faults
        }
    }
}

// MARK: - via byte-span parseWhole (exact-length)

extension BinaryLEB128InterpreterTests.Whole {

    @Test
    func `uleb128 decodes via parseWhole`() throws {
        #expect(try ([0xE5, 0x8E, 0x26] as [Byte]).span.parseWhole(Binary.Machine.uleb128Parser()) == 624485)
    }

    @Test
    func `sleb128 decodes via parseWhole`() throws {
        #expect(try ([0x80, 0x7F] as [Byte]).span.parseWhole(Binary.Machine.sleb128Parser()) == -128)
    }

    @Test
    func `uleb128 round-trips via parseWhole`() throws {
        for u in [0, 1, 624485, UInt64.max] as [UInt64] {
            #expect(try ([Byte](leb128: u)).span.parseWhole(Binary.Machine.uleb128Parser()) == u)
        }
    }

    @Test
    func `sleb128 round-trips via parseWhole`() throws {
        for s in [0, 1, -1, -624485, Int64.min, Int64.max] as [Int64] {
            #expect(try ([Byte](leb128: s)).span.parseWhole(Binary.Machine.sleb128Parser()) == s)
        }
    }
}
