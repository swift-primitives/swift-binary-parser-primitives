import Binary_Parser_Primitives_Test_Support
import Testing

@testable import Binary_Parser_Primitives

// MARK: - Integer Coder Tests

@Suite("Integer Coders")
struct IntegerCoderTests {
    @Suite struct UInt8Tests {}
    @Suite struct UInt16Tests {}
    @Suite struct UInt32Tests {}
    @Suite struct UInt64Tests {}
    @Suite struct Int8Tests {}
    @Suite struct Int16Tests {}
    @Suite struct Int32Tests {}
    @Suite struct Int64Tests {}
}

// MARK: - UInt8 Tests

extension IntegerCoderTests.UInt8Tests {

    @Test
    func `decode single byte`() throws {
        let coder = UInt8.coder(endianness: .big)

        let value = try coder.decodeWhole([0x42])

        #expect(value == 0x42)
    }

    @Test
    func `encode single byte`() {
        let coder = UInt8.coder(endianness: .big)

        let bytes = coder.encodeToArray(0x42)

        #expect(bytes == [0x42])
    }

    @Test
    func `round trip`() throws {
        let coder = UInt8.coder(endianness: .big)
        let original: UInt8 = 0xFF

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }

    @Test
    func `decode zero`() throws {
        let coder = UInt8.coder(endianness: .big)

        let value = try coder.decodeWhole([0x00])

        #expect(value == 0)
    }

    @Test
    func `decode max value`() throws {
        let coder = UInt8.coder(endianness: .big)

        let value = try coder.decodeWhole([0xFF])

        #expect(value == UInt8.max)
    }
}

// MARK: - UInt16 Tests

extension IntegerCoderTests.UInt16Tests {

    @Test
    func `decode big endian`() throws {
        let coder = UInt16.coder(endianness: .big)

        let value = try coder.decodeWhole([0x12, 0x34])

        #expect(value == 0x1234)
    }

    @Test
    func `decode little endian`() throws {
        let coder = UInt16.coder(endianness: .little)

        let value = try coder.decodeWhole([0x34, 0x12])

        #expect(value == 0x1234)
    }

    @Test
    func `encode big endian`() {
        let coder = UInt16.coder(endianness: .big)

        let bytes = coder.encodeToArray(0x1234)

        #expect(bytes == [0x12, 0x34])
    }

    @Test
    func `encode little endian`() {
        let coder = UInt16.coder(endianness: .little)

        let bytes = coder.encodeToArray(0x1234)

        #expect(bytes == [0x34, 0x12])
    }

    @Test
    func `round trip big endian`() throws {
        let coder = UInt16.coder(endianness: .big)
        let original: UInt16 = 0xABCD

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }

    @Test
    func `round trip little endian`() throws {
        let coder = UInt16.coder(endianness: .little)
        let original: UInt16 = 0xABCD

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - UInt32 Tests

extension IntegerCoderTests.UInt32Tests {

    @Test
    func `decode big endian`() throws {
        let coder = UInt32.coder(endianness: .big)

        let value = try coder.decodeWhole([0xDE, 0xAD, 0xBE, 0xEF])

        #expect(value == 0xDEAD_BEEF)
    }

    @Test
    func `decode little endian`() throws {
        let coder = UInt32.coder(endianness: .little)

        let value = try coder.decodeWhole([0xEF, 0xBE, 0xAD, 0xDE])

        #expect(value == 0xDEAD_BEEF)
    }

    @Test
    func `encode big endian`() {
        let coder = UInt32.coder(endianness: .big)

        let bytes = coder.encodeToArray(0xDEAD_BEEF)

        #expect(bytes == [0xDE, 0xAD, 0xBE, 0xEF])
    }

    @Test
    func `encode little endian`() {
        let coder = UInt32.coder(endianness: .little)

        let bytes = coder.encodeToArray(0xDEAD_BEEF)

        #expect(bytes == [0xEF, 0xBE, 0xAD, 0xDE])
    }

    @Test
    func `round trip`() throws {
        let coder = UInt32.coder(endianness: .big)
        let original: UInt32 = 0xCAFE_BABE

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - UInt64 Tests

extension IntegerCoderTests.UInt64Tests {

    @Test
    func `decode big endian`() throws {
        let coder = UInt64.coder(endianness: .big)

        let value = try coder.decodeWhole([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])

        #expect(value == 0x0123_4567_89AB_CDEF)
    }

    @Test
    func `decode little endian`() throws {
        let coder = UInt64.coder(endianness: .little)

        let value = try coder.decodeWhole([0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01])

        #expect(value == 0x0123_4567_89AB_CDEF)
    }

    @Test
    func `round trip`() throws {
        let coder = UInt64.coder(endianness: .big)
        let original: UInt64 = UInt64.max

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - Int8 Tests

extension IntegerCoderTests.Int8Tests {

    @Test
    func `decode positive value`() throws {
        let coder = Int8.coder(endianness: .big)

        let value = try coder.decodeWhole([0x7F])

        #expect(value == 127)
    }

    @Test
    func `decode negative value`() throws {
        let coder = Int8.coder(endianness: .big)

        let value = try coder.decodeWhole([0xFF])

        #expect(value == -1)
    }

    @Test
    func `decode min value`() throws {
        let coder = Int8.coder(endianness: .big)

        let value = try coder.decodeWhole([0x80])

        #expect(value == Int8.min)
    }

    @Test
    func `round trip`() throws {
        let coder = Int8.coder(endianness: .big)
        let original: Int8 = -42

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - Int16 Tests

extension IntegerCoderTests.Int16Tests {

    @Test
    func `decode positive big endian`() throws {
        let coder = Int16.coder(endianness: .big)

        let value = try coder.decodeWhole([0x00, 0x7F])

        #expect(value == 127)
    }

    @Test
    func `decode negative big endian`() throws {
        let coder = Int16.coder(endianness: .big)

        let value = try coder.decodeWhole([0xFF, 0xFF])

        #expect(value == -1)
    }

    @Test
    func `round trip`() throws {
        let coder = Int16.coder(endianness: .little)
        let original: Int16 = -1234

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - Int32 Tests

extension IntegerCoderTests.Int32Tests {

    @Test
    func `decode negative value big endian`() throws {
        let coder = Int32.coder(endianness: .big)

        let value = try coder.decodeWhole([0xFF, 0xFF, 0xFF, 0xFF])

        #expect(value == -1)
    }

    @Test
    func `round trip`() throws {
        let coder = Int32.coder(endianness: .big)
        let original: Int32 = Int32.min

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}

// MARK: - Int64 Tests

extension IntegerCoderTests.Int64Tests {

    @Test
    func `decode max value`() throws {
        let coder = Int64.coder(endianness: .big)

        let value = try coder.decodeWhole([0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])

        #expect(value == Int64.max)
    }

    @Test
    func `decode min value`() throws {
        let coder = Int64.coder(endianness: .big)

        let value = try coder.decodeWhole([0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

        #expect(value == Int64.min)
    }

    @Test
    func `round trip`() throws {
        let coder = Int64.coder(endianness: .little)
        let original: Int64 = -9_876_543_210

        let encoded = coder.encodeToArray(original)
        let decoded = try coder.decodeWhole(encoded)

        #expect(decoded == original)
    }
}
