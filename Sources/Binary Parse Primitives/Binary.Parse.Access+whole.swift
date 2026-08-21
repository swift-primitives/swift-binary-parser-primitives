public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Ownership_Shared_Primitive
public import Parser_Primitives

extension Binary.Parse.Access {

    @inlinable
    public func whole<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) throws(Either<P.Failure, Binary.Parse.Error>) -> P.Output
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        let value: P.Output
        do throws(P.Failure) {
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
