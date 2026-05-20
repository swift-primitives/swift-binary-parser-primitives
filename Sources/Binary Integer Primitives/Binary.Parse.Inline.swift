// Binary.Parse.Inline.swift
// swift-binary-primitives
//
// Parser for fixed-size InlineArray sequences.

extension Binary.Parse {
    /// Parser for fixed-size `InlineArray` of `FixedWidthInteger` elements.
    ///
    /// Parses a compile-time-known count of elements from binary input.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = Binary.Parse.Inline<3, UInt16>(endianness: .big)
    /// var input: ArraySlice<Byte> = [0x00, 0x01, 0x00, 0x02, 0x00, 0x03][...]
    /// let array = try parser.parse(&input)
    /// // array: InlineArray<3, UInt16> == [1, 2, 3]
    /// ```
    public struct Inline<let Count: Int, Element: FixedWidthInteger>: Sendable {
        /// Byte order for parsing each element.
        public let endianness: Binary.Endianness

        /// Creates an inline array parser.
        ///
        /// - Parameter endianness: Byte order for parsing elements.
        @inlinable
        public init(endianness: Binary.Endianness) {
            self.endianness = endianness
        }
    }
}

// MARK: - Parser.Parser

extension Binary.Parse.Inline: Parser.`Protocol` {
    public typealias Input = ArraySlice<Byte>
    public typealias Output = InlineArray<Count, Element>
    public typealias Failure = Parser.EndOfInput.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try Output(parsing: &input, endianness: endianness)
    }
}
