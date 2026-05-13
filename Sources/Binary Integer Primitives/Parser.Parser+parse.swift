public import Parser_Primitives

extension Parser.`Protocol` where Input == Binary.Bytes.Input {
    /// Accessor for bytes parsing capabilities.
    ///
    /// Provides `parser.parse.whole(bytes)` and `parser.parse.prefix(bytes)` ergonomics.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser: some Parser.Parser<Binary.Bytes.Input, MyType, MyError> = ...
    /// let bytes: [UInt8] = [...]
    ///
    /// // Whole-buffer parsing (fails if bytes remain)
    /// let value = try parser.parse.whole(bytes)
    ///
    /// // Prefix parsing (returns value + consumed count)
    /// let result = try parser.parse.prefix(bytes)
    /// let remainder = bytes.dropFirst(result.count)
    /// ```
    @inlinable
    public var parse: Binary.Parse.Access<Self> {
        .init(self)
    }
}
