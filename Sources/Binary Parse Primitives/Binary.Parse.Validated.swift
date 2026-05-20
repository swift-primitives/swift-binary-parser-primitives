// Binary.Parse.Validated.swift
// swift-binary-primitives
//
// Parser for RawRepresentable types with validation.

extension Binary.Parse {
    /// Parser for `RawRepresentable` types backed by `FixedWidthInteger`.
    ///
    /// Parses the raw value and validates that it maps to a valid case.
    /// Commonly used for parsing enums from binary data.
    ///
    /// ## Example
    ///
    /// ```swift
    /// enum Status: UInt8 {
    ///     case inactive = 0
    ///     case active = 1
    ///     case pending = 2
    /// }
    ///
    /// let parser = Binary.Parse.Validated<Status>(endianness: .big)
    /// var input: ArraySlice<Byte> = [0x01][...]
    /// let status = try parser.parse(&input)
    /// // status == .active
    ///
    /// var badInput: ArraySlice<Byte> = [0xFF][...]
    /// _ = try parser.parse(&badInput)
    /// // throws Error.invalid(rawValue: 255)
    /// ```
    public struct Validated<T>: Sendable
    where T: RawRepresentable, T.RawValue: FixedWidthInteger {
        /// Byte order for parsing the raw value.
        public let endianness: Binary.Endianness

        /// Creates a validated parser.
        ///
        /// - Parameter endianness: Byte order for parsing
        @inlinable
        public init(endianness: Binary.Endianness) {
            self.endianness = endianness
        }
    }
}

// MARK: - Error

extension Binary.Parse.Validated {
    /// Errors from validated RawRepresentable parsing.
    public enum Error: Swift.Error {
        /// Input ended before required bytes were available.
        case endOfInput(expected: String)

        /// Parsed raw value does not map to a valid case.
        case invalid(rawValue: T.RawValue)
    }
}

extension Binary.Parse.Validated.Error: Sendable where T.RawValue: Sendable {}

// MARK: - Parser.Parser

extension Binary.Parse.Validated: Parser.`Protocol` {
    public typealias Input = ArraySlice<Byte>
    public typealias Output = T
    public typealias Failure = Binary.Parse.Validated<T>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        let rawSize = MemoryLayout<T.RawValue>.size
        guard input.count >= rawSize else {
            throw .endOfInput(expected: "\(rawSize) bytes for \(T.RawValue.self)")
        }

        let base = input.startIndex
        var rawValue: T.RawValue = 0

        switch endianness {
        case .little:
            for i in 0..<rawSize {
                rawValue |= T.RawValue(truncatingIfNeeded: input[base + i].underlying) << (i * 8)
            }
        case .big:
            for i in 0..<rawSize {
                rawValue |= T.RawValue(truncatingIfNeeded: input[base + i].underlying) << ((rawSize - 1 - i) * 8)
            }
        }

        input.removeFirst(rawSize)

        guard let result = T(rawValue: rawValue) else {
            throw .invalid(rawValue: rawValue)
        }

        return result
    }
}

// MARK: - Error Descriptions

extension Binary.Parse.Validated.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .endOfInput(let expected):
            return "End of input: expected \(expected)"
        case .invalid(let rawValue):
            return "Invalid raw value \(rawValue) for \(T.self)"
        }
    }
}

// MARK: - Equatable

extension Binary.Parse.Validated.Error: Equatable where T.RawValue: Equatable {}
