public import Parser_Primitives

extension Parser.`Protocol` where Input == Byte.Input {

    @inlinable
    public var parse: Binary.Parse.Access<Self> {
        .init(self)
    }
}
