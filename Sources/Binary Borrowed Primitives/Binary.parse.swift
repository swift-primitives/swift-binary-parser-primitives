// Binary.parse.swift
// Zero-copy borrowed parsing APIs with inlined interpreter

internal import Index_Primitives
public import Vector_Primitive
public import Machine_Primitives
internal import Memory_Primitives
import Standard_Library_Extensions
public import Byte_Primitives
public import Byte_Primitives_Standard_Library_Integration
public import Cursor_Primitives

//
// ## Design Note
//
// The interpreter is LITERALLY inlined into the engine on Binary.Borrowed.
// This is required because Swift 6.x's lifetime checker sees ANY function
// call with `inout Cursor<Byte>` as a potential escape.
//
// CRITICAL: NO COMPUTED PROPERTY READS on Cursor<Byte> inside the interpreter.
// The lifetime checker cannot reason through computed property accessors in
// complex control flow. Track position externally via local counters.
//
// Allowed operations on view:
// - removeFirst() / removeFirst(n) - mutating consumption
// - subscript(offset:) - peek without consuming
// - position = x - write for backtracking (writes appear to be okay)
//
// Forbidden operations on view inside interpreter:
// - consumed, count, isEmpty, first (computed properties)

// MARK: - Typed Count Constants

/// Typed count constants for common byte widths.
/// These avoid repeated construction of Index<Byte>.Count values.
@usableFromInline
let _two: Index<Byte>.Count = Index<Byte>.Count(Cardinal(2))
@usableFromInline
let _four: Index<Byte>.Count = Index<Byte>.Count(Cardinal(4))
@usableFromInline
let _eight: Index<Byte>.Count = Index<Byte>.Count(Cardinal(8))

// MARK: - Binary parsing (owned)

extension Binary {
    /// Executes a machine parser on this binary buffer's bytes.
    ///
    /// Equivalent to `parsePrefix(parser).value` — returns the parsed value
    /// and discards the consumed-count.
    @inlinable
    public borrowing func parse<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> Output {
        try view.parse(parser)
    }

    /// Executes a machine parser on this binary buffer's bytes, returning
    /// the parsed value and the number of bytes consumed.
    @inlinable
    public borrowing func parsePrefix<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> (value: Output, count: Index<Byte>.Count) {
        try view.parsePrefix(parser)
    }

    /// Executes a machine parser on this binary buffer's bytes, returning
    /// the parsed value and the number of bytes consumed (unconstrained).
    @inlinable
    public borrowing func parsePrefixUnchecked<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> (value: Output, count: Index<Byte>.Count) {
        try view.parsePrefixUnchecked(parser)
    }

    /// Executes a machine parser on this binary buffer's bytes, requiring
    /// all input to be consumed.
    ///
    /// If any bytes remain after parsing, throws `.expectedEnd`.
    @inlinable
    public borrowing func parseWhole<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> Output {
        try view.parseWhole(parser)
    }
}

// MARK: - Binary.Borrowed parsing (borrowed view)

extension Binary.Borrowed {
    /// Executes a machine parser on this borrowed view of bytes.
    ///
    /// Equivalent to `parsePrefix(parser).value` — returns the parsed value
    /// and discards the consumed-count.
    @inlinable
    public func parse<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> Output {
        try _parsePrefix(parser).value
    }

    /// Executes a machine parser on this borrowed view of bytes, returning
    /// the parsed value and the number of bytes consumed.
    @inlinable
    public func parsePrefix<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> (value: Output, count: Index<Byte>.Count) {
        try _parsePrefix(parser)
    }

    /// Executes a machine parser on this borrowed view of bytes, returning
    /// the parsed value and the number of bytes consumed (unconstrained).
    @inlinable
    public func parsePrefixUnchecked<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> (value: Output, count: Index<Byte>.Count) {
        try _parsePrefix(parser)
    }

    /// Executes a machine parser on this borrowed view of bytes, requiring
    /// all input to be consumed.
    ///
    /// If any bytes remain after parsing, throws `.expectedEnd`.
    @inlinable
    public func parseWhole<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> Output {
        let (value, consumed) = try _parsePrefix(parser)
        let remaining = count.subtract.saturating(consumed)
        guard remaining == .zero else {
            throw Binary.Machine.Fault.expectedEnd(remaining: remaining)
        }
        return value
    }
}

// MARK: - Internal Interpreter (engine on Binary.Borrowed)

extension Binary.Borrowed {
    /// Internal engine: runs the machine interpreter against the borrowed
    /// span and returns both the parsed value and the consumed-count.
    @inlinable
    internal func _parsePrefix<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) throws(Binary.Machine.Fault) -> (value: Output, count: Index<Byte>.Count) {
        let sourceBytes = self.span
        let total = Index<Byte>.Count(Cardinal(UInt(sourceBytes.count)))
        var view = Cursor<Byte>(sourceBytes)

        typealias Value = Binary.Machine.Value
        typealias Frame = Binary.Machine.Frame
        typealias Node = Binary.Machine.Node
        typealias Fault = Binary.Machine.Fault

        let program = parser.program
        var current = parser.root
        let stackCapacity = (program.maxDepth ?? 1000) * 4
        var frames: [Frame] = []
        frames.reserveCapacity(stackCapacity)

        var arena = Value.Arena(capacity: stackCapacity * 2)
        var depth = 0
        var pendingHandle: Value.Handle? = nil
        var instructionError: Fault? = nil
        var consumed: Index<Byte> = .zero

        interpreterLoop: while true {
            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    return (value: value[as: Output.self], count: Index<Byte>.Count(consumed))
                }

                let frame = frames.removeLast()

                switch frame {
                case .map(let transform):
                    pendingHandle = arena.allocate(transform.apply(using: program.captures, value))

                case .tryMap(let transform):
                    do throws(Fault) {
                        pendingHandle = arena.allocate(try transform.apply(using: program.captures, value))
                    } catch {
                        instructionError = error
                    }

                case .sequence(.second(let b, let combine)):
                    frames.append(.sequence(.combine(firstHandle: arena.allocate(value), combine: combine)))
                    current = b
                    continue interpreterLoop

                case .sequence(.combine(let firstHandle, let combine)):
                    pendingHandle = arena.allocate(combine.combine(using: program.captures, arena.release(firstHandle), value))

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, _, var resultHandles, let finalize):
                    resultHandles.append(arena.allocate(value))
                    frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: resultHandles, finalize: finalize))
                    current = child
                    continue interpreterLoop

                case .fold(let child, _, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(newAcc), combine: combine))
                    current = child
                    continue interpreterLoop

                case .optional(_, let wrapSome, let noneHandle):
                    _ = arena.release(noneHandle)
                    pendingHandle = arena.allocate(wrapSome.apply(using: program.captures, value))

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .flatMap(let next):
                    current = next.next(using: program.captures, value)
                    continue interpreterLoop

                case .extra(let never):
                    switch never {}
                }

                if instructionError == nil {
                    continue interpreterLoop
                }
            }

            if let error = instructionError {
                instructionError = nil
                var recovered = false
                while let recoveryFrame = frames.popLast() {
                    switch recoveryFrame {
                    case .oneOf(let alternatives, let index, let savedCheckpoint):
                        if index < alternatives.count {
                            view.seek(to: savedCheckpoint)
                            consumed = savedCheckpoint
                            frames.append(.oneOf(alternatives: alternatives, index: index + 1, savedCheckpoint: savedCheckpoint))
                            current = alternatives[index]
                            recovered = true
                        }
                    case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                        view.seek(to: savedCheckpoint)
                        consumed = savedCheckpoint
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for h in resultHandles { results.append(arena.release(h)) }
                        pendingHandle = arena.allocate(finalize.finalize(using: program.captures, results))
                        recovered = true
                    case .fold(_, let savedCheckpoint, let accHandle, _):
                        view.seek(to: savedCheckpoint)
                        consumed = savedCheckpoint
                        pendingHandle = accHandle
                        recovered = true
                    case .optional(let savedCheckpoint, _, let noneHandle):
                        view.seek(to: savedCheckpoint)
                        consumed = savedCheckpoint
                        pendingHandle = noneHandle
                        recovered = true
                    case .recursiveExit:
                        depth -= 1
                    case .map, .tryMap, .flatMap, .sequence, .extra:
                        continue
                    }
                    if recovered { break }
                }
                if !recovered { throw error }
                continue interpreterLoop
            }

            let node = program[current]

            switch node {
            case .leaf(let instruction):
                let remaining = total.subtract.saturating(Index<Byte>.Count(consumed))

                switch instruction {
                case .take1:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let b = view.consume()
                        consumed += .one
                        pendingHandle = arena.allocate(Value.make(b))
                    }
                case .take(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        var bytes: [Byte] = []
                        bytes.reserveCapacity(n)
                        (.zero..<need).forEach { _ in
                            bytes.append(view.consume())
                            consumed += .one
                        }
                        pendingHandle = arena.allocate(Value.make(bytes))
                    }
                case .skip(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        view.advance(by: need)
                        consumed += need
                        pendingHandle = arena.allocate(Value.make(()))
                    }
                case .peek:
                    let byte: Byte? = remaining > .zero ? view.peek()! : nil
                    pendingHandle = arena.allocate(Value.make(byte))
                case .byte(let expected):
                    if remaining < .one {
                        instructionError = .unexpectedByte(expected: expected, found: nil)
                    } else {
                        let found = view.peek()!
                        if found == expected {
                            _ = view.consume()
                            consumed += .one
                            pendingHandle = arena.allocate(Value.make(expected))
                        } else {
                            instructionError = .unexpectedByte(expected: expected, found: found)
                        }
                    }
                case .bytes(let expected):
                    let expectedCount = Index<Byte>.Count(Cardinal(UInt(expected.count)))
                    if remaining < expectedCount {
                        var found: [Byte] = []
                        (.zero..<remaining).forEach { idx in
                            found.append(view.peek(at: idx.map { Cardinal($0) })!)
                        }
                        instructionError = .unexpectedBytes(expected: expected, found: found)
                    } else {
                        var mismatch = false
                        var viewIdx: Index<Byte> = .zero
                        for expectedByte in expected {
                            if view.peek(at: viewIdx.map { Cardinal($0) })! != expectedByte {
                                var found: [Byte] = []
                                (.zero..<expectedCount).forEach { j in
                                    found.append(view.peek(at: j.map { Cardinal($0) })!)
                                }
                                instructionError = .unexpectedBytes(expected: expected, found: found)
                                mismatch = true
                                break
                            }
                            viewIdx += .one
                        }
                        if !mismatch {
                            view.advance(by: expectedCount)
                            consumed += expectedCount
                            pendingHandle = arena.allocate(Value.make(expected))
                        }
                    }
                case .satisfy(let predicate):
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let byte = view.peek()!
                        if predicate(byte) {
                            _ = view.consume()
                            consumed += .one
                            pendingHandle = arena.allocate(Value.make(byte))
                        } else {
                            instructionError = .predicateFailed(byte: byte)
                        }
                    }
                case .takeWhile(let predicate):
                    var bytes: [Byte] = []
                    while consumed < total {
                        let byte = view.peek()!
                        if predicate(byte) {
                            bytes.append(view.consume())
                            consumed += .one
                        } else {
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(bytes))
                case .skipWhile(let predicate):
                    while consumed < total {
                        let byte = view.peek()!
                        if predicate(byte) {
                            _ = view.consume()
                            consumed += .one
                        } else {
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(()))
                case .end:
                    if remaining == .zero {
                        pendingHandle = arena.allocate(Value.make(()))
                    } else {
                        instructionError = .expectedEnd(remaining: remaining)
                    }
                case .require(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining >= need {
                        pendingHandle = arena.allocate(Value.make(()))
                    } else {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    }
                case .u8:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let b = view.consume().underlying
                        consumed += .one
                        pendingHandle = arena.allocate(Value.make(b))
                    }
                case .u16le:
                    if remaining < _two {
                        instructionError = .insufficientBytes(need: _two, have: remaining)
                    } else {
                        let b0 = UInt16(view.consume())
                        let b1 = UInt16(view.consume())
                        consumed += _two
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8)))
                    }
                case .u16be:
                    if remaining < _two {
                        instructionError = .insufficientBytes(need: _two, have: remaining)
                    } else {
                        let b0 = UInt16(view.consume())
                        let b1 = UInt16(view.consume())
                        consumed += _two
                        pendingHandle = arena.allocate(Value.make((b0 << 8) | b1))
                    }
                case .u32le:
                    if remaining < _four {
                        instructionError = .insufficientBytes(need: _four, have: remaining)
                    } else {
                        let b0 = UInt32(view.consume())
                        let b1 = UInt32(view.consume())
                        let b2 = UInt32(view.consume())
                        let b3 = UInt32(view.consume())
                        consumed += _four
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))
                    }
                case .u32be:
                    if remaining < _four {
                        instructionError = .insufficientBytes(need: _four, have: remaining)
                    } else {
                        let b0 = UInt32(view.consume())
                        let b1 = UInt32(view.consume())
                        let b2 = UInt32(view.consume())
                        let b3 = UInt32(view.consume())
                        consumed += _four
                        pendingHandle = arena.allocate(Value.make((b0 << 24) | (b1 << 16) | (b2 << 8) | b3))
                    }
                case .u64le:
                    if remaining < _eight {
                        instructionError = .insufficientBytes(need: _eight, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        var shift: UInt64 = 0
                        (.zero..<_eight).forEach { _ in
                            result |= UInt64(view.consume()) << shift
                            shift += 8
                        }
                        consumed += _eight
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                case .u64be:
                    if remaining < _eight {
                        instructionError = .insufficientBytes(need: _eight, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        (.zero..<_eight).forEach { _ in
                            result = (result << 8) | UInt64(view.consume())
                        }
                        consumed += _eight
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                case .i8:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let b = view.consume()
                        consumed += .one
                        pendingHandle = arena.allocate(Value.make(Int8(bitPattern: b)))
                    }
                case .i16le:
                    if remaining < _two {
                        instructionError = .insufficientBytes(need: _two, have: remaining)
                    } else {
                        let b0 = UInt16(view.consume())
                        let b1 = UInt16(view.consume())
                        consumed += _two
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: b0 | (b1 << 8))))
                    }
                case .i16be:
                    if remaining < _two {
                        instructionError = .insufficientBytes(need: _two, have: remaining)
                    } else {
                        let b0 = UInt16(view.consume())
                        let b1 = UInt16(view.consume())
                        consumed += _two
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: (b0 << 8) | b1)))
                    }
                case .i32le:
                    if remaining < _four {
                        instructionError = .insufficientBytes(need: _four, have: remaining)
                    } else {
                        let b0 = UInt32(view.consume())
                        let b1 = UInt32(view.consume())
                        let b2 = UInt32(view.consume())
                        let b3 = UInt32(view.consume())
                        consumed += _four
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))))
                    }
                case .i32be:
                    if remaining < _four {
                        instructionError = .insufficientBytes(need: _four, have: remaining)
                    } else {
                        let b0 = UInt32(view.consume())
                        let b1 = UInt32(view.consume())
                        let b2 = UInt32(view.consume())
                        let b3 = UInt32(view.consume())
                        consumed += _four
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: (b0 << 24) | (b1 << 16) | (b2 << 8) | b3)))
                    }
                case .i64le:
                    if remaining < _eight {
                        instructionError = .insufficientBytes(need: _eight, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        var shift: UInt64 = 0
                        (.zero..<_eight).forEach { _ in
                            result |= UInt64(view.consume()) << shift
                            shift += 8
                        }
                        consumed += _eight
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }
                case .i64be:
                    if remaining < _eight {
                        instructionError = .insufficientBytes(need: _eight, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        (.zero..<_eight).forEach { _ in
                            result = (result << 8) | UInt64(view.consume())
                        }
                        consumed += _eight
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }
                case .uleb128:
                    var result: UInt64 = 0
                    var shift: UInt64 = 0
                    var overflow = false
                    var done = false
                    while !done {
                        if consumed >= total {
                            instructionError = .insufficientBytes(need: .one, have: .zero)
                            break
                        }
                        let byte = view.consume()
                        consumed += .one
                        let byteValue = UInt64(byte & 0x7F)
                        if shift >= 64 || (shift == 63 && byteValue > 1) {
                            overflow = true
                            break
                        }
                        result |= byteValue << shift
                        if byte & 0x80 == 0 { done = true } else { shift += 7 }
                    }
                    if overflow { instructionError = .leb128Overflow } else if done { pendingHandle = arena.allocate(Value.make(result)) }
                case .sleb128:
                    var result: Int64 = 0
                    var shift: UInt64 = 0
                    var byte: Byte = 0
                    var overflow = false
                    var done = false
                    while !done {
                        if consumed >= total {
                            instructionError = .insufficientBytes(need: .one, have: .zero)
                            break
                        }
                        byte = view.consume()
                        consumed += .one
                        if shift >= 64 {
                            overflow = true
                            break
                        }
                        result |= Int64(byte & 0x7F) << shift
                        shift += 7
                        if byte & 0x80 == 0 { done = true }
                    }
                    if overflow {
                        instructionError = .leb128Overflow
                    } else if done {
                        if shift < 64 && (byte & 0x40) != 0 { result |= -(1 << shift) }
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                }

            case .pure(let value):
                pendingHandle = arena.allocate(value)

            case .map(let child, let transform):
                frames.append(.map(transform: transform))
                current = child

            case .tryMap(let child, let transform):
                frames.append(.tryMap(transform: transform))
                current = child

            case .flatMap(let child, let next):
                frames.append(.flatMap(next: next))
                current = child

            case .sequence(let a, let b, let combine):
                frames.append(.sequence(.second(b: b, combine: combine)))
                current = a

            case .oneOf(let alternatives):
                guard !alternatives.isEmpty else { fatalError("Empty oneOf") }
                if alternatives.count > 1 {
                    frames.append(.oneOf(alternatives: alternatives, index: 1, savedCheckpoint: consumed))
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: [], finalize: finalize))
                current = child

            case .fold(let child, let initial, let combine):
                frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(initial), combine: combine))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                frames.append(.optional(savedCheckpoint: consumed, wrapSome: wrapSome, noneHandle: arena.allocate(noneValue)))
                current = child

            case .ref(let target):
                if let limit = program.maxDepth, depth >= limit {
                    instructionError = .depthExceeded(limit: limit)
                } else {
                    depth += 1
                    frames.append(.recursiveExit)
                    current = target
                }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
    }
}

// MARK: - Owned-Input Convenience Constructors

extension Binary {
    /// Constructs a `Byte.Input` over `bytes` and runs `body` against it.
    ///
    /// The input is consumed within the closure's scope and not exposed
    /// to callers.
    @inlinable
    public static func withInput<T, E: Swift.Error>(
        _ bytes: [Byte],
        _ body: (inout Byte.Input) throws(E) -> T
    ) throws(E) -> T {
        var input = Byte.Input(bytes)
        return try body(&input)
    }

    /// Constructs a `Byte.Input` by copying `bytes` and runs `body` against it.
    @inlinable
    public static func withInput<Bytes, T, E: Swift.Error>(
        _ bytes: Bytes,
        _ body: (inout Byte.Input) throws(E) -> T
    ) throws(E) -> T where Bytes: Swift.Collection, Bytes.Element == Byte {
        var input = Byte.Input(Swift.Array(bytes))
        return try body(&input)
    }

    /// Constructs a `Byte.Input` from a string's UTF-8 bytes and runs `body`.
    @inlinable
    public static func withInput<T, E: Swift.Error>(
        _ string: some StringProtocol,
        _ body: (inout Byte.Input) throws(E) -> T
    ) throws(E) -> T {
        var input = Byte.Input(Swift.Array(string.utf8))
        return try body(&input)
    }
}
