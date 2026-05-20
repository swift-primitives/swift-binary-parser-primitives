import Binary_LEB128_Parser_Primitives
import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Testing

@testable import Binary_Parser_Primitives

// MARK: - Binary.LEB128.Unsigned Tests

// Note: Binary.LEB128.Unsigned<T> is generic, so per [TEST-004] we use
// parallel namespace pattern instead of type extension pattern.

@Suite("Binary.LEB128.Unsigned")
struct LEB128UnsignedTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unsigned Unit Tests

extension LEB128UnsignedTests.Unit {

    @Test
    func `parse single byte value`() throws {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x00][...]

        let value = try parser.parse(&input)

        #expect(value == 0)
        #expect(input.isEmpty)
    }

    @Test
    func `parse single byte max value`() throws {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x7F][...]

        let value = try parser.parse(&input)

        #expect(value == 127)
    }

    @Test
    func `parse two byte value`() throws {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x80, 0x01][...]

        let value = try parser.parse(&input)

        #expect(value == 128)
    }

    @Test
    func `parse known value 624485`() throws {
        // 624485 encodes as [0xE5, 0x8E, 0x26]
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0xE5, 0x8E, 0x26][...]

        let value = try parser.parse(&input)

        #expect(value == 624485)
    }

    @Test
    func `parse consumes only needed bytes`() throws {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x7F, 0xAA, 0xBB][...]

        let value = try parser.parse(&input)

        #expect(value == 127)
        #expect(input.count == 2)
    }

    @Test
    func `parse UInt8 max value`() throws {
        let parser = Binary.LEB128.Unsigned<UInt8>()
        var input: ArraySlice<Byte> = [0xFF, 0x01][...]

        let value = try parser.parse(&input)

        #expect(value == 255)
    }

    @Test
    func `parse UInt16 max value`() throws {
        let parser = Binary.LEB128.Unsigned<UInt16>()
        var input: ArraySlice<Byte> = [0xFF, 0xFF, 0x03][...]

        let value = try parser.parse(&input)

        #expect(value == 65535)
    }
}

// MARK: - Unsigned EdgeCase Tests

extension LEB128UnsignedTests.EdgeCase {

    @Test
    func `parse empty input throws unterminated`() {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [][...]

        #expect(throws: Binary.LEB128.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parse unterminated sequence throws`() {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x80][...]  // continuation bit set, no following byte

        #expect(throws: Binary.LEB128.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parse overflow throws for UInt8`() {
        let parser = Binary.LEB128.Unsigned<UInt8>()
        var input: ArraySlice<Byte> = [0x80, 0x02][...]  // 256, overflows UInt8

        #expect(throws: Binary.LEB128.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parse zero`() throws {
        let parser = Binary.LEB128.Unsigned<UInt64>()
        var input: ArraySlice<Byte> = [0x00][...]

        let value = try parser.parse(&input)

        #expect(value == 0)
    }
}

// MARK: - Binary.LEB128.Signed Tests

// Note: Binary.LEB128.Signed<T> is generic, so per [TEST-004] we use
// parallel namespace pattern instead of type extension pattern.

@Suite("Binary.LEB128.Signed")
struct LEB128SignedTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Signed Unit Tests

extension LEB128SignedTests.Unit {

    @Test
    func `parse zero`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x00][...]

        let value = try parser.parse(&input)

        #expect(value == 0)
    }

    @Test
    func `parse positive single byte`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x3F][...]  // 63

        let value = try parser.parse(&input)

        #expect(value == 63)
    }

    @Test
    func `parse negative one`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x7F][...]

        let value = try parser.parse(&input)

        #expect(value == -1)
    }

    @Test
    func `parse negative two`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x7E][...]

        let value = try parser.parse(&input)

        #expect(value == -2)
    }

    @Test
    func `parse positive two byte value`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x80, 0x01][...]  // 128

        let value = try parser.parse(&input)

        #expect(value == 128)
    }

    @Test
    func `parse negative 128`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x80, 0x7F][...]

        let value = try parser.parse(&input)

        #expect(value == -128)
    }

    @Test
    func `parse consumes only needed bytes`() throws {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x00, 0xFF, 0xFF][...]

        let value = try parser.parse(&input)

        #expect(value == 0)
        #expect(input.count == 2)
    }
}

// MARK: - Signed EdgeCase Tests

extension LEB128SignedTests.EdgeCase {

    @Test
    func `parse empty input throws unterminated`() {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [][...]

        #expect(throws: Binary.LEB128.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parse unterminated sequence throws`() {
        let parser = Binary.LEB128.Signed<Int64>()
        var input: ArraySlice<Byte> = [0x80][...]

        #expect(throws: Binary.LEB128.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `parse Int8 min value`() throws {
        let parser = Binary.LEB128.Signed<Int8>()
        var input: ArraySlice<Byte> = [0x80, 0x7F][...]  // -128

        let value = try parser.parse(&input)

        #expect(value == -128)
    }

    @Test
    func `parse Int8 max value`() throws {
        let parser = Binary.LEB128.Signed<Int8>()
        var input: ArraySlice<Byte> = [0xFF, 0x00][...]  // 127

        let value = try parser.parse(&input)

        #expect(value == 127)
    }
}
