internal import Index_Primitives
public import Parser_Primitives

extension Binary.Parse.Access {
    /// Parse prefix of input. Returns value and count of bytes consumed.
    ///
    /// - Parameter bytes: The bytes to parse.
    /// - Returns: The parsed value and count of bytes consumed.
    /// - Throws: `P.Failure` if parsing fails.
    @inlinable
    public func prefix<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(P.Failure) -> (value: P.Output, count: Index<Byte>.Count)
    where Bytes.Element == UInt8 {
        var input = Byte.Input(bytes)
        let value = try parser.parse(&input)
        return (value: value, count: input.consumed.retag(Byte.self))
    }
}
