public import Parser_Primitives

extension Binary.Parse {
    /// Accessor wrapper providing `parser.parse.whole(bytes)` / `parser.parse.prefix(bytes)` ergonomics.
    ///
    /// This keeps `whole` and `prefix` out of the root parser namespace by requiring
    /// the `.parse` accessor first.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let value = try parser.parse.whole(bytes)
    /// let result = try parser.parse.prefix(bytes)
    /// ```
    public struct Access<P: Parser.`Protocol` & Sendable>: Sendable where P.Input == Binary.Bytes.Input {
        @usableFromInline
        internal let parser: P

        @inlinable
        public init(_ parser: P) {
            self.parser = parser
        }
    }
}
