import Binary_Parser_Primitives_Test_Support
import Testing

@testable import Binary_Parser_Primitives

// MARK: - Byte.Input.View Tests

// Note: Input.View is ~Copyable and ~Escapable, so tests must extract values
// before using #expect since the macro doesn't support these types.

@Suite("Byte.Input.View")
struct BinaryBytesInputViewTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
}

// MARK: - Unit Tests

extension BinaryBytesInputViewTests.Unit {

    @Test
    func `count returns correct value`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]

        let count = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.count
        }

        #expect(count == 5)
    }

    @Test
    func `isEmpty returns false for non-empty view`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]

        let isEmpty = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.isEmpty
        }

        #expect(!isEmpty)
    }

    @Test
    func `first returns first byte`() {
        let bytes: [UInt8] = [0xAB, 0xCD, 0xEF]

        let first = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.first
        }

        #expect(first == 0xAB)
    }

    @Test
    func `consumedCount starts at zero`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]

        let consumedCount = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.consumedCount
        }

        #expect(consumedCount == 0)
    }

    @Test
    func `removeFirst removes and returns first byte`() {
        let bytes: [UInt8] = [0x41, 0x42, 0x43]

        let (byte, count, first) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)
            let byte = view.removeFirst()
            return (byte, view.count, view.first)
        }

        #expect(byte == 0x41)
        #expect(count == 2)
        #expect(first == 0x42)
    }

    @Test
    func `removeFirst updates consumedCount`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]

        let (consumed1, consumed2) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            _ = view.removeFirst()
            let c1 = view.consumedCount

            _ = view.removeFirst()
            let c2 = view.consumedCount

            return (c1, c2)
        }

        #expect(consumed1 == 1)
        #expect(consumed2 == 2)
    }

    @Test
    func `removeFirst n removes multiple bytes`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]

        let (count, first, consumedCount) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            view.removeFirst(3)

            return (view.count, view.first, view.consumedCount)
        }

        #expect(count == 2)
        #expect(first == 0x04)
        #expect(consumedCount == 3)
    }

    @Test
    func `subscript accesses byte at offset`() {
        let bytes: [UInt8] = [0x10, 0x20, 0x30, 0x40]

        let (b0, b1, b2, b3) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return (view[offset: 0], view[offset: 1], view[offset: 2], view[offset: 3])
        }

        #expect(b0 == 0x10)
        #expect(b1 == 0x20)
        #expect(b2 == 0x30)
        #expect(b3 == 0x40)
    }

    @Test
    func `subscript respects consumed bytes`() {
        let bytes: [UInt8] = [0x10, 0x20, 0x30, 0x40]

        let (b0, b1) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            _ = view.removeFirst()

            return (view[offset: 0], view[offset: 1])
        }

        #expect(b0 == 0x20)
        #expect(b1 == 0x30)
    }

    @Test
    func `starts with returns true for matching prefix`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]

        let startsWith = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.starts(with: [0x01, 0x02])
        }

        #expect(startsWith)
    }

    @Test
    func `starts with returns false for non-matching prefix`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]

        let startsWith = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return view.starts(with: [0x01, 0x03])
        }

        #expect(!startsWith)
    }
}

// MARK: - EdgeCase Tests

extension BinaryBytesInputViewTests.EdgeCase {

    @Test
    func `empty view has count zero`() {
        let bytes: [UInt8] = []

        let (count, isEmpty, first) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            let view = Byte.Input.View(span)
            return (view.count, view.isEmpty, view.first)
        }

        #expect(count == 0)
        #expect(isEmpty)
        #expect(first == nil)
    }

    @Test
    func `consuming all bytes makes view empty`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03]

        let (isEmpty, first, consumedCount) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            view.removeFirst(3)

            return (view.isEmpty, view.first, view.consumedCount)
        }

        #expect(isEmpty)
        #expect(first == nil)
        #expect(consumedCount == 3)
    }

    @Test
    func `removeFirst zero is no-op`() {
        let bytes: [UInt8] = [0x01, 0x02]

        let (count, consumedCount) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            view.removeFirst(0)

            return (view.count, view.consumedCount)
        }

        #expect(count == 2)
        #expect(consumedCount == 0)
    }
}

// MARK: - Integration Tests

extension BinaryBytesInputViewTests.Integration {

    @Test
    func `copyToOwned creates independent input`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]

        let (ownedCount, ownedFirst) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            _ = view.removeFirst()
            let owned = view.copyToOwned()

            return (owned.count, owned.first)
        }

        #expect(ownedCount == 3)
        #expect(ownedFirst == 0x02)
    }

    @Test
    func `sequential byte consumption works`() {
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04]

        let (first, second, third, consumedCount, count) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            let first = view.removeFirst()
            let second = view.removeFirst()
            let third = view.removeFirst()

            return (first, second, third, view.consumedCount, view.count)
        }

        #expect(first == 0x01)
        #expect(second == 0x02)
        #expect(third == 0x03)
        #expect(consumedCount == 3)
        #expect(count == 1)
    }

    @Test
    func `parse fixed-width integer from view`() {
        let bytes: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]

        let (value, isEmpty) = bytes.withUnsafeBufferPointer { buffer in
            let span = Span(_unsafeElements: buffer)
            var view = Byte.Input.View(span)

            let b0 = view.removeFirst()
            let b1 = view.removeFirst()
            let b2 = view.removeFirst()
            let b3 = view.removeFirst()

            let value =
                UInt32(b0) << 24
                | UInt32(b1) << 16
                | UInt32(b2) << 8
                | UInt32(b3)

            return (value, view.isEmpty)
        }

        #expect(value == 0xDEAD_BEEF)
        #expect(isEmpty)
    }
}
