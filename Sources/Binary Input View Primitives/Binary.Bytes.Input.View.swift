public import Byte_Primitives
public import Cursor_Primitives_Core

extension Binary.Bytes.Input {
    /// Borrowed input view for zero-copy bytes parsing.
    ///
    /// `Binary.Bytes.Input.View` is a typealias for the institute's unified
    /// single-generic borrowed-bytes cursor — ``Cursor`` parameterized over
    /// ``Byte``. Storage derives from `Byte.Borrowed` via Byte's
    /// `Ownership.Borrow.`Protocol`` conformance; position is typed
    /// `Tagged<Byte, Ordinal>` (≡ `Index<Byte>`) per the typed-position
    /// discipline.
    ///
    /// ## Lifetime
    ///
    /// `~Copyable` and `~Escapable` — the cursor cannot be duplicated and
    /// cannot outlive the span it borrows. Compiler-enforced via
    /// `@_lifetime(borrow source)` on the underlying primitive's initializer.
    ///
    /// ## NOT Sendable
    ///
    /// Borrowed views must not cross task boundaries. For cross-task transfer
    /// use ``Binary/Bytes/Input`` (Copyable, `[UInt8]`-backed).
    ///
    /// ## Migration note
    ///
    /// `position` was previously a raw `Int` stored property. As part of the
    /// cursor-abstractions arc (`swift-institute/Research/cursor-abstractions-l1-ecosystem.md`
    /// v1.3.0 DECISION 2026-05-17), position now types as
    /// `Tagged<Byte, Ordinal>`. Position assignment is performed via
    /// ``Cursor/seek(to:)`` for parser-machine backtracking.
    ///
    /// ## Cursor shape lineage
    ///
    /// The substrate Cursor type reshaped twice through 2026-05-18:
    /// `Cursor.Span<DomainTag>` (Shape γ; pre-2026-05-18) →
    /// `Cursor<Storage, PositionTag>` (Shape A two-generic; 2026-05-18) →
    /// `Cursor<DomainTag: Ownership.Borrow.`Protocol`>` (Shape A
    /// single-generic; the current shape, per
    /// `cursor-shape-a-vs-three-worlds.md` v1.2.0). Call-site shape at this
    /// typealias is invariant across the changes — `Binary.Bytes.Input.View`
    /// continues to resolve to the correct cursor instantiation.
    public typealias View = Cursor<Byte>
}

// MARK: - Legacy public API (binary-domain extensions)
//
// The original `Binary.Bytes.Input.View` shipped a domain-specific public API
// (`isEmpty`, `first`, `removeFirst`, `removeFirst(_:)`, `subscript[offset:]`,
// `consumedCount`). The unified Cursor<Byte> substrate uses cursor-style
// names (`isAtEnd`, `peek`, `consume`, `advance`, `peek(at:)`). These
// extensions preserve the legacy binary-domain API on the typealiased identity
// so existing call sites continue to compile.

extension Cursor where DomainTag == Byte {
    /// Whether there are no more bytes to parse.
    @inlinable
    public var isEmpty: Bool { isAtEnd }

    /// The first byte, or `nil` if empty.
    @inlinable
    public var first: UInt8? { peek() }

    /// The number of bytes consumed since construction (canonical measure).
    @inlinable
    public var consumedCount: Int { Int(bitPattern: position) }

    /// Removes and returns the first byte.
    ///
    /// - Precondition: The view must not be empty.
    /// - Returns: The first byte.
    @inlinable
    @discardableResult
    @_lifetime(self: copy self)
    public mutating func removeFirst() -> UInt8 {
        consume()
    }

    /// Removes the first `n` bytes.
    ///
    /// - Parameter n: The number of bytes to remove.
    /// - Precondition: `n >= 0` and `n <= count`.
    @inlinable
    @_lifetime(self: copy self)
    public mutating func removeFirst(_ n: Int) {
        precondition(n >= 0, "removeFirst(_:) requires non-negative count")
        advance(by: Tagged<Byte, Cardinal>(_unchecked: Cardinal(UInt(bitPattern: n))))
    }

    /// Accesses the byte at the given offset from the current position.
    ///
    /// - Parameter offset: The offset from the current position (0-indexed).
    /// - Precondition: `offset >= 0` and `offset < count`.
    /// - Returns: The byte at the given offset.
    @inlinable
    @_lifetime(copy self)
    public subscript(offset offset: Int) -> UInt8 {
        precondition(offset >= 0, "subscript offset must be non-negative")
        let typedOffset = Tagged<Byte, Cardinal>(_unchecked: Cardinal(UInt(bitPattern: offset)))
        guard let byte = peek(at: typedOffset) else {
            preconditionFailure("subscript offset out of bounds")
        }
        return byte
    }

    /// Checks if the remaining bytes start with the given prefix.
    ///
    /// - Parameter prefix: The prefix to check.
    /// - Returns: `true` if the remaining bytes start with the prefix.
    @inlinable
    public func starts<Prefix: Swift.Collection>(with prefix: Prefix) -> Bool
    where Prefix.Element == UInt8 {
        var i: Int = 0
        for byte in prefix {
            let typedOffset = Tagged<Byte, Cardinal>(_unchecked: Cardinal(UInt(bitPattern: i)))
            guard let observed = peek(at: typedOffset), observed == byte else { return false }
            i += 1
        }
        return true
    }
}

// MARK: - Domain owned-form conversion

extension Cursor where DomainTag == Byte {
    /// Copies the remaining bytes to an owned input.
    ///
    /// Use this when you need to store or send the input across concurrency domains.
    ///
    /// - Returns: An owned `Binary.Bytes.Input` containing the remaining bytes.
    @inlinable
    public func copyToOwned() -> Binary.Bytes.Input {
        let remaining = Int(bitPattern: count)
        var bytes: [UInt8] = []
        bytes.reserveCapacity(remaining)
        var i: Int = 0
        while i < remaining {
            let typedOffset = Tagged<Byte, Cardinal>(_unchecked: Cardinal(UInt(bitPattern: i)))
            if let b = peek(at: typedOffset) {
                bytes.append(b)
            }
            i += 1
        }
        return Binary.Bytes.Input(bytes)
    }
}
