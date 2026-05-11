// Binary.Parse.Converting.swift
// swift-binary-primitives
//
// Parser that reads one integer type and converts to another.

extension Binary.Parse {
    /// Parser that reads bytes as one integer type and converts to another.
    ///
    /// Useful when binary formats store values in a smaller type than the
    /// target representation (e.g., reading UInt32 from file into Int).
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse UInt32, convert to Int
    /// let parser = Binary.Parse.Converting<UInt32, Int>(endianness: .big)
    /// var input: ArraySlice<UInt8> = [0x00, 0x01, 0x00, 0x00][...]
    /// let value = try parser.parse(&input)
    /// // value: Int == 65536
    /// ```
    ///
    /// ## Overflow
    ///
    /// If the parsed value cannot be exactly represented in the target type,
    /// throws `Binary.Parse.Converting.Error.overflow`.
    public struct Converting<Source, Target>: Sendable
    where Source: FixedWidthInteger, Target: FixedWidthInteger {
        /// Byte order for parsing the source type.
        public let endianness: Binary.Endianness

        /// Creates a converting parser.
        ///
        /// - Parameter endianness: Byte order for parsing
        @inlinable
        public init(endianness: Binary.Endianness) {
            self.endianness = endianness
        }
    }
}

// MARK: - Error

extension Binary.Parse.Converting {
    /// Errors from type-converting parsing.
    public enum Error: Swift.Error {
        /// Input ended before required bytes were available.
        case endOfInput(expected: String)

        /// Parsed value cannot be exactly represented in target type.
        case overflow(source: Source)
    }
}

extension Binary.Parse.Converting.Error: Sendable where Source: Sendable {}

// MARK: - Parser.Parser

extension Binary.Parse.Converting: Parser.`Protocol` {
    public typealias Input = ArraySlice<UInt8>
    public typealias Output = Target
    public typealias Failure = Binary.Parse.Converting<Source, Target>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Target {
        let sourceSize = MemoryLayout<Source>.size
        guard input.count >= sourceSize else {
            throw .endOfInput(expected: "\(sourceSize) bytes for \(Source.self)")
        }

        let base = input.startIndex
        var sourceValue: Source = 0

        switch endianness {
        case .little:
            for i in 0..<sourceSize {
                sourceValue |= Source(truncatingIfNeeded: input[base + i]) << (i * 8)
            }
        case .big:
            for i in 0..<sourceSize {
                sourceValue |= Source(truncatingIfNeeded: input[base + i]) << ((sourceSize - 1 - i) * 8)
            }
        }

        input.removeFirst(sourceSize)

        guard let targetValue = Target(exactly: sourceValue) else {
            throw .overflow(source: sourceValue)
        }

        return targetValue
    }
}

// MARK: - Error Descriptions

extension Binary.Parse.Converting.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .endOfInput(let expected):
            return "End of input: expected \(expected)"
        case .overflow(let source):
            return "Value \(source) cannot be represented as \(Target.self)"
        }
    }
}
