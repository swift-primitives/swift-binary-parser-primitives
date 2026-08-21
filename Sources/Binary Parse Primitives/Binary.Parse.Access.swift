public import Parser_Primitives

extension Binary.Parse {

    public struct Access<P: Parser.`Protocol`> where P.Input == Byte.Input {
        @usableFromInline
        internal let parser: P

        @inlinable
        public init(_ parser: P) {
            self.parser = parser
        }
    }
}
