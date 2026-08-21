extension Binary.Parse {

    public struct Inline<let Count: Int, Element: FixedWidthInteger>: Sendable {

        public let endianness: Binary.Endianness

        @inlinable
        public init(endianness: Binary.Endianness) {
            self.endianness = endianness
        }
    }
}

extension Binary.Parse.Inline: Parser.`Protocol` {

    public typealias Input = ArraySlice<Byte>

    public typealias Output = InlineArray<Count, Element>

    public typealias Failure = Parser.EndOfInput.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try Output(parsing: &input, endianness: endianness)
    }
}
