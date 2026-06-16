public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Parser_Primitives
public import Shared_Primitive

extension Binary.Parse.Access {
    /// Parse entire input. Fails if any bytes remain.
    ///
    /// - Parameter bytes: The bytes to parse.
    /// - Returns: The parsed value.
    /// - Throws: `Either<P.Failure, Binary.Parse.Error>` if parsing fails or bytes remain.
    @inlinable
    public func whole<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(Either<P.Failure, Binary.Parse.Error>) -> P.Output
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        let value: P.Output
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
