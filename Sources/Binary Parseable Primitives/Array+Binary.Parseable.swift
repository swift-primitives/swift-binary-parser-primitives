public import Binary_Parse_Primitives
import Cardinal_Primitives
import Index_Primitives

extension Swift.Array: Binary.Parseable where Element == Byte {

    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Self
    where Source.Element == Byte {
        var bytes = Self()

        bytes.reserveCapacity(
            Index_Primitives.Index<Byte>.Count(Cardinal(UInt(source.count)))
        )
        for byte in source {
            bytes.append(byte)
        }
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
