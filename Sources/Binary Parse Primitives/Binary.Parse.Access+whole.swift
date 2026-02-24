public import Parser_Primitives

extension Binary.Parse.Access {
    /// Parse entire input. Fails if any bytes remain.
    ///
    /// - Parameter bytes: The bytes to parse.
    /// - Returns: The parsed value.
    /// - Throws: `Either<P.Failure, Binary.Parse.Error>` if parsing fails or bytes remain.
    @inlinable
    public func whole<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(Parser.Error.Either<P.Failure, Binary.Parse.Error>) -> P.ParseOutput
    where Bytes.Element == UInt8 {
        var input = Binary.Bytes.Input(bytes)
        let value: P.ParseOutput
        do {
            value = try parser.parse(&input)
        } catch {
            throw .left(error)
        }
        guard input.isEmpty else {
            throw .right(.end(remaining: input.count))
        }
        return value
    }
}
