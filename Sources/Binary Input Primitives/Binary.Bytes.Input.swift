public import Byte_Parser_Primitives

extension Binary.Bytes {
    /// Owned input cursor for bytes parsing.
    ///
    /// `Binary.Bytes.Input` is a typealias for ``Byte/Input`` (declared in
    /// `swift-byte-parser-primitives`) — the canonical byte-stream input
    /// for byte-domain parsers, built on
    /// `Input.Slice<Array<UInt8>.Indexed<UInt8>>`.
    ///
    /// ## Migration note
    ///
    /// Pre-2026-05-18 this was a hand-written struct with `storage: [UInt8]`
    /// and `position: Index<UInt8>` fields plus `+init` / `+properties` /
    /// `+mutation` / `+subscript` / `+Input.Protocol` extension files
    /// duplicating what `Input.Slice` already provides. The typed-input-
    /// unification arc (`swift-institute/Research/typed-input-unification.md`,
    /// DECISION 2026-05-18) collapsed the duplication: `Binary.Bytes.Input`
    /// is now a typealias chain
    /// `Binary.Bytes.Input` → `Byte.Input` →
    /// `Input_Primitives.Input.Slice<Array<UInt8>.Indexed<UInt8>>`. The
    /// binary-domain name survives via the typealias; the byte-parser-
    /// primitives package owns the byte-domain owned-input identity.
    ///
    /// ## Invariants
    ///
    /// All invariants are inherited from ``Input/Slice``:
    /// - `position <= totalCount`
    /// - `count == totalCount.subtract.saturating(position)`
    ///
    /// ## Sendable
    ///
    /// Fully `Sendable` (conditional on `Array<UInt8>.Indexed<UInt8>: Sendable`,
    /// which holds — institute Array is `@unchecked Sendable`).
    ///
    /// ## Borrowed Alternative
    ///
    /// For zero-copy parsing over borrowed data, use ``Binary/Bytes/Input/View``
    /// (= `Cursor<Byte>`), which stores a lifetime-checked `Span<UInt8>` and
    /// cannot escape its borrowing scope.
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
    ///         try input.advance()
    ///         return byte
    ///     }
    /// }
    /// ```
    public typealias Input = Byte.Input
}

// MARK: - Binary-domain convenience surface
//
// `Byte.Input` ships `init(_ bytes: [UInt8])` and `init(utf8: String)` as
// canonical byte-domain inits. The two binary-domain extensions below add:
//
//   1. A generic `Collection` init covering arbitrary `Bytes: Collection` where
//      `Bytes.Element == UInt8` (used by Binary.Parse.Access<P>.prefix(_:)).
//   2. An `ArraySlice<UInt8>` init for `Swift.Array.dropFirst(_:)` results.
//
// Plus `starts(with:)` — a prefix-match helper that consumers' parser-machine
// scaffolding uses. Since `Binary.Bytes.Input` is a typealias for
// `Input.Slice<Array<UInt8>.Indexed<UInt8>>`, the extension below binds to
// that specific instantiation; both `Binary.Bytes.Input(...)` and
// `Byte.Input(...)` call sites resolve to these inits.

extension Binary.Bytes.Input {
    /// Creates an input cursor from any byte collection.
    ///
    /// Delegates to ``Byte/Input/init(_:)-(Array<UInt8>)`` after materializing
    /// the collection into a stdlib array.
    ///
    /// - Parameter bytes: The bytes to parse.
    @inlinable
    public init<Bytes: Swift.Collection>(_ bytes: Bytes) where Bytes.Element == UInt8 {
        self.init(Swift.Array(bytes))
    }

    /// Creates an input cursor from an array slice.
    ///
    /// - Parameter bytes: The byte slice to parse.
    @inlinable
    public init(_ bytes: ArraySlice<UInt8>) {
        self.init(Swift.Array(bytes))
    }
}

// MARK: - Prefix-match helper

extension Binary.Bytes.Input {
    /// Checks if the remaining bytes start with the given prefix.
    ///
    /// Delegates to ``Input/Access/Random``'s `access.starts(with:)` Property
    /// view — the canonical prefix-match operation lives on the Random-access
    /// capability protocol. This binary-domain wrapper preserves the legacy
    /// `input.starts(with:)` call-site shape; new call sites SHOULD prefer
    /// `input.access.starts(with: prefix)` directly.
    ///
    /// - Parameter prefix: The prefix to check.
    /// - Returns: `true` if the remaining bytes start with the prefix.
    @inlinable
    public func starts<Prefix: Swift.Collection>(with prefix: Prefix) -> Bool
    where Prefix.Element == UInt8 {
        var copy = self
        return copy.access.starts(with: prefix)
    }
}
