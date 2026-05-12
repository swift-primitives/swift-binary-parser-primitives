extension Binary.Bytes.Input {
    /// Borrowed input view for zero-copy bytes parsing.
    ///
    /// This type provides a scope-bound cursor over borrowed bytes using
    /// Swift's lifetime-checked `Span<UInt8>`. It cannot outlive the data it borrows.
    ///
    /// ## Invariants
    ///
    /// - `0 <= position <= span.count`
    /// - `count == span.count - position`
    /// - `consumedCount == position`
    ///
    /// ## Lifetime Safety
    ///
    /// `Input.View` is `~Copyable` and `~Escapable`. The compiler enforces that:
    /// - The view cannot escape the scope of the borrowed data
    /// - The borrowed data must outlive the view
    /// - No implicit copies can be made; any copy requires explicit `copy` and
    ///   remains lifetime-bound to the same underlying storage
    ///
    /// ## NOT Sendable
    ///
    /// `Input.View` is explicitly NOT `Sendable`. Borrowed views must not cross
    /// task boundaries. Use `Binary.Bytes.Input` (owned) if you need to transfer
    /// parsing state across concurrency domains.
    ///
    /// ## Owned Alternative
    ///
    /// For inputs that need to be stored or sent across concurrency domains,
    /// use `Binary.Bytes.Input` which owns its storage as `[UInt8]`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct MyParser: Binary.Bytes.Parser {
    ///     typealias Output = UInt8
    ///     typealias Failure = Never
    ///
    ///     mutating func parse(_ input: inout Binary.Bytes.Input.View) -> UInt8 {
    ///         input.removeFirst()
    ///     }
    /// }
    ///
    /// let result = try Binary.Bytes.withBorrowed(data, MyParser())
    /// ```
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types; `@safe` documents that this type performs no
    // SAFETY: unsafe operations.
    @safe
    public struct View: ~Copyable, ~Escapable {
        @usableFromInline
        let span: Span<UInt8>

        public var position: Int

        /// Memberwise initializer with explicit lifetime annotation.
        @inlinable
        @_lifetime(borrow span)
        internal init(span: borrowing Span<UInt8>, position: Int) {
            self.span = copy span
            self.position = position
        }
    }
}

// MARK: - Initialization (Span-based only)

extension Binary.Bytes.Input.View {
    /// Creates a borrowed input view from a span.
    ///
    /// The view's lifetime is bound to the span's lifetime, which is in turn
    /// bound to the underlying storage. The compiler enforces this relationship.
    ///
    /// - Parameter span: The byte span to borrow.
    @inlinable
    @_lifetime(borrow span)
    public init(_ span: borrowing Span<UInt8>) {
        self.span = copy span
        self.position = 0
    }
}

// MARK: - Properties

extension Binary.Bytes.Input.View {
    /// Total length of the underlying span.
    @usableFromInline
    internal var totalCount: Int {
        span.count
    }

    /// The number of bytes remaining to parse.
    @inlinable
    public var count: Int { totalCount - position }

    /// Whether there are no more bytes to parse.
    @inlinable
    public var isEmpty: Bool { position == totalCount }

    /// The number of bytes consumed since construction (canonical measure).
    @inlinable
    public var consumedCount: Int { position }

    /// The first byte, or `nil` if empty.
    @inlinable
    public var first: UInt8? {
        guard position < totalCount else { return nil }
        return span[position]
    }
}

// MARK: - Mutation

extension Binary.Bytes.Input.View {
    /// Removes and returns the first byte.
    ///
    /// - Precondition: The view must not be empty.
    /// - Returns: The first byte.
    @inlinable
    @discardableResult
    @_lifetime(self: copy self)
    public mutating func removeFirst() -> UInt8 {
        precondition(position < totalCount, "removeFirst() called on empty view")
        let byte = span[position]
        position += 1
        return byte
    }

    /// Removes the first `n` bytes.
    ///
    /// - Parameter n: The number of bytes to remove.
    /// - Precondition: `n >= 0` and `n <= count`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func removeFirst(_ n: Int) {
        precondition(n >= 0 && n <= count)
        position += n
    }
}

// MARK: - Subscript

extension Binary.Bytes.Input.View {
    /// Accesses the byte at the given offset from the current position.
    ///
    /// - Parameter offset: The offset from the current position (0-indexed).
    /// - Precondition: `offset >= 0` and `offset < count`.
    /// - Returns: The byte at the given offset.
    @inlinable
    @_lifetime(copy self)
    public subscript(offset offset: Int) -> UInt8 {
        precondition(offset >= 0 && offset < count, "offset out of bounds")
        return span[position + offset]
    }

    /// Checks if the remaining bytes start with the given prefix.
    ///
    /// - Parameter prefix: The prefix to check.
    /// - Returns: `true` if the remaining bytes start with the prefix.
    @inlinable
    public func starts<Prefix: Swift.Collection>(with prefix: Prefix) -> Bool
    where Prefix.Element == UInt8 {
        guard prefix.count <= count else { return false }
        var idx = position
        for byte in prefix {
            if span[idx] != byte { return false }
            idx += 1
        }
        return true
    }
}

// MARK: - Conversion

extension Binary.Bytes.Input.View {
    /// Copies the remaining bytes to an owned input.
    ///
    /// Use this when you need to store or send the input across concurrency domains.
    ///
    /// - Returns: An owned `Binary.Bytes.Input` containing the remaining bytes.
    @inlinable
    public func copyToOwned() -> Binary.Bytes.Input {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(count)
        for i in position..<totalCount {
            bytes.append(span[i])
        }
        return Binary.Bytes.Input(bytes)
    }
}

// MARK: - NOT Sendable
// Input.View is explicitly NOT Sendable. Borrowed views must not cross task boundaries.
// This is intentional - use Binary.Bytes.Input (owned) for cross-task transfer.
