import Binary_Parser_Primitives_Test_Support
import Byte_Primitives
import Index_Primitives
import Testing
// The parse engine is re-homed to `Span.`Protocol` where Element == Byte`;
// calling `someByteSpan.parse(...)` needs the `Swift.Span: Span.`Protocol``
// conformance in scope. A `Swift.Span<Byte>` is obtained from `[Byte].span`.
import Span_Protocol_Primitives

@testable import Binary_Parser_Primitives

// MARK: - Binary parse Tests (byte-span instance-method API)
//
// The owned `Binary` struct was dissolved (binary-primitives is now a
// namespace); the binary-domain parse engine lives on
// `Span.`Protocol` where Element == Byte`. These tests drive it through a
// `Swift.Span<Byte>` obtained from `[Byte].span`.

extension Binary {
    @Suite
    struct ParseTest {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit Tests — byte-span parse

extension Binary.ParseTest.Unit {

    // MARK: parse

    @Test
    func `byte-span parse u8 returns first byte`() throws {
        let value = try ([0x42, 0x99] as [Byte]).span.parse(Binary.Machine.u8Parser())
        #expect(value == 0x42)
    }

    @Test
    func `byte-span parse u16le decodes little-endian`() throws {
        let value = try ([0x34, 0x12] as [Byte]).span.parse(Binary.Machine.u16leParser())
        #expect(value == 0x1234)
    }

    @Test
    func `byte-span parse u16be decodes big-endian`() throws {
        let value = try ([0x12, 0x34] as [Byte]).span.parse(Binary.Machine.u16beParser())
        #expect(value == 0x1234)
    }

    @Test
    func `byte-span parse u32le decodes little-endian`() throws {
        let value = try ([0x78, 0x56, 0x34, 0x12] as [Byte]).span.parse(Binary.Machine.u32leParser())
        #expect(value == 0x12345678)
    }

    @Test
    func `byte-span parse u32be decodes big-endian`() throws {
        let value = try ([0x12, 0x34, 0x56, 0x78] as [Byte]).span.parse(Binary.Machine.u32beParser())
        #expect(value == 0x12345678)
    }

    @Test
    func `byte-span parse u64be decodes big-endian`() throws {
        let value = try ([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF] as [Byte]).span.parse(Binary.Machine.u64beParser())
        #expect(value == 0x0123456789ABCDEF)
    }

    // MARK: parsePrefix

    @Test
    func `byte-span parsePrefix u8 returns value and consumed count 1`() throws {
        let result = try ([0x42, 0x99] as [Byte]).span.parsePrefix(Binary.Machine.u8Parser())
        #expect(result.value == 0x42)
        #expect(result.count == Index<Byte>.Count(Cardinal(1)))
    }

    @Test
    func `byte-span parsePrefix u16le returns value and consumed count 2`() throws {
        let result = try ([0x34, 0x12, 0xAA, 0xBB] as [Byte]).span.parsePrefix(Binary.Machine.u16leParser())
        #expect(result.value == 0x1234)
        #expect(result.count == Index<Byte>.Count(Cardinal(2)))
    }

    @Test
    func `byte-span parsePrefix u32le returns value and consumed count 4`() throws {
        let result = try ([0x78, 0x56, 0x34, 0x12, 0xAA, 0xBB] as [Byte]).span.parsePrefix(Binary.Machine.u32leParser())
        #expect(result.value == 0x12345678)
        #expect(result.count == Index<Byte>.Count(Cardinal(4)))
    }

    // MARK: parsePrefixUnchecked

    @Test
    func `byte-span parsePrefixUnchecked u8 returns value and consumed count 1`() throws {
        let result = try ([0x42, 0x99] as [Byte]).span.parsePrefixUnchecked(Binary.Machine.u8Parser())
        #expect(result.value == 0x42)
        #expect(result.count == Index<Byte>.Count(Cardinal(1)))
    }

    // MARK: parseWhole

    @Test
    func `byte-span parseWhole u8 succeeds when input is exactly 1 byte`() throws {
        let value = try ([0x42] as [Byte]).span.parseWhole(Binary.Machine.u8Parser())
        #expect(value == 0x42)
    }

    @Test
    func `byte-span parseWhole u16le succeeds when input is exactly 2 bytes`() throws {
        let value = try ([0x34, 0x12] as [Byte]).span.parseWhole(Binary.Machine.u16leParser())
        #expect(value == 0x1234)
    }

    @Test
    func `byte-span parseWhole u32be succeeds at exact-length input`() throws {
        let value = try ([0x12, 0x34, 0x56, 0x78] as [Byte]).span.parseWhole(Binary.Machine.u32beParser())
        #expect(value == 0x12345678)
    }

    @Test
    func `byte-span parseWhole throws expectedEnd when bytes remain`() {
        // A lifetime-dependent span cannot escape an #expect(throws:) autoclosure;
        // assert the fault via do/catch in linear scope instead.
        let bytes: [Byte] = [0x42, 0x99]
        do {
            _ = try bytes.span.parseWhole(Binary.Machine.u8Parser())
            Issue.record("expected Binary.Machine.Fault.expectedEnd")
        } catch {
            // expected: a byte remains after the 1-byte parse
        }
    }
}

// MARK: - Edge Cases

extension Binary.ParseTest.EdgeCase {

    @Test
    func `byte-span parse throws insufficientBytes when input shorter than needed`() {
        let bytes: [Byte] = [0x42]
        do {
            _ = try bytes.span.parse(Binary.Machine.u32leParser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {
            // expected: 1 byte cannot satisfy a u32 parse
        }
    }

    @Test
    func `byte-span parse on empty input throws insufficientBytes`() {
        let bytes: [Byte] = []
        do {
            _ = try bytes.span.parse(Binary.Machine.u8Parser())
            Issue.record("expected Binary.Machine.Fault")
        } catch {
            // expected: empty input cannot satisfy a u8 parse
        }
    }

    @Test
    func `byte-span parse of single-byte input returns the byte`() throws {
        let value = try ([0xAB] as [Byte]).span.parse(Binary.Machine.u8Parser())
        #expect(value == 0xAB)
    }
}

// MARK: - Binary.withInput Tests (owned-input convenience)
//
// `Binary.withInput` is a static convenience on the `Binary` namespace (it
// constructs a `Byte.Input` over the bytes and runs the closure); it survives
// the owned-struct dissolution unchanged.

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
