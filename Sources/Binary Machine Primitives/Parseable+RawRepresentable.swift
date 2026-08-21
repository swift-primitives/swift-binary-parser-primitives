public import Byte_Parser_Primitives

extension Parseable where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {

    public static var parser: Binary.Parser<Self> {
        Binary.Parser { input throws(Binary.Machine.Fault) in
            let size = MemoryLayout<RawValue>.size
            var bytes: [Byte] = []
            bytes.reserveCapacity(size)
            let needCount = Index<Byte>.Count(Cardinal(UInt(size)))
            for _ in 0..<size {
                guard !input.isEmpty else {
                    let have = Index<Byte>.Count(Cardinal(UInt(bytes.count)))
                    throw .insufficientBytes(need: needCount, have: have)
                }
                bytes.append(input.removeFirst())
            }
            guard let raw = RawValue(bytes: bytes, endianness: .little) else {
                throw .malformed
            }
            guard let value = Self(rawValue: raw) else {
                throw .outOfRange
            }
            return value
        }
    }
}
