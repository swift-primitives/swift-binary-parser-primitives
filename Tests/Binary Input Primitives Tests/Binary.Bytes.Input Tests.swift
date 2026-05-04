import Binary_Parser_Primitives_Test_Support
import Testing

@testable import Binary_Parser_Primitives

// MARK: - Binary.Bytes.Input Tests

extension Binary.Bytes.Input {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

// MARK: - Unit Tests

extension Binary.Bytes.Input.Test.Unit {

    // MARK: Initialization

    @Test
    func `init from Array creates input with correct count`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]
        let input = Binary.Bytes.Input(bytes)

        #expect(input.count == 3)
        #expect(!input.isEmpty)
    }

    @Test
    func `init from ArraySlice creates input with correct count`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        let slice = bytes[1..<4]
        let input = Binary.Bytes.Input(slice)

        #expect(input.count == 3)
    }

    @Test
    func `init from Collection preserves first byte`() {
        let bytes: [UInt8] = [0x41, 0x42, 0x43]
        let input = Binary.Bytes.Input(bytes)

        #expect(input.first == 0x41)
    }

    @Test
    func `init empty creates empty input`() {
        let input = Binary.Bytes.Input([])

        #expect(input.isEmpty)
        #expect(input.count == 0)
        #expect(input.first == nil)
    }

    // MARK: Properties

    @Test
    func `isEmpty returns true for empty input`() {
        let input = Binary.Bytes.Input([])

        #expect(input.isEmpty)
    }

    @Test
    func `isEmpty returns false for non-empty input`() {
        let input = Binary.Bytes.Input([0x01])

        #expect(!input.isEmpty)
    }

    @Test
    func `count returns correct value`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03, 0x04, 0x05])

        #expect(input.count == 5)
    }

    @Test
    func `first returns first byte`() {
        let input = Binary.Bytes.Input([0xAB, 0xCD, 0xEF])

        #expect(input.first == 0xAB)
    }

    @Test
    func `first returns nil for empty input`() {
        let input = Binary.Bytes.Input([])

        #expect(input.first == nil)
    }

    @Test
    func `consumedCount starts at zero`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        #expect(input.consumedCount == 0)
    }

    // MARK: Advance

    @Test
    func `advance removes and returns first byte`() throws {
        var input = Binary.Bytes.Input([0x41, 0x42, 0x43])

        let byte = try input.advance()

        #expect(byte == 0x41)
        #expect(input.count == 2)
        #expect(input.first == 0x42)
    }

    @Test
    func `advance updates consumedCount`() throws {
        var input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        _ = try input.advance()
        #expect(input.consumedCount == 1)

        _ = try input.advance()
        #expect(input.consumedCount == 2)
    }

    @Test
    func `advance by count skips multiple bytes`() {
        var input = Binary.Bytes.Input([0x01, 0x02, 0x03, 0x04, 0x05])

        input.advance(by: 3)

        #expect(input.count == 2)
        #expect(input.first == 0x04)
        #expect(input.consumedCount == 3)
    }

    @Test
    func `advance by zero is no-op`() {
        var input = Binary.Bytes.Input([0x01, 0x02])

        input.advance(by: 0)

        #expect(input.count == 2)
        #expect(input.consumedCount == 0)
    }

    @Test
    func `consuming all bytes makes input empty`() {
        var input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        input.advance(by: 3)

        #expect(input.isEmpty)
        #expect(input.first == nil)
        #expect(input.consumedCount == 3)
    }

    // MARK: Subscript

    @Test
    func `subscript accesses byte at offset`() {
        let input = Binary.Bytes.Input([0x10, 0x20, 0x30, 0x40])

        #expect(input[offset: 0] == 0x10)
        #expect(input[offset: 1] == 0x20)
        #expect(input[offset: 2] == 0x30)
        #expect(input[offset: 3] == 0x40)
    }

    @Test
    func `subscript respects consumed bytes`() throws {
        var input = Binary.Bytes.Input([0x10, 0x20, 0x30, 0x40])

        _ = try input.advance()

        #expect(input[offset: 0] == 0x20)
        #expect(input[offset: 1] == 0x30)
    }

    // MARK: Starts With

    @Test
    func `starts with returns true for matching prefix`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03, 0x04])

        #expect(input.starts(with: [0x01, 0x02]))
    }

    @Test
    func `starts with returns false for non-matching prefix`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        #expect(!input.starts(with: [0x01, 0x03]))
    }

    @Test
    func `starts with returns true for empty prefix`() {
        let input = Binary.Bytes.Input([0x01, 0x02])

        #expect(input.starts(with: []))
    }

    @Test
    func `starts with returns false when prefix longer than input`() {
        let input = Binary.Bytes.Input([0x01, 0x02])

        #expect(!input.starts(with: [0x01, 0x02, 0x03]))
    }

    @Test
    func `starts with returns true for exact match`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        #expect(input.starts(with: [0x01, 0x02, 0x03]))
    }

    @Test
    func `starts with respects consumed bytes`() throws {
        var input = Binary.Bytes.Input([0x01, 0x02, 0x03])

        _ = try input.advance()

        #expect(input.starts(with: [0x02, 0x03]))
        #expect(!input.starts(with: [0x01, 0x02]))
    }

    // MARK: Sendable

    @Test
    func `Input conforms to Sendable`() {
        let input = Binary.Bytes.Input([0x01, 0x02, 0x03])
        let _: any Sendable = input
    }
}

// MARK: - Edge Case Tests

extension Binary.Bytes.Input.Test.EdgeCase {

    @Test
    func `advance on empty input throws`() {
        var input = Binary.Bytes.Input([])

        #expect(throws: Input.Stream.Error.self) {
            try input.advance()
        }
    }

    @Test
    func `advance after consuming all bytes throws`() throws {
        var input = Binary.Bytes.Input([0x01])

        _ = try input.advance()

        #expect(throws: Input.Stream.Error.self) {
            try input.advance()
        }
    }

    @Test
    func `single byte input works correctly`() throws {
        var input = Binary.Bytes.Input([0xFF])

        #expect(input.count == 1)
        #expect(input.first == 0xFF)

        let byte = try input.advance()

        #expect(byte == 0xFF)
        #expect(input.isEmpty)
        #expect(input.consumedCount == 1)
    }
}

// MARK: - Integration Tests

extension Binary.Bytes.Input.Test.Integration {

    @Test
    func `consumedCount enables prefix result calculation`() throws {
        var input = Binary.Bytes.Input([0x31, 0x32, 0x33, 0x41, 0x42])

        // Parse ASCII digits manually
        var value = 0
        while let byte = input.first, byte >= 0x30 && byte <= 0x39 {
            value = value * 10 + Int(byte - 0x30)
            _ = try input.advance()
        }

        #expect(value == 123)
        #expect(input.consumedCount == 3)
        #expect(input.count == 2)
    }

    @Test
    func `sequential byte consumption works correctly`() throws {
        var input = Binary.Bytes.Input([0x01, 0x02, 0x03, 0x04])

        let first = try input.advance()
        let second = try input.advance()
        let third = try input.advance()

        #expect(first == 0x01)
        #expect(second == 0x02)
        #expect(third == 0x03)
        #expect(input.consumedCount == 3)
        #expect(input.count == 1)
    }

    @Test
    func `parse fixed-width integer manually`() throws {
        var input = Binary.Bytes.Input([0xDE, 0xAD, 0xBE, 0xEF])

        let b0 = try input.advance()
        let b1 = try input.advance()
        let b2 = try input.advance()
        let b3 = try input.advance()

        let value =
            UInt32(b0) << 24
            | UInt32(b1) << 16
            | UInt32(b2) << 8
            | UInt32(b3)

        #expect(value == 0xDEAD_BEEF)
        #expect(input.isEmpty)
        #expect(input.consumedCount == 4)
    }
}
