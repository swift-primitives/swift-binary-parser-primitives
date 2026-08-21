extension UInt32: Binary.Parseable {

    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> UInt32
    where Source.Element == Byte {
        let size = MemoryLayout<UInt32>.size
        guard source.count >= size else { throw .insufficient(needed: size) }
        let bytes = [Byte](source.prefix(size))
        source.removeFirst(size)
        guard let value = UInt32(bytes: bytes, endianness: .little) else {
            throw .malformed
        }
        return value
    }
}
