// Binary.Bytes.Machine.Run.swift
// Owned executor for Machine programs

public import Machine_Primitives
public import Parser_Primitives
public import Index_Primitives

extension Binary.Bytes.Machine {
    /// Executes a Machine program on any byte-oriented Parser_Primitives.Parser.Input.
    ///
    /// This is the owned-path executor, complementing the borrowed-path `withBorrowed`.
    /// Both execute the same IR (Machine.Program); this one operates on any `Parser_Primitives.Parser.Input`
    /// where `Element == UInt8` and `Checkpoint == Int`.
    ///
    /// This generalization allows zero-copy parsing on both `Binary.Bytes.Input` and
    /// `ArraySlice<UInt8>` without conversion overhead.
    ///
    /// - Parameters:
    ///   - program: The program to execute.
    ///   - root: The root node ID.
    ///   - input: The input cursor (any Parser_Primitives.Parser.Input with UInt8 elements).
    /// - Returns: The parsed output.
    /// - Throws: `Fault` on parsing failure.
    @usableFromInline
    static func run<Input: Parser_Primitives.Parser.Input, Output>(
        program: Program,
        root: Node.ID,
        input: inout Input,
        as outputType: Output.Type
    ) throws(Fault) -> Output where Input.Element == UInt8, Input.Checkpoint == Index<UInt8> {
        typealias Frame = Binary.Bytes.Machine.Frame
        typealias Value = Binary.Bytes.Machine.Value
        typealias Node = Binary.Bytes.Machine.Node

        // Use same stack sizing policy as Parsing
        let stackCapacity = (program.maxDepth ?? 10_000) * 4
        var frames: [Frame] = []
        frames.reserveCapacity(stackCapacity)

        var current = root
        var arena = Value.Arena(capacity: stackCapacity * 2)
        var depth = 0
        var pendingHandle: Value.Handle? = nil
        var instructionError: Fault? = nil

        interpreterLoop: while true {
            // Handle pending value from previous iteration
            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    return value[as: Output.self]
                }

                let frame = frames.removeLast()

                switch frame {
                case .map(let transform):
                    pendingHandle = arena.allocate(transform.apply(using: program.captures, value))

                case .tryMap(let transform):
                    do {
                        pendingHandle = arena.allocate(try transform.apply(using: program.captures, value))
                    } catch let error as Fault {
                        instructionError = error
                    }

                case .flatMap(let next):
                    current = next.next(using: program.captures, value)
                    continue interpreterLoop

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
                    frames.append(.many(child: child, savedCheckpoint: input.checkpoint, resultHandles: resultHandles, finalize: finalize))
                    current = child
                    continue interpreterLoop

                case .fold(let child, _, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    frames.append(.fold(child: child, savedCheckpoint: input.checkpoint, accumulatorHandle: arena.allocate(newAcc), combine: combine))
                    current = child
                    continue interpreterLoop

                case .optional(_, let wrapSome, let noneHandle):
                    // Discard none-handle on success to avoid arena leak
                    _ = arena.release(noneHandle)
                    pendingHandle = arena.allocate(wrapSome.apply(using: program.captures, value))

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .extra(let never):
                    switch never {}
                }

                if instructionError == nil {
                    continue interpreterLoop
                }
            }

            // Handle error recovery
            if let error = instructionError {
                instructionError = nil
                var recovered = false
                while let recoveryFrame = frames.popLast() {
                    switch recoveryFrame {
                    case .oneOf(let alternatives, let index, let savedCheckpoint):
                        guard index < alternatives.count else { break }
                        input.setPosition(to: savedCheckpoint)
                        frames.append(.oneOf(alternatives: alternatives, index: index + 1, savedCheckpoint: savedCheckpoint))
                        current = alternatives[index]
                        recovered = true
                        break

                    case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                        input.setPosition(to: savedCheckpoint)
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for h in resultHandles { results.append(arena.release(h)) }
                        pendingHandle = arena.allocate(finalize.finalize(using: program.captures, results))
                        recovered = true

                    case .fold(_, let savedCheckpoint, let accHandle, _):
                        input.setPosition(to: savedCheckpoint)
                        pendingHandle = accHandle
                        recovered = true

                    case .optional(let savedCheckpoint, _, let noneHandle):
                        input.setPosition(to: savedCheckpoint)
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

            // Execute current node
            let node = program[current]

            switch node {
            case .leaf(let instruction):
                let remaining = input.count

                switch instruction {
                case .take1:
                    if remaining < .one { instructionError = .insufficientBytes(need: .one, have: remaining) }
                    else { pendingHandle = arena.allocate(Value.make(try! input.advance())) }

                case .take(let n):
                    let need = Index<UInt8>.Count(Cardinal(UInt(n)))
                    if remaining < need { instructionError = .insufficientBytes(need: need, have: remaining) }
                    else {
                        var bytes: [UInt8] = []
                        bytes.reserveCapacity(n)
                        for _ in 0..<n { bytes.append(try! input.advance()) }
                        pendingHandle = arena.allocate(Value.make(bytes))
                    }

                case .skip(let n):
                    let need = Index<UInt8>.Count(Cardinal(UInt(n)))
                    if remaining < need { instructionError = .insufficientBytes(need: need, have: remaining) }
                    else { input.advance(by: need); pendingHandle = arena.allocate(Value.make(())) }

                case .peek:
                    if input.isEmpty {
                        pendingHandle = arena.allocate(Value.make(UInt8?.none))
                    } else {
                        let cp = input.checkpoint
                        let byte = try! input.advance()
                        input.setPosition(to: cp)
                        pendingHandle = arena.allocate(Value.make(UInt8?(byte)))
                    }

                case .byte(let expected):
                    if remaining < .one { instructionError = .insufficientBytes(need: .one, have: remaining) }
                    else {
                        let cp = input.checkpoint
                        let byte = try! input.advance()
                        if byte != expected {
                            input.setPosition(to: cp)
                            instructionError = .unexpectedByte(expected: expected, found: byte)
                        } else {
                            pendingHandle = arena.allocate(Value.make(byte))
                        }
                    }

                case .bytes(let expected):
                    let n = expected.count
                    let need = Index<UInt8>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        // Save checkpoint before consuming
                        let cp = input.checkpoint
                        var found: [UInt8] = []
                        found.reserveCapacity(n)
                        var mismatch = false

                        // Consume and compare byte by byte
                        for expectedByte in expected {
                            let actual = try! input.advance()
                            found.append(actual)
                            if actual != expectedByte { mismatch = true }
                        }

                        if mismatch {
                            // Restore to checkpoint on mismatch
                            input.setPosition(to: cp)
                            instructionError = .unexpectedBytes(expected: expected, found: found)
                        } else {
                            // Input already advanced past expected bytes
                            pendingHandle = arena.allocate(Value.make(expected))
                        }
                    }

                case .satisfy(let predicate):
                    if remaining < .one { instructionError = .insufficientBytes(need: .one, have: remaining) }
                    else {
                        let cp = input.checkpoint
                        let byte = try! input.advance()
                        if predicate(byte) {
                            pendingHandle = arena.allocate(Value.make(byte))
                        } else {
                            input.setPosition(to: cp)
                            instructionError = .predicateFailed(byte: byte)
                        }
                    }

                case .takeWhile(let predicate):
                    var bytes: [UInt8] = []
                    while !input.isEmpty {
                        let cp = input.checkpoint
                        let byte = try! input.advance()
                        if predicate(byte) {
                            bytes.append(byte)
                        } else {
                            input.setPosition(to: cp)
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(bytes))

                case .skipWhile(let predicate):
                    while !input.isEmpty {
                        let cp = input.checkpoint
                        let byte = try! input.advance()
                        if !predicate(byte) {
                            input.setPosition(to: cp)
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(()))

                case .end:
                    if !input.isEmpty { instructionError = .expectedEnd(remaining: remaining) }
                    else { pendingHandle = arena.allocate(Value.make(())) }

                case .require(let n):
                    let need = Index<UInt8>.Count(Cardinal(UInt(n)))
                    if remaining < need { instructionError = .insufficientBytes(need: need, have: remaining) }
                    else { pendingHandle = arena.allocate(Value.make(())) }

                // Integer decoding (unsigned)
                case .u8:
                    if remaining < .one { instructionError = .insufficientBytes(need: .one, have: remaining) }
                    else { pendingHandle = arena.allocate(Value.make(try! input.advance())) }

                case .u16le:
                    if remaining < Index<UInt8>.Count(Cardinal(2)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(2)), have: remaining) }
                    else {
                        let b0 = UInt16(try! input.advance())
                        let b1 = UInt16(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8)))
                    }

                case .u16be:
                    if remaining < Index<UInt8>.Count(Cardinal(2)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(2)), have: remaining) }
                    else {
                        let b0 = UInt16(try! input.advance())
                        let b1 = UInt16(try! input.advance())
                        pendingHandle = arena.allocate(Value.make((b0 << 8) | b1))
                    }

                case .u32le:
                    if remaining < Index<UInt8>.Count(Cardinal(4)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(4)), have: remaining) }
                    else {
                        let b0 = UInt32(try! input.advance())
                        let b1 = UInt32(try! input.advance())
                        let b2 = UInt32(try! input.advance())
                        let b3 = UInt32(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))
                    }

                case .u32be:
                    if remaining < Index<UInt8>.Count(Cardinal(4)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(4)), have: remaining) }
                    else {
                        let b0 = UInt32(try! input.advance())
                        let b1 = UInt32(try! input.advance())
                        let b2 = UInt32(try! input.advance())
                        let b3 = UInt32(try! input.advance())
                        pendingHandle = arena.allocate(Value.make((b0 << 24) | (b1 << 16) | (b2 << 8) | b3))
                    }

                case .u64le:
                    if remaining < Index<UInt8>.Count(Cardinal(8)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(8)), have: remaining) }
                    else {
                        var result: UInt64 = 0
                        for i in 0..<8 {
                            result |= UInt64(try! input.advance()) << (i * 8)
                        }
                        pendingHandle = arena.allocate(Value.make(result))
                    }

                case .u64be:
                    if remaining < Index<UInt8>.Count(Cardinal(8)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(8)), have: remaining) }
                    else {
                        var result: UInt64 = 0
                        for _ in 0..<8 {
                            result = (result << 8) | UInt64(try! input.advance())
                        }
                        pendingHandle = arena.allocate(Value.make(result))
                    }

                // Integer decoding (signed)
                case .i8:
                    if remaining < .one { instructionError = .insufficientBytes(need: .one, have: remaining) }
                    else { pendingHandle = arena.allocate(Value.make(Int8(bitPattern: try! input.advance()))) }

                case .i16le:
                    if remaining < Index<UInt8>.Count(Cardinal(2)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(2)), have: remaining) }
                    else {
                        let b0 = UInt16(try! input.advance())
                        let b1 = UInt16(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: b0 | (b1 << 8))))
                    }

                case .i16be:
                    if remaining < Index<UInt8>.Count(Cardinal(2)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(2)), have: remaining) }
                    else {
                        let b0 = UInt16(try! input.advance())
                        let b1 = UInt16(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: (b0 << 8) | b1)))
                    }

                case .i32le:
                    if remaining < Index<UInt8>.Count(Cardinal(4)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(4)), have: remaining) }
                    else {
                        let b0 = UInt32(try! input.advance())
                        let b1 = UInt32(try! input.advance())
                        let b2 = UInt32(try! input.advance())
                        let b3 = UInt32(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))))
                    }

                case .i32be:
                    if remaining < Index<UInt8>.Count(Cardinal(4)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(4)), have: remaining) }
                    else {
                        let b0 = UInt32(try! input.advance())
                        let b1 = UInt32(try! input.advance())
                        let b2 = UInt32(try! input.advance())
                        let b3 = UInt32(try! input.advance())
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: (b0 << 24) | (b1 << 16) | (b2 << 8) | b3)))
                    }

                case .i64le:
                    if remaining < Index<UInt8>.Count(Cardinal(8)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(8)), have: remaining) }
                    else {
                        var result: UInt64 = 0
                        for i in 0..<8 {
                            result |= UInt64(try! input.advance()) << (i * 8)
                        }
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }

                case .i64be:
                    if remaining < Index<UInt8>.Count(Cardinal(8)) { instructionError = .insufficientBytes(need: Index<UInt8>.Count(Cardinal(8)), have: remaining) }
                    else {
                        var result: UInt64 = 0
                        for _ in 0..<8 {
                            result = (result << 8) | UInt64(try! input.advance())
                        }
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }

                // Variable-length integers
                case .uleb128:
                    var result: UInt64 = 0
                    var shift: UInt64 = 0
                    var overflow = false
                    var done = false
                    while !done {
                        guard !input.isEmpty else {
                            instructionError = .insufficientBytes(need: .one, have: .zero)
                            break
                        }
                        let byte = try! input.advance()
                        let byteValue = UInt64(byte & 0x7F)
                        if shift >= 64 || (shift == 63 && byteValue > 1) {
                            overflow = true
                            break
                        }
                        result |= byteValue << shift
                        if byte & 0x80 == 0 { done = true }
                        else { shift += 7 }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done { pendingHandle = arena.allocate(Value.make(result)) }

                case .sleb128:
                    var result: Int64 = 0
                    var shift: UInt64 = 0
                    var byte: UInt8 = 0
                    var overflow = false
                    var done = false
                    while !done {
                        guard !input.isEmpty else {
                            instructionError = .insufficientBytes(need: .one, have: .zero)
                            break
                        }
                        byte = try! input.advance()
                        if shift >= 64 {
                            overflow = true
                            break
                        }
                        result |= Int64(byte & 0x7F) << shift
                        shift += 7
                        if byte & 0x80 == 0 { done = true }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done {
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
                    frames.append(.oneOf(alternatives: alternatives, index: 1, savedCheckpoint: input.checkpoint))
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                frames.append(.many(child: child, savedCheckpoint: input.checkpoint, resultHandles: [], finalize: finalize))
                current = child

            case .fold(let child, let initial, let combine):
                frames.append(.fold(child: child, savedCheckpoint: input.checkpoint, accumulatorHandle: arena.allocate(initial), combine: combine))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                frames.append(.optional(savedCheckpoint: input.checkpoint, wrapSome: wrapSome, noneHandle: arena.allocate(noneValue)))
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

// MARK: - Parser Extension

extension Binary.Bytes.Machine.Parser {
    /// Executes this parser on any byte-oriented Parser_Primitives.Parser.Input.
    ///
    /// This generic overload allows zero-copy parsing on both `Binary.Bytes.Input` and
    /// `ArraySlice<UInt8>` without conversion overhead.
    ///
    /// - Parameter input: Any Parser_Primitives.Parser.Input with UInt8 elements and Int checkpoint.
    /// - Returns: The parsed output.
    /// - Throws: `Fault` on parsing failure.
    @inlinable
    public func parse<Input: Parser_Primitives.Parser.Input>(
        _ input: inout Input
    ) throws(Binary.Bytes.Machine.Fault) -> Output
    where Input.Element == UInt8, Input.Checkpoint == Index<UInt8> {
        try Binary.Bytes.Machine.run(program: program, root: root, input: &input, as: Output.self)
    }
}
