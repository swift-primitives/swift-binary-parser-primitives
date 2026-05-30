// Binary.LEB128.Interpreter Tests.swift
// swift-binary-parser-primitives
//
// Regression tests for the binary Machine `.uleb128`/`.sleb128` instructions,
// exercised through the borrowed interpreter (Binary.parse / Binary.view.*).
// These instruction paths were previously untested; they now route through the
// shared Binary.LEB128.Decode core, so these tests pin that the re-point is
// behavior-preserving and that the core's overflow maps to Binary.Machine.Fault.
//
// The owned executor (Binary.Machine.Run) carries the byte-identical re-pointed
// logic over a different byte source and is compile-verified; it delegates to
// the same core, which is independently unit-tested in swift-binary-leb128-primitives.

import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Testing

@testable import Binary_Parser_Primitives

@Suite("Binary.LEB128 Interpreter")
struct BinaryLEB128InterpreterTests {
    @Suite struct Prefix {}  // via Binary.parse (prefix)
    @Suite struct Whole {}   // via Binary.view.parseWhole (exact-length)
}

// MARK: - via Binary.parse (prefix)

extension BinaryLEB128InterpreterTests.Prefix {

    @Test
    func `uleb128 decodes known sequences`() throws {
        #expect(try Binary([0x00] as [Byte]).parse(Binary.Machine.uleb128Parser()) == 0)
        #expect(try Binary([0x7F] as [Byte]).parse(Binary.Machine.uleb128Parser()) == 127)
        #expect(try Binary([0x80, 0x01] as [Byte]).parse(Binary.Machine.uleb128Parser()) == 128)
        #expect(try Binary([0xE5, 0x8E, 0x26] as [Byte]).parse(Binary.Machine.uleb128Parser()) == 624485)
    }

    @Test
    func `sleb128 decodes known sequences`() throws {
        #expect(try Binary([0x00] as [Byte]).parse(Binary.Machine.sleb128Parser()) == 0)
        #expect(try Binary([0x7F] as [Byte]).parse(Binary.Machine.sleb128Parser()) == -1)
        #expect(try Binary([0x80, 0x7F] as [Byte]).parse(Binary.Machine.sleb128Parser()) == -128)
    }

    @Test
    func `uleb128 round-trips with the encoder`() throws {
        for v in [0, 1, 624485, UInt64.max] as [UInt64] {
            #expect(try Binary([Byte](leb128: v)).parse(Binary.Machine.uleb128Parser()) == v)
        }
    }

    @Test
    func `sleb128 round-trips with the encoder`() throws {
        for v in [0, 1, -1, -624485, Int64.min, Int64.max] as [Int64] {
            #expect(try Binary([Byte](leb128: v)).parse(Binary.Machine.sleb128Parser()) == v)
        }
    }

    @Test
    func `uleb128 over-long encoding faults`() {
        // 11-byte uleb (a byte past bit 64) is over-long under the strict core.
        let overLong = [Byte](repeating: 0x80, count: 10) + [0x01]
        #expect(throws: Binary.Machine.Fault.self) {
            try Binary(overLong).parse(Binary.Machine.uleb128Parser())
        }
    }

    @Test
    func `uleb128 unterminated faults`() {
        #expect(throws: Binary.Machine.Fault.self) {
            try Binary([0x80, 0x80] as [Byte]).parse(Binary.Machine.uleb128Parser())
        }
    }
}

// MARK: - via Binary.view.parseWhole (exact-length)

extension BinaryLEB128InterpreterTests.Whole {

    @Test
    func `uleb128 decodes via parseWhole`() throws {
        #expect(try Binary([0xE5, 0x8E, 0x26] as [Byte]).view.parseWhole(Binary.Machine.uleb128Parser()) == 624485)
    }

    @Test
    func `sleb128 decodes via parseWhole`() throws {
        #expect(try Binary([0x80, 0x7F] as [Byte]).view.parseWhole(Binary.Machine.sleb128Parser()) == -128)
    }

    @Test
    func `uleb128 round-trips via parseWhole`() throws {
        for u in [0, 1, 624485, UInt64.max] as [UInt64] {
            #expect(try Binary([Byte](leb128: u)).view.parseWhole(Binary.Machine.uleb128Parser()) == u)
        }
    }

    @Test
    func `sleb128 round-trips via parseWhole`() throws {
        for s in [0, 1, -1, -624485, Int64.min, Int64.max] as [Int64] {
            #expect(try Binary([Byte](leb128: s)).view.parseWhole(Binary.Machine.sleb128Parser()) == s)
        }
    }
}
