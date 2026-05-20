// Binary.Machine.Error.swift
// Error types for machine execution

public import Byte_Primitives
public import Index_Primitives
import Machine_Primitives
import Parser_Primitives

extension Binary.Machine {
    /// Errors that can occur during machine execution.
    public enum Fault: Swift.Error, Sendable, Equatable {
        /// Not enough bytes in input.
        case insufficientBytes(need: Index<Byte>.Count, have: Index<Byte>.Count)

        /// Expected a specific byte but found different or end.
        case unexpectedByte(expected: Byte, found: Byte?)

        /// Expected a specific byte sequence but found mismatch.
        case unexpectedBytes(expected: [Byte], found: [Byte])

        /// Expected end of input but bytes remain.
        case expectedEnd(remaining: Index<Byte>.Count)

        /// Byte did not satisfy predicate.
        case predicateFailed(byte: Byte)

        /// Recursion depth exceeded.
        case depthExceeded(limit: Int)

        /// LEB128 decode overflow.
        case leb128Overflow

        /// No alternatives matched in oneOf.
        case noAlternativesMatched

        /// Source bytes were structurally malformed for the target type.
        ///
        /// Ported from `Binary.Parse.Failure.malformed` during the
        /// Binary.Serializable / Binary.Parseable → canonical witness
        /// migration so consumer parse logic can express the same
        /// semantic precision under the new `Binary.Parser<Value>` shape.
        case malformed

        /// Parsed raw value did not initialize a valid instance of the
        /// target type.
        ///
        /// Ported from `Binary.Parse.Failure.outOfRange` during the
        /// migration. Use this when bytes decode successfully into a
        /// raw value (e.g., a UInt8) but `Self(rawValue:)` returns nil.
        case outOfRange
    }
}

// MARK: - Error Bridging

extension Binary.Machine.Fault {
    /// Converts this fault to a `Parser.EndOfInput.Error` with preserved specificity.
    ///
    /// Used by ad-hoc ParserPrinter types that delegate parsing to Machine but
    /// need to maintain their original error type for API compatibility.
    ///
    /// - Parameter typeName: The name of the type being parsed (e.g., "UInt16").
    /// - Returns: An `EndOfInput.Error` with a descriptive message.
    @inlinable
    public func asEndOfInputError(for typeName: String) -> Parser.EndOfInput.Error {
        switch self {
        case .insufficientBytes(let need, let have):
            return .unexpected(expected: "\(Int(bitPattern: need)) bytes for \(typeName), have \(Int(bitPattern: have))")
        case .unexpectedByte(let expected, let found):
            let foundStr = found.map { "0x\(String($0.underlying, radix: 16))" } ?? "EOF"
            return .unexpected(expected: "byte 0x\(String(expected.underlying, radix: 16)) for \(typeName), found \(foundStr)")
        case .unexpectedBytes(let expected, _):
            return .unexpected(expected: "\(expected.count) byte sequence for \(typeName)")
        case .expectedEnd(let remaining):
            return .unexpected(expected: "end of input for \(typeName), \(Int(bitPattern: remaining)) bytes remain")
        case .predicateFailed(let byte):
            return .unexpected(expected: "byte satisfying predicate for \(typeName), got 0x\(String(byte.underlying, radix: 16))")
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
