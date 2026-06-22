// Binary.Parse.Overflow.swift
// swift-binary-parser-primitives
//
// Overflow parse fault.
//
// Re-homed from swift-binary-primitives' `Binary.Error.Overflow`.

extension Binary.Parse {
    /// An arithmetic operation would overflow.
    ///
    /// Thrown when index arithmetic (addition or subtraction) would
    /// overflow the scalar type's representable range.
    public struct Overflow: Swift.Error, Sendable, Equatable {
        /// The kind of operation that overflowed.
        public let operation: Operation

        /// The field being computed.
        public let field: Field

        public init(operation: Operation, field: Field) {
            self.operation = operation
            self.field = field
        }
    }
}

// MARK: - Operation

extension Binary.Parse.Overflow {
    /// The kind of arithmetic operation.
    public enum Operation: Sendable, Equatable {
        /// Addition overflowed.
        case addition

        /// Subtraction underflowed.
        case subtraction

        /// Conversion from a wider type.
        case conversion
    }
}

// MARK: - Field

extension Binary.Parse.Overflow {
    /// The field being computed.
    public enum Field: Sendable, Equatable {
        /// Reader index computation.
        case reader

        /// Writer index computation.
        case writer

        /// Count computation.
        case count
    }
}

// MARK: - CustomStringConvertible

extension Binary.Parse.Overflow: CustomStringConvertible {
    public var description: String {
        "\(field) \(operation) overflow"
    }
}

extension Binary.Parse.Overflow.Operation: CustomStringConvertible {
    public var description: String {
        switch self {
        case .addition: return "addition"
        case .subtraction: return "subtraction"
        case .conversion: return "conversion"
        }
    }
}

extension Binary.Parse.Overflow.Field: CustomStringConvertible {
    public var description: String {
        switch self {
        case .reader: return "readerIndex"
        case .writer: return "writerIndex"
        case .count: return "count"
        }
    }
}
