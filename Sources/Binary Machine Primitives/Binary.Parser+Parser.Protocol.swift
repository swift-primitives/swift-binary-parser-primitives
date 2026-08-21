public import Byte_Parser_Primitives

extension Binary.Parser: Parser.`Protocol` {

    public typealias Input = Byte.Input

    public typealias Output = Value

    public typealias Failure = Binary.Machine.Fault

    public typealias Body = Never

    @inlinable
    public borrowing func parse(_ input: inout Byte.Input) throws(Binary.Machine.Fault) -> Value {
        try _parse(&input)
    }
}
