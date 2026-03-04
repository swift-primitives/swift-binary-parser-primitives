public import Parser_Primitives
public import Serialization_Primitives
public import Index_Primitives

extension Binary.Parse.Access {
    /// Parse prefix of input. Returns value and count of bytes consumed.
    ///
    /// - Parameter bytes: The bytes to parse.
    /// - Returns: The parsed value and count of bytes consumed.
    /// - Throws: `P.Failure` if parsing fails.
    @inlinable
    public func prefix<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(P.Failure) -> Serialization.Parsing.Prefix.Result<P.Output, Index<UInt8>.Count>
    where Bytes.Element == UInt8 {
        var input = Binary.Bytes.Input(bytes)
        let value = try parser.parse(&input)
        return Serialization.Parsing.Prefix.Result(value: value, count: input.consumedCount)
    }
}
