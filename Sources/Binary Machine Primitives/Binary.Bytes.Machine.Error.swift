// Binary.Bytes.Machine.Error.swift
// Error types for machine execution

import Machine_Primitives
import Parser_Primitives
public import Index_Primitives

extension Binary.Bytes.Machine {
    /// Errors that can occur during machine execution.
    public enum Fault: Swift.Error, Sendable, Equatable {
        /// Not enough bytes in input.
        case insufficientBytes(need: Index<UInt8>.Count, have: Index<UInt8>.Count)

        /// Expected a specific byte but found different or end.
        case unexpectedByte(expected: UInt8, found: UInt8?)

        /// Expected a specific byte sequence but found mismatch.
        case unexpectedBytes(expected: [UInt8], found: [UInt8])

        /// Expected end of input but bytes remain.
        case expectedEnd(remaining: Index<UInt8>.Count)

        /// Byte did not satisfy predicate.
        case predicateFailed(byte: UInt8)

        /// Recursion depth exceeded.
        case depthExceeded(limit: Int)

        /// LEB128 decode overflow.
        case leb128Overflow

        /// No alternatives matched in oneOf.
        case noAlternativesMatched
    }
}

// MARK: - Error Bridging

extension Binary.Bytes.Machine.Fault {
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
            return .unexpected(expected: "\(Int(bitPattern: need.rawValue)) bytes for \(typeName), have \(Int(bitPattern: have.rawValue))")
        case .unexpectedByte(let expected, let found):
            let foundStr = found.map { "0x\(String($0, radix: 16))" } ?? "EOF"
            return .unexpected(expected: "byte 0x\(String(expected, radix: 16)) for \(typeName), found \(foundStr)")
        case .unexpectedBytes(let expected, _):
            return .unexpected(expected: "\(expected.count) byte sequence for \(typeName)")
        case .expectedEnd(let remaining):
            return .unexpected(expected: "end of input for \(typeName), \(Int(bitPattern: remaining.rawValue)) bytes remain")
        case .predicateFailed(let byte):
            return .unexpected(expected: "byte satisfying predicate for \(typeName), got 0x\(String(byte, radix: 16))")
        case .depthExceeded(let limit):
            return .unexpected(expected: "recursion within depth \(limit) for \(typeName)")
        case .leb128Overflow:
            return .unexpected(expected: "LEB128 value within bit width for \(typeName)")
        case .noAlternativesMatched:
            return .unexpected(expected: "one of alternatives to match for \(typeName)")
        }
    }
}
