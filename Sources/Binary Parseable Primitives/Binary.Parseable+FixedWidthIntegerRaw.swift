extension Binary.Parseable where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {

    @inlinable
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Self
    where Source.Element == Byte {
        let size = MemoryLayout<RawValue>.size
        guard source.count >= size else { throw .insufficient(needed: size) }
        let bytes = [Byte](source.prefix(size))
        source.removeFirst(size)
        guard let raw = RawValue(bytes: bytes, endianness: .little) else {
            throw .malformed
        }
        guard let value = Self(rawValue: raw) else { throw .outOfRange }
        return value
    }

    @inlinable
    public init?(bytes: [Byte], endianness: Binary.Endianness = .little) {
        guard let raw = Self.RawValue(bytes: bytes, endianness: endianness) else {
            return nil
        }
        guard let value = Self(rawValue: raw) else {
            return nil
        }
        self = value
    }

}
