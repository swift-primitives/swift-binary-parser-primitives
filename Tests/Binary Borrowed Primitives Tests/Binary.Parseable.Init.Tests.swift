import Binary_Parseable_Primitives
import Testing

private struct Word: RawRepresentable, Binary.Parseable {
    var rawValue: UInt32
    init?(rawValue: UInt32) { self.rawValue = rawValue }
    init(_ raw: UInt32) { self.rawValue = raw }
}

@Suite
struct `Binary.Parseable Init Bytes Tests` {

    @Test
    func `init?(bytes: [Byte], endianness:) decodes little-endian`() throws {
        let bytes: [Byte] = [0x78, 0x56, 0x34, 0x12]
        let word = try #require(Word(bytes: bytes, endianness: .little))
        #expect(word.rawValue == 0x1234_5678)
    }

    @Test
    func `init?(bytes: [Byte], endianness:) decodes big-endian`() throws {
        let bytes: [Byte] = [0x12, 0x34, 0x56, 0x78]
        let word = try #require(Word(bytes: bytes, endianness: .big))
        #expect(word.rawValue == 0x1234_5678)
    }

    @Test
    func `init?(bytes: [Byte], endianness:) returns nil on wrong byte count`() {
        let tooFew: [Byte] = [0x12, 0x34]
        #expect(Word(bytes: tooFew, endianness: .little) == nil)
    }
}
