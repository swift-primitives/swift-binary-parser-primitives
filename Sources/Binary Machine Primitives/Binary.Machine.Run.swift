internal import Binary_LEB128_Decode_Primitives
public import Byte_Primitives
import Byte_Primitives_Standard_Library_Integration
internal import Index_Primitives
public import Machine_Primitives
import Parser_Primitives

@inline(__always)
private func advanceProvenInBounds<Input: Input_Primitives.Input.`Protocol`>(
    _ input: inout Input
) -> Input.Element where Input.Element == Byte, Input.Checkpoint == Index<Byte> {
    do {
        return try input.advance()
    } catch {
        preconditionFailure("advance() threw after a bounds check proved it could not: \(error)")
    }
}

extension Binary.Machine {

    @usableFromInline
    static func run<Input: Input_Primitives.Input.`Protocol`, Output>(
        program: Program,
        root: Node.ID,
        input: inout Input,
        as outputType: Output.Type
    ) throws(Fault) -> Output where Input.Element == Byte, Input.Checkpoint == Index<Byte> {
        typealias Frame = Binary.Machine.Frame
        typealias Value = Binary.Machine.Value
        typealias Node = Binary.Machine.Node

        let stackCapacity = (program.maxDepth ?? 10_000) * 4
        var frames: [Frame] = []
        frames.reserveCapacity(stackCapacity)

        var current = root
        var arena = Value.Arena(capacity: stackCapacity * 2)
        var depth = 0
        var pendingHandle: Value.Handle? = nil
        var instructionError: Fault? = nil

        interpreterLoop: while true {

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
                    do throws(Fault) {
                        pendingHandle = arena.allocate(
                            try transform.apply(using: program.captures, value)
                        )
                    } catch {
                        instructionError = error
                    }

                case .flatMap(let next):
                    current = next.next(using: program.captures, value)
                    continue interpreterLoop

                case .sequence(.second(let b, let combine)):
                    frames.append(
                        .sequence(.combine(firstHandle: arena.allocate(value), combine: combine))
                    )
                    current = b
                    continue interpreterLoop

                case .sequence(.combine(let firstHandle, let combine)):
                    pendingHandle = arena.allocate(
                        combine.combine(using: program.captures, arena.release(firstHandle), value)
                    )

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, _, var resultHandles, let finalize):
                    resultHandles.append(arena.allocate(value))
                    frames.append(
                        .many(
                            child: child,
                            savedCheckpoint: input.checkpoint,
                            resultHandles: resultHandles,
                            finalize: finalize
                        )
                    )
                    current = child
                    continue interpreterLoop

                case .fold(let child, _, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    frames.append(
                        .fold(
                            child: child,
                            savedCheckpoint: input.checkpoint,
                            accumulatorHandle: arena.allocate(newAcc),
                            combine: combine
                        )
                    )
                    current = child
                    continue interpreterLoop

                case .optional(_, let wrapSome, let noneHandle):

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

            if let error = instructionError {
                instructionError = nil
                var recovered = false
                while let recoveryFrame = frames.popLast() {
                    switch recoveryFrame {
                    case .oneOf(let alternatives, let index, let savedCheckpoint):
                        guard index < alternatives.count else { break }
                        input.seek(to: savedCheckpoint)
                        frames.append(
                            .oneOf(
                                alternatives: alternatives,
                                index: index + 1,
                                savedCheckpoint: savedCheckpoint
                            )
                        )
                        current = alternatives[index]
                        recovered = true

                    case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                        input.seek(to: savedCheckpoint)
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for h in resultHandles { results.append(arena.release(h)) }
                        pendingHandle = arena.allocate(
                            finalize.finalize(using: program.captures, results)
                        )
                        recovered = true

                    case .fold(_, let savedCheckpoint, let accHandle, _):
                        input.seek(to: savedCheckpoint)
                        pendingHandle = accHandle
                        recovered = true

                    case .optional(let savedCheckpoint, _, let noneHandle):
                        input.seek(to: savedCheckpoint)
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
                let remaining = input.count

                switch instruction {
                case .take1:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        pendingHandle = arena.allocate(Value.make(advanceProvenInBounds(&input)))
                    }

                case .take(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        var bytes: [Byte] = []
                        bytes.reserveCapacity(n)
                        for _ in 0..<n { bytes.append(advanceProvenInBounds(&input)) }
                        pendingHandle = arena.allocate(Value.make(bytes))
                    }

                case .skip(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        input.advance(by: need)
                        pendingHandle = arena.allocate(Value.make(()))
                    }

                case .peek:
                    if input.isEmpty {
                        pendingHandle = arena.allocate(Value.make(Byte?.none))
                    } else {
                        let cp = input.checkpoint
                        let byte = advanceProvenInBounds(&input)
                        input.seek(to: cp)
                        pendingHandle = arena.allocate(Value.make(Byte?(byte)))
                    }

                case .byte(let expected):
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let cp = input.checkpoint
                        let byte = advanceProvenInBounds(&input)
                        if byte != expected {
                            input.seek(to: cp)
                            instructionError = .unexpectedByte(expected: expected, found: byte)
                        } else {
                            pendingHandle = arena.allocate(Value.make(byte))
                        }
                    }

                case .bytes(let expected):
                    let n = expected.count
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {

                        let cp = input.checkpoint
                        var found: [Byte] = []
                        found.reserveCapacity(n)
                        var mismatch = false

                        for expectedByte in expected {
                            let actual = advanceProvenInBounds(&input)
                            found.append(actual)
                            if actual != expectedByte { mismatch = true }
                        }

                        if mismatch {

                            input.seek(to: cp)
                            instructionError = .unexpectedBytes(expected: expected, found: found)
                        } else {

                            pendingHandle = arena.allocate(Value.make(expected))
                        }
                    }

                case .satisfy(let predicate):
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let cp = input.checkpoint
                        let byte = advanceProvenInBounds(&input)
                        if predicate(byte) {
                            pendingHandle = arena.allocate(Value.make(byte))
                        } else {
                            input.seek(to: cp)
                            instructionError = .predicateFailed(byte: byte)
                        }
                    }

                case .takeWhile(let predicate):
                    var bytes: [Byte] = []
                    while !input.isEmpty {
                        let cp = input.checkpoint
                        let byte = advanceProvenInBounds(&input)
                        guard predicate(byte) else {
                            input.seek(to: cp)
                            break
                        }
                        bytes.append(byte)
                    }
                    pendingHandle = arena.allocate(Value.make(bytes))

                case .skipWhile(let predicate):
                    while !input.isEmpty {
                        let cp = input.checkpoint
                        let byte = advanceProvenInBounds(&input)
                        if !predicate(byte) {
                            input.seek(to: cp)
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(()))

                case .end:
                    if !input.isEmpty {
                        instructionError = .expectedEnd(remaining: remaining)
                    } else {
                        pendingHandle = arena.allocate(Value.make(()))
                    }

                case .require(let n):
                    let need = Index<Byte>.Count(Cardinal(UInt(n)))
                    if remaining < need {
                        instructionError = .insufficientBytes(need: need, have: remaining)
                    } else {
                        pendingHandle = arena.allocate(Value.make(()))
                    }

                case .u8:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        let byte = advanceProvenInBounds(&input)
                        pendingHandle = arena.allocate(Value.make(byte.underlying))
                    }

                case .u16le:
                    if remaining < Index<Byte>.Count(Cardinal(2)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(2)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt16(advanceProvenInBounds(&input))
                        let b1 = UInt16(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8)))
                    }

                case .u16be:
                    if remaining < Index<Byte>.Count(Cardinal(2)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(2)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt16(advanceProvenInBounds(&input))
                        let b1 = UInt16(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(Value.make((b0 << 8) | b1))
                    }

                case .u32le:
                    if remaining < Index<Byte>.Count(Cardinal(4)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(4)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt32(advanceProvenInBounds(&input))
                        let b1 = UInt32(advanceProvenInBounds(&input))
                        let b2 = UInt32(advanceProvenInBounds(&input))
                        let b3 = UInt32(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
                        )
                    }

                case .u32be:
                    if remaining < Index<Byte>.Count(Cardinal(4)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(4)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt32(advanceProvenInBounds(&input))
                        let b1 = UInt32(advanceProvenInBounds(&input))
                        let b2 = UInt32(advanceProvenInBounds(&input))
                        let b3 = UInt32(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)
                        )
                    }

                case .u64le:
                    if remaining < Index<Byte>.Count(Cardinal(8)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(8)),
                            have: remaining
                        )
                    } else {
                        var result: UInt64 = 0
                        for i in 0..<8 {
                            result |= UInt64(advanceProvenInBounds(&input)) << (i * 8)
                        }
                        pendingHandle = arena.allocate(Value.make(result))
                    }

                case .u64be:
                    if remaining < Index<Byte>.Count(Cardinal(8)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(8)),
                            have: remaining
                        )
                    } else {
                        var result: UInt64 = 0
                        for _ in 0..<8 {
                            result = (result << 8) | UInt64(advanceProvenInBounds(&input))
                        }
                        pendingHandle = arena.allocate(Value.make(result))
                    }

                case .i8:
                    if remaining < .one {
                        instructionError = .insufficientBytes(need: .one, have: remaining)
                    } else {
                        pendingHandle = arena.allocate(
                            Value.make(Int8(bitPattern: advanceProvenInBounds(&input)))
                        )
                    }

                case .i16le:
                    if remaining < Index<Byte>.Count(Cardinal(2)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(2)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt16(advanceProvenInBounds(&input))
                        let b1 = UInt16(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make(Int16(bitPattern: b0 | (b1 << 8)))
                        )
                    }

                case .i16be:
                    if remaining < Index<Byte>.Count(Cardinal(2)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(2)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt16(advanceProvenInBounds(&input))
                        let b1 = UInt16(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make(Int16(bitPattern: (b0 << 8) | b1))
                        )
                    }

                case .i32le:
                    if remaining < Index<Byte>.Count(Cardinal(4)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(4)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt32(advanceProvenInBounds(&input))
                        let b1 = UInt32(advanceProvenInBounds(&input))
                        let b2 = UInt32(advanceProvenInBounds(&input))
                        let b3 = UInt32(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make(Int32(bitPattern: b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))
                        )
                    }

                case .i32be:
                    if remaining < Index<Byte>.Count(Cardinal(4)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(4)),
                            have: remaining
                        )
                    } else {
                        let b0 = UInt32(advanceProvenInBounds(&input))
                        let b1 = UInt32(advanceProvenInBounds(&input))
                        let b2 = UInt32(advanceProvenInBounds(&input))
                        let b3 = UInt32(advanceProvenInBounds(&input))
                        pendingHandle = arena.allocate(
                            Value.make(Int32(bitPattern: (b0 << 24) | (b1 << 16) | (b2 << 8) | b3))
                        )
                    }

                case .i64le:
                    if remaining < Index<Byte>.Count(Cardinal(8)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(8)),
                            have: remaining
                        )
                    } else {
                        var result: UInt64 = 0
                        for i in 0..<8 {
                            result |= UInt64(advanceProvenInBounds(&input)) << (i * 8)
                        }
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }

                case .i64be:
                    if remaining < Index<Byte>.Count(Cardinal(8)) {
                        instructionError = .insufficientBytes(
                            need: Index<Byte>.Count(Cardinal(8)),
                            have: remaining
                        )
                    } else {
                        var result: UInt64 = 0
                        for _ in 0..<8 {
                            result = (result << 8) | UInt64(advanceProvenInBounds(&input))
                        }
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }

                case .uleb128:

                    var result: UInt64 = 0
                    var shift: Int = 0
                    var done = false
                    do throws(Binary.LEB128.Error) {
                        while !done {
                            guard !input.isEmpty else {
                                instructionError = .insufficientBytes(need: .one, have: .zero)
                                break
                            }
                            let byte = advanceProvenInBounds(&input)
                            done = try Binary.LEB128.Decode.unsigned(
                                byte: byte.underlying,
                                into: &result,
                                shift: &shift
                            )
                        }
                        if done { pendingHandle = arena.allocate(Value.make(result)) }
                    } catch {
                        instructionError = .leb128Overflow
                    }

                case .sleb128:
                    var result: Int64 = 0
                    var shift: Int = 0
                    var done = false
                    do throws(Binary.LEB128.Error) {
                        while !done {
                            guard !input.isEmpty else {
                                instructionError = .insufficientBytes(need: .one, have: .zero)
                                break
                            }
                            let byte = advanceProvenInBounds(&input)
                            done = try Binary.LEB128.Decode.signed(
                                byte: byte.underlying,
                                into: &result,
                                shift: &shift
                            )
                        }
                        if done { pendingHandle = arena.allocate(Value.make(result)) }
                    } catch {
                        instructionError = .leb128Overflow
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
                    frames.append(
                        .oneOf(
                            alternatives: alternatives,
                            index: 1,
                            savedCheckpoint: input.checkpoint
                        )
                    )
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                frames.append(
                    .many(
                        child: child,
                        savedCheckpoint: input.checkpoint,
                        resultHandles: [],
                        finalize: finalize
                    )
                )
                current = child

            case .fold(let child, let initial, let combine):
                frames.append(
                    .fold(
                        child: child,
                        savedCheckpoint: input.checkpoint,
                        accumulatorHandle: arena.allocate(initial),
                        combine: combine
                    )
                )
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                frames.append(
                    .optional(
                        savedCheckpoint: input.checkpoint,
                        wrapSome: wrapSome,
                        noneHandle: arena.allocate(noneValue)
                    )
                )
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

extension Binary.Machine.Parser {

    @inlinable
    public func parse<Input: Input_Primitives.Input.`Protocol`>(
        _ input: inout Input
    ) throws(Binary.Machine.Fault) -> Output
    where Input.Element == Byte, Input.Checkpoint == Index<Byte> {
        try Binary.Machine.run(program: program, root: root, input: &input, as: Output.self)
    }
}
