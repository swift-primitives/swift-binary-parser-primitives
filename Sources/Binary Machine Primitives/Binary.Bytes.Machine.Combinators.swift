// Binary.Bytes.Machine.Combinators.swift
// Combinator API for building machine programs

public import Byte_Primitives
public import Machine_Primitives

// MARK: - Instruction Expressions

extension Binary.Bytes.Machine {
    /// Creates an expression for the take1 instruction.
    @inlinable
    public static func take1(
        in builder: inout Builder
    ) -> Expression<Byte> {
        let node = Node.leaf(.take1)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for taking n bytes.
    @inlinable
    public static func take(
        _ n: Int,
        in builder: inout Builder
    ) -> Expression<[Byte]> {
        let node = Node.leaf(.take(n))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for skipping n bytes.
    @inlinable
    public static func skip(
        _ n: Int,
        in builder: inout Builder
    ) -> Expression<Void> {
        let node = Node.leaf(.skip(n))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for matching a specific byte.
    @inlinable
    public static func byte(
        _ expected: Byte,
        in builder: inout Builder
    ) -> Expression<Byte> {
        let node = Node.leaf(.byte(expected))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for matching a byte sequence.
    @inlinable
    public static func bytes(
        _ expected: [Byte],
        in builder: inout Builder
    ) -> Expression<[Byte]> {
        let node = Node.leaf(.bytes(expected))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for matching end of input.
    @inlinable
    public static func end(
        in builder: inout Builder
    ) -> Expression<Void> {
        let node = Node.leaf(.end)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    // MARK: - Unsigned Integer Expressions

    /// Creates an expression for u8.
    @inlinable
    public static func u8(
        in builder: inout Builder
    ) -> Expression<UInt8> {
        let node = Node.leaf(.u8)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u16 little-endian.
    @inlinable
    public static func u16le(
        in builder: inout Builder
    ) -> Expression<UInt16> {
        let node = Node.leaf(.u16le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u16 big-endian.
    @inlinable
    public static func u16be(
        in builder: inout Builder
    ) -> Expression<UInt16> {
        let node = Node.leaf(.u16be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u32 little-endian.
    @inlinable
    public static func u32le(
        in builder: inout Builder
    ) -> Expression<UInt32> {
        let node = Node.leaf(.u32le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u32 big-endian.
    @inlinable
    public static func u32be(
        in builder: inout Builder
    ) -> Expression<UInt32> {
        let node = Node.leaf(.u32be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u64 little-endian.
    @inlinable
    public static func u64le(
        in builder: inout Builder
    ) -> Expression<UInt64> {
        let node = Node.leaf(.u64le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for u64 big-endian.
    @inlinable
    public static func u64be(
        in builder: inout Builder
    ) -> Expression<UInt64> {
        let node = Node.leaf(.u64be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    // MARK: - Signed Integer Expressions

    /// Creates an expression for i8.
    @inlinable
    public static func i8(
        in builder: inout Builder
    ) -> Expression<Int8> {
        let node = Node.leaf(.i8)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i16 little-endian.
    @inlinable
    public static func i16le(
        in builder: inout Builder
    ) -> Expression<Int16> {
        let node = Node.leaf(.i16le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i16 big-endian.
    @inlinable
    public static func i16be(
        in builder: inout Builder
    ) -> Expression<Int16> {
        let node = Node.leaf(.i16be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i32 little-endian.
    @inlinable
    public static func i32le(
        in builder: inout Builder
    ) -> Expression<Int32> {
        let node = Node.leaf(.i32le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i32 big-endian.
    @inlinable
    public static func i32be(
        in builder: inout Builder
    ) -> Expression<Int32> {
        let node = Node.leaf(.i32be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i64 little-endian.
    @inlinable
    public static func i64le(
        in builder: inout Builder
    ) -> Expression<Int64> {
        let node = Node.leaf(.i64le)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for i64 big-endian.
    @inlinable
    public static func i64be(
        in builder: inout Builder
    ) -> Expression<Int64> {
        let node = Node.leaf(.i64be)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    // MARK: - Variable-Length Integer Expressions

    /// Creates an expression for unsigned LEB128.
    @inlinable
    public static func uleb128(
        in builder: inout Builder
    ) -> Expression<UInt64> {
        let node = Node.leaf(.uleb128)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates an expression for signed LEB128.
    @inlinable
    public static func sleb128(
        in builder: inout Builder
    ) -> Expression<Int64> {
        let node = Node.leaf(.sleb128)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Pure

extension Binary.Bytes.Machine {
    /// Creates a pure expression that always succeeds with the given value.
    @inlinable
    public static func pure<Output>(
        _ value: Output,
        in builder: inout Builder
    ) -> Expression<Output> {
        let node = Node.pure(Value.make(value))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Map

extension Binary.Bytes.Machine.Expression {
    /// Transforms the output of this expression.
    @inlinable
    public func map<T>(
        _ transform: @escaping (Output) -> T,
        in builder: inout Binary.Bytes.Machine.Builder
    ) -> Binary.Bytes.Machine.Expression<T> {
        let captureID = builder.captures.insert(transform)
        let node = Binary.Bytes.Machine.Node.map(
            child: self.node,
            transform: Binary.Bytes.Machine.Transform.Erased(capture: captureID)
        )
        let nodeID = builder.allocate(node)
        return Binary.Bytes.Machine.Expression(node: nodeID)
    }

    /// Transforms the output with a throwing function.
    @inlinable
    public func tryMap<T>(
        _ transform: @escaping (Output) throws(Binary.Bytes.Machine.Fault) -> T,
        in builder: inout Binary.Bytes.Machine.Builder
    ) -> Binary.Bytes.Machine.Expression<T> {
        let captureID = builder.captures.insert(transform)
        let node = Binary.Bytes.Machine.Node.tryMap(
            child: self.node,
            transform: Binary.Bytes.Machine.Transform.Throwing(capture: captureID)
        )
        let nodeID = builder.allocate(node)
        return Binary.Bytes.Machine.Expression(node: nodeID)
    }
}

// MARK: - Sequence

extension Binary.Bytes.Machine {
    /// Sequences two expressions and combines their outputs.
    @inlinable
    public static func sequence<A, B, C>(
        _ a: Expression<A>,
        _ b: Expression<B>,
        combine: @escaping (A, B) -> C,
        in builder: inout Builder
    ) -> Expression<C> {
        let captureID = builder.captures.insert(combine)
        let node = Node.sequence(
            a: a.node,
            b: b.node,
            combine: Combine.Erased(capture: captureID)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - OneOf

extension Binary.Bytes.Machine {
    /// Creates an expression that tries alternatives in order until one succeeds.
    @inlinable
    public static func oneOf<Output>(
        _ alternatives: [Expression<Output>],
        in builder: inout Builder
    ) -> Expression<Output> {
        let nodeIDs = alternatives.map { $0.node }
        let node = Node.oneOf(nodeIDs)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Many

extension Binary.Bytes.Machine {
    /// Creates an expression that parses zero or more occurrences.
    @inlinable
    public static func many<T>(
        _ expr: Expression<T>,
        in builder: inout Builder
    ) -> Expression<[T]> {
        let node = Node.many(
            child: expr.node,
            finalize: Finalize.Array(elementType: T.self, store: &builder.captures)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Fold

extension Binary.Bytes.Machine {
    /// Creates an expression that folds zero or more occurrences without allocation.
    ///
    /// Unlike `many` which collects into an array, `fold` accumulates incrementally:
    /// 1. Start with `initial` as accumulator
    /// 2. Try to parse `child`
    /// 3. If success: `accumulator = combine(accumulator, childResult)`, repeat
    /// 4. If failure: return accumulator
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse decimal digits and fold into integer
    /// let digit = take1(in: &builder).tryMap({ byte in
    ///     guard byte >= 0x30 && byte <= 0x39 else { throw .predicateFailed(byte: byte) }
    ///     return Int(byte - 0x30)
    /// }, in: &builder)
    ///
    /// let number = fold(digit, initial: 0, combine: { acc, d in acc * 10 + d }, in: &builder)
    /// ```
    @inlinable
    public static func fold<T, Acc>(
        _ expr: Expression<T>,
        initial: Acc,
        combine: @escaping (Acc, T) -> Acc,
        in builder: inout Builder
    ) -> Expression<Acc> {
        let captureID = builder.captures.insert(combine)
        let node: Node = .fold(
            child: expr.node,
            initial: Value.make(initial),
            combine: Combine.Erased(capture: captureID)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Optional

extension Binary.Bytes.Machine {
    /// Creates an expression that optionally parses its child.
    @inlinable
    public static func optional<T>(
        _ expr: Expression<T>,
        in builder: inout Builder
    ) -> Expression<T?> {
        let wrapSome: (T) -> T? = { Swift.Optional.some($0) }
        let captureID = builder.captures.insert(wrapSome)
        let node = Node.optional(
            child: expr.node,
            wrapSome: Transform.Erased(capture: captureID),
            noneValue: Value.make(T?.none)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}
