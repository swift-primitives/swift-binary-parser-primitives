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
    /// var input: ArraySlice<Byte> = [0xE5, 0x8E, 0x26][...]
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
    public typealias Input = ArraySlice<Byte>
    public typealias Output = T
    public typealias Failure = Binary.LEB128.Error
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var shift: Int = 0
        while true {
            guard let byte = input.first else {
                throw .unterminated
            }
            input.removeFirst()
            // Delegate to the shared decode core (Binary LEB128 Decode Primitives).
            // Bridge Byte -> UInt8 once at this unpacking boundary per [API-BYTE-004].
            if try Binary.LEB128.Decode.unsigned(byte: byte.underlying, into: &result, shift: &shift) {
                return result
            }
        }
    }
}
