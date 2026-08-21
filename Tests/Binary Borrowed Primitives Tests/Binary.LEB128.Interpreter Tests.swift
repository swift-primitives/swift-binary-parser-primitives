import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Span_Protocol_Primitives
import Testing

@testable import Binary_Parser_Primitives

@Suite("Binary.LEB128 Interpreter")
struct BinaryLEB128InterpreterTests {
    @Suite struct Prefix {}
    @Suite struct Whole {}
}

extension BinaryLEB128InterpreterTests.Prefix {

    @Test
    func `uleb128 decodes known sequences`() throws {
        #expect(try ([0x00] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 0)
        #expect(try ([0x7F] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 127)
        #expect(try ([0x80, 0x01] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 128)
        #expect(
            try ([0xE5, 0x8E, 0x26] as [Byte]).span.parse(Binary.Machine.uleb128Parser()) == 624485
        )
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

        let overLong = [Byte](repeating: 0x80, count: 10) + [0x01]
        do throws(Binary.Machine.Fault) {
            _ = try overLong.span.parse(Binary.Machine.uleb128Parser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {

        }
    }

    @Test
    func `uleb128 unterminated faults`() {
        let bytes: [Byte] = [0x80, 0x80]
        do throws(Binary.Machine.Fault) {
            _ = try bytes.span.parse(Binary.Machine.uleb128Parser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {

        }
    }
}

extension BinaryLEB128InterpreterTests.Whole {

    @Test
    func `uleb128 decodes via parseWhole`() throws {
        #expect(
            try ([0xE5, 0x8E, 0x26] as [Byte]).span.parseWhole(Binary.Machine.uleb128Parser())
                == 624485
        )
    }

    @Test
    func `sleb128 decodes via parseWhole`() throws {
        #expect(
            try ([0x80, 0x7F] as [Byte]).span.parseWhole(Binary.Machine.sleb128Parser()) == -128
        )
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
