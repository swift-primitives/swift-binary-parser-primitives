public import Byte_Primitives
public import Index_Primitives
import Machine_Primitives
import Parser_Primitives

extension Binary.Machine {

    public enum Fault: Swift.Error, Sendable, Equatable {

        case insufficientBytes(need: Index<Byte>.Count, have: Index<Byte>.Count)

        case unexpectedByte(expected: Byte, found: Byte?)

        case unexpectedBytes(expected: [Byte], found: [Byte])

        case expectedEnd(remaining: Index<Byte>.Count)

        case predicateFailed(byte: Byte)

        case depthExceeded(limit: Int)

        case leb128Overflow

        case noAlternativesMatched

        case malformed

        case outOfRange
    }
}

extension Binary.Machine.Fault {

    @inlinable
    public func asEndOfInputError(for typeName: String) -> Parser.EndOfInput.Error {
        switch self {
        case .insufficientBytes(let need, let have):
            return .unexpected(
                expected:
                    "\(Int(bitPattern: need)) bytes for \(typeName), have \(Int(bitPattern: have))"
            )

        case .unexpectedByte(let expected, let found):
            let foundStr = found.map { "0x\(String($0.underlying, radix: 16))" } ?? "EOF"
            return .unexpected(
                expected:
                    "byte 0x\(String(expected.underlying, radix: 16)) for \(typeName), found \(foundStr)"
            )

        case .unexpectedBytes(let expected, _):
            return .unexpected(expected: "\(expected.count) byte sequence for \(typeName)")

        case .expectedEnd(let remaining):
            return .unexpected(
                expected: "end of input for \(typeName), \(Int(bitPattern: remaining)) bytes remain"
            )

        case .predicateFailed(let byte):
            return .unexpected(
                expected:
                    "byte satisfying predicate for \(typeName), got 0x\(String(byte.underlying, radix: 16))"
            )

        case .depthExceeded(let limit):
            return .unexpected(expected: "recursion within depth \(limit) for \(typeName)")

        case .leb128Overflow:
            return .unexpected(expected: "LEB128 value within bit width for \(typeName)")

        case .noAlternativesMatched:
            return .unexpected(expected: "one of alternatives to match for \(typeName)")

        case .malformed:
            return .unexpected(expected: "well-formed bytes for \(typeName)")

        case .outOfRange:
            return .unexpected(expected: "in-range raw value for \(typeName)")
        }
    }
}
