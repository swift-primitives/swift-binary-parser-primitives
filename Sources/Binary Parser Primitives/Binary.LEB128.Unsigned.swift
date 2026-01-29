// Binary.LEB128.Unsigned.swift
// swift-binary-primitives
//
// Parser for unsigned LEB128 encoded integers.

extension Binary.LEB128 {
    /// Parser for unsigned LEB128 encoded integers.
    ///
    /// Decodes a variable-length unsigned integer where:
    /// - Each byte contributes 7 bits of value
    /// - MSB=1 means more bytes follow
    /// - MSB=0 marks the final byte
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse UInt64 from LEB128
    /// let parser = Binary.LEB128.Unsigned<UInt64>()
    /// var input: ArraySlice<UInt8> = [0xE5, 0x8E, 0x26][...]
    /// let value = try parser.parse(&input)
    /// // value == 624485
    /// ```
    ///
    /// ## Overflow Behavior
    ///
    /// If the encoded value exceeds the target type's bit width,
    /// throws `Binary.LEB128.Error.overflow`.
    public struct Unsigned<T: UnsignedInteger & FixedWidthInteger>: Sendable {
        @inlinable
        public init() {}
    }
}

// MARK: - Parser.Parser

extension Binary.LEB128.Unsigned: Parser.`Protocol` {
    public typealias Input = ArraySlice<UInt8>
    public typealias Output = T
    public typealias Failure = Binary.LEB128.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var shift: Int = 0

        while true {
            guard let byte = input.first else {
                throw .unterminated
            }
            input.removeFirst()

            // Extract 7-bit payload
            let payload = T(byte & 0x7F)

            // Check for overflow before shifting
            if shift >= T.bitWidth {
                // Any non-zero payload at this point overflows
                if payload != 0 {
                    throw .overflow(bitWidth: T.bitWidth)
                }
            } else if shift > 0 {
                // Check if payload would overflow when shifted
                let maxPayload = T.max >> shift
                if payload > maxPayload {
                    throw .overflow(bitWidth: T.bitWidth)
                }
            }

            result |= payload << shift
            shift += 7

            // MSB=0 means final byte
            if byte & 0x80 == 0 {
                return result
            }
        }
    }
}
