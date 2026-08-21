public import Binary_Parse_Primitives
import Byte_Primitives

extension Binary {

    public protocol Parseable: Sendable {

        static func parse<Source: RangeReplaceableCollection>(
            from source: inout Source
        ) throws(Binary.Parse.Failure) -> Self
        where Source.Element == Byte
    }
}
