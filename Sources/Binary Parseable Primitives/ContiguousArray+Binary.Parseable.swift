extension ContiguousArray: Binary.Parseable where Element == Byte {

    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> ContiguousArray<Byte>
    where Source.Element == Byte {
        let bytes = ContiguousArray(source)
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
