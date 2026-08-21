extension ArraySlice: Binary.Parseable where Element == Byte {

    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> ArraySlice<Byte>
    where Source.Element == Byte {
        let bytes = ArraySlice(source)
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
