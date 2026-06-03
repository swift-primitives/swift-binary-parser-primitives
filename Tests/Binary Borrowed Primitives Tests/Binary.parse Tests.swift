import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Index_Primitives
import Testing
// W3 PRUNE: the parse engine re-homed to `Span.Borrowed.`Protocol` where
// Element == Byte`; calling `someByteSpan.parse(...)` needs the
// `Swift.Span: Span.Borrowed.`Protocol`` conformance in scope.
import Span_Protocol_Primitives

@testable import Binary_Parser_Primitives

// MARK: - Binary.parse Tests (owned + borrowed instance-method API)

extension Binary {
    @Suite
    struct ParseTest {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
        @Suite struct Roundtrip {}
    }
}

// MARK: - Unit Tests — Binary.parse (owned)

extension Binary.ParseTest.Unit {

    // MARK: parse

    @Test
    func `Binary.parse u8 returns first byte`() throws {
        let binary = Binary([0x42, 0x99] as [Byte])
        let value = try binary.parse(Binary.Machine.u8Parser())
        #expect(value == 0x42)
    }

    @Test
    func `Binary.parse u16le decodes little-endian`() throws {
        let binary = Binary([0x34, 0x12] as [Byte])
        let value = try binary.parse(Binary.Machine.u16leParser())
        #expect(value == 0x1234)
    }

    @Test
    func `Binary.parse u16be decodes big-endian`() throws {
        let binary = Binary([0x12, 0x34] as [Byte])
        let value = try binary.parse(Binary.Machine.u16beParser())
        #expect(value == 0x1234)
    }

    @Test
    func `Binary.parse u32le decodes little-endian`() throws {
        let binary = Binary([0x78, 0x56, 0x34, 0x12] as [Byte])
        let value = try binary.parse(Binary.Machine.u32leParser())
        #expect(value == 0x12345678)
    }

    @Test
    func `Binary.parse u64be decodes big-endian`() throws {
        let binary = Binary([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF] as [Byte])
        let value = try binary.parse(Binary.Machine.u64beParser())
        #expect(value == 0x0123456789ABCDEF)
    }

    // MARK: parsePrefix

    @Test
    func `Binary.parsePrefix u8 returns value and consumed count 1`() throws {
        let binary = Binary([0x42, 0x99] as [Byte])
        let result = try binary.parsePrefix(Binary.Machine.u8Parser())
        #expect(result.value == 0x42)
        #expect(result.count == Index<Byte>.Count(Cardinal(1)))
    }

    @Test
    func `Binary.parsePrefix u32le returns value and consumed count 4`() throws {
        let binary = Binary([0x78, 0x56, 0x34, 0x12, 0xAA, 0xBB] as [Byte])
        let result = try binary.parsePrefix(Binary.Machine.u32leParser())
        #expect(result.value == 0x12345678)
        #expect(result.count == Index<Byte>.Count(Cardinal(4)))
    }

    // MARK: parsePrefixUnchecked

    @Test
    func `Binary.parsePrefixUnchecked u8 returns value and consumed count 1`() throws {
        let binary = Binary([0x42, 0x99] as [Byte])
        let result = try binary.parsePrefixUnchecked(Binary.Machine.u8Parser())
        #expect(result.value == 0x42)
        #expect(result.count == Index<Byte>.Count(Cardinal(1)))
    }

    // MARK: parseWhole

    @Test
    func `Binary.parseWhole u8 succeeds when input is exactly 1 byte`() throws {
        let binary = Binary([0x42] as [Byte])
        let value = try binary.parseWhole(Binary.Machine.u8Parser())
        #expect(value == 0x42)
    }

    @Test
    func `Binary.parseWhole u16le succeeds when input is exactly 2 bytes`() throws {
        let binary = Binary([0x34, 0x12] as [Byte])
        let value = try binary.parseWhole(Binary.Machine.u16leParser())
        #expect(value == 0x1234)
    }

    @Test
    func `Binary.parseWhole throws expectedEnd when bytes remain`() throws {
        let binary = Binary([0x42, 0x99] as [Byte])
        #expect(throws: Binary.Machine.Fault.self) {
            try binary.parseWhole(Binary.Machine.u8Parser())
        }
    }
}

// MARK: - Unit Tests — Binary.Borrowed.parse (borrowed)

extension Binary.ParseTest.Unit {

    @Test
    func `borrowed byte-span parse u8 returns first byte`() throws {
        // W3 PRUNE: the borrowed view IS a Swift.Span<Byte>; parse attaches
        // to it via the Span.Borrowed.`Protocol` byte-span seam.
        let bytes: [Byte] = [0x42, 0x99]
        let value = try bytes.withUnsafeBufferPointer { (buf: UnsafeBufferPointer<Byte>) throws(Binary.Machine.Fault) -> UInt8 in
            let span = unsafe Swift.Span(_unsafeStart: buf.baseAddress ?? UnsafePointer<Byte>(bitPattern: 1)!, count: buf.count)
            return try span.parse(Binary.Machine.u8Parser())
        }
        #expect(value == 0x42)
    }

    @Test
    func `Binary.Borrowed.parsePrefix returns value and consumed count`() throws {
        let binary = Binary([0x34, 0x12, 0xAA, 0xBB] as [Byte])
        let result = try binary.view.parsePrefix(Binary.Machine.u16leParser())
        #expect(result.value == 0x1234)
        #expect(result.count == Index<Byte>.Count(Cardinal(2)))
    }

    @Test
    func `Binary.Borrowed.parseWhole succeeds at exact-length input`() throws {
        let binary = Binary([0x12, 0x34, 0x56, 0x78] as [Byte])
        let value = try binary.view.parseWhole(Binary.Machine.u32beParser())
        #expect(value == 0x12345678)
    }

    @Test
    func `Binary.Borrowed.parseWhole throws expectedEnd when bytes remain`() throws {
        let binary = Binary([0x42, 0x99, 0xAA] as [Byte])
        #expect(throws: Binary.Machine.Fault.self) {
            try binary.view.parseWhole(Binary.Machine.u8Parser())
        }
    }
}

// MARK: - Edge Cases

extension Binary.ParseTest.EdgeCase {

    @Test
    func `Binary.parse throws insufficientBytes when input shorter than needed`() throws {
        let binary = Binary([0x42] as [Byte])
        #expect(throws: Binary.Machine.Fault.self) {
            try binary.parse(Binary.Machine.u32leParser())
        }
    }

    @Test
    func `Binary.init from empty byte array is valid`() {
        let binary = Binary([] as [Byte])
        #expect(binary.count == Index<Byte>.Count(Cardinal(0)))
    }

    @Test
    func `Binary.parse on empty input throws insufficientBytes`() {
        let binary = Binary([] as [Byte])
        #expect(throws: Binary.Machine.Fault.self) {
            try binary.parse(Binary.Machine.u8Parser())
        }
    }

    @Test
    func `Binary.init from single-byte array preserves the byte`() throws {
        let binary = Binary([0xAB] as [Byte])
        #expect(binary.count == Index<Byte>.Count(Cardinal(1)))
        let value = try binary.parse(Binary.Machine.u8Parser())
        #expect(value == 0xAB)
    }
}

// MARK: - Round-trip / Delegation Tests
//
// These test that `Binary.parse` delegates correctly to `Binary.Borrowed.parse`
// via the `view` accessor (Wave 1c delegation chain).

extension Binary.ParseTest.Roundtrip {

    @Test
    func `Binary.parse and Binary.view.parse produce same result`() throws {
        let binary = Binary([0x12, 0x34, 0x56, 0x78] as [Byte])
        let viaOwned = try binary.parse(Binary.Machine.u32beParser())
        let viaBorrowed = try binary.view.parse(Binary.Machine.u32beParser())
        #expect(viaOwned == viaBorrowed)
        #expect(viaOwned == 0x12345678)
    }

    @Test
    func `Binary.parsePrefix and Binary.view.parsePrefix produce same value and count`() throws {
        let binary = Binary([0x42, 0x99, 0xAA] as [Byte])
        let viaOwned = try binary.parsePrefix(Binary.Machine.u8Parser())
        let viaBorrowed = try binary.view.parsePrefix(Binary.Machine.u8Parser())
        #expect(viaOwned.value == viaBorrowed.value)
        #expect(viaOwned.count == viaBorrowed.count)
        #expect(viaOwned.value == 0x42)
        #expect(viaOwned.count == Index<Byte>.Count(Cardinal(1)))
    }
}

// MARK: - Binary.withInput Tests (owned-input convenience)

extension Binary.ParseTest.Unit {

    @Test
    func `Binary.withInput from byte array constructs Byte.Input`() {
        var observedCount: Index<Byte>.Count = .zero
        Binary.withInput([0x01, 0x02, 0x03] as [Byte]) { (input: inout Byte.Input) -> Void in
            observedCount = input.count
        }
        #expect(observedCount == Index<Byte>.Count(Cardinal(3)))
    }

    @Test
    func `Binary.withInput from ArraySlice constructs Byte.Input`() {
        let bytes: [Byte] = [0x01, 0x02, 0x03, 0x04, 0x05]
        var observedCount: Index<Byte>.Count = .zero
        Binary.withInput(bytes[1..<4]) { (input: inout Byte.Input) -> Void in
            observedCount = input.count
        }
        #expect(observedCount == Index<Byte>.Count(Cardinal(3)))
    }

    @Test
    func `Binary.withInput from string produces input with correct UTF-8 count`() {
        var observedCount: Index<Byte>.Count = .zero
        Binary.withInput("ABC") { (input: inout Byte.Input) -> Void in
            observedCount = input.count
        }
        #expect(observedCount == Index<Byte>.Count(Cardinal(3)))
    }
}
