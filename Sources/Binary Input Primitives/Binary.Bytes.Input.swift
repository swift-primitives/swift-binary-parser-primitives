public import Index_Primitives

extension Binary.Bytes {
    /// Owned input cursor for bytes parsing.
    ///
    /// This type provides an escapable, `Sendable` cursor over bytes that can be
    /// used as `Parser.Parser.Input`. Backed by `[UInt8]` with full ownership.
    ///
    /// ## Invariants
    ///
    /// - `position <= totalCount`
    /// - `count == totalCount.subtract.saturating(position)`
    ///
    /// ## Sendable
    ///
    /// Fully `Sendable` because storage is an owned `[UInt8]` value type.
    /// Safe to transfer across concurrency domains.
    ///
    /// ## Borrowed Alternative
    ///
    /// For zero-copy parsing over borrowed data, use `Input.View` which stores
    /// a lifetime-checked `Span<UInt8>` and cannot escape its borrowing scope.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct MyParser: Parser.`Protocol` {
    ///     typealias Input = Binary.Bytes.Input
    ///     typealias Output = UInt8
    ///     typealias Failure = Parser.Match.Error
    ///
    ///     func parse(_ input: inout Input) throws(Failure) -> UInt8 {
    ///         guard let byte = input.first else {
    ///             throw .unexpectedEnd
    ///         }
    ///         input.removeFirst()
    ///         return byte
    ///     }
    /// }
    /// ```
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types; `@safe` documents that this type performs no
    // SAFETY: unsafe operations.
    @safe
    public struct Input: Sendable {
        @usableFromInline
        internal var storage: [UInt8]

        @usableFromInline
        internal var position: Index<UInt8>
    }
}
