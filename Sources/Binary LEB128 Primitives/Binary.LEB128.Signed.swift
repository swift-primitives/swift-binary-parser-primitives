// Binary.LEB128.Signed.swift
// swift-binary-primitives
//
// Parser for signed LEB128 encoded integers.

extension Binary.LEB128 {
    /// Parser for signed LEB128 encoded integers.
    ///
    /// Decodes a variable-length signed integer where:
    /// - Each byte contributes 7 bits of value
    /// - MSB=1 means more bytes follow
    /// - MSB=0 marks the final byte
    /// - Bit 6 of the final byte is sign-extended
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse negative Int64 from LEB128
    /// let parser = Binary.LEB128.Signed<Int64>()
    /// var input: ArraySlice<UInt8> = [0x7F][...]  // -1
    /// let value = try parser.parse(&input)
    /// // value == -1
    /// ```
    ///
    /// ## Sign Extension
    ///
    /// The sign bit (bit 6) of the final byte determines the sign:
    /// - If set (1), the remaining high bits are filled with 1s
    /// - If clear (0), the remaining high bits are filled with 0s
    public struct Signed<T: SignedInteger & FixedWidthInteger>: Sendable {
        @inlinable
        public init() {}
    }
}

// MARK: - Parser.Parser

extension Binary.LEB128.Signed: Parser.`Protocol` {
    public typealias Input = ArraySlice<UInt8>
    public typealias ParseOutput = T
    public typealias Failure = Binary.LEB128.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var shift: Int = 0
        var byte: UInt8 = 0

        while true {
            guard let nextByte = input.first else {
                throw .unterminated
            }
            input.removeFirst()
            byte = nextByte

            // Extract 7-bit payload
            let payload = T(truncatingIfNeeded: byte & 0x7F)

            // Check for overflow before shifting
            if shift >= T.bitWidth && payload != 0 && payload != 0x7F {
                throw .overflow(bitWidth: T.bitWidth)
            }

            if shift < T.bitWidth {
                result |= payload << shift
            }
            shift += 7

            // MSB=0 means final byte
            if byte & 0x80 == 0 {
                break
            }
        }

        // Sign extension: if bit 6 of final byte is set, extend sign
        if shift < T.bitWidth && (byte & 0x40) != 0 {
            // Fill remaining high bits with 1s
            result |= T(-1) << shift
        }

        return result
    }
}
