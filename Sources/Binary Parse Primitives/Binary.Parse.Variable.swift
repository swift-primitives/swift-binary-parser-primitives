// Binary.Parse.Variable.swift
// swift-binary-primitives
//
// Parser for variable byte-count integers.

extension Binary.Parse {
    /// Parser for integers with arbitrary byte count.
    ///
    /// Parses `count` bytes into a `FixedWidthInteger` with sign extension
    /// (for signed types) or zero extension (for unsigned types) when
    /// `count` is less than the target type's byte width.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse 3 bytes as Int32 (sign-extended)
    /// let parser = Binary.Parse.Variable<Int32>(count: 3, endianness: .big)
    /// var input: ArraySlice<UInt8> = [0xFF, 0x12, 0x34][...]
    /// let value = try parser.parse(&input)
    /// // value == -60876 (sign-extended from 24-bit)
    /// ```
    ///
    /// ## Sign Extension
    ///
    /// For signed types, if the high bit of the parsed bytes is set,
    /// the remaining high bits of the result are filled with 1s.
    ///
    /// ## Validation
    ///
    /// - `count` must be > 0 and <= type's byte width
    /// - Input must have at least `count` bytes available
    public struct Variable<T: FixedWidthInteger>: Sendable {
        /// Number of bytes to parse.
        public let count: Int

        /// Byte order for multi-byte parsing.
        public let endianness: Binary.Endianness

        /// Creates a variable byte-count parser.
        ///
        /// - Parameters:
        ///   - count: Number of bytes to parse (must be > 0 and <= T's byte width)
        ///   - endianness: Byte order for parsing
        @inlinable
        public init(count: Int, endianness: Binary.Endianness) {
            precondition(
                count > 0 && count <= MemoryLayout<T>.size,
                "count must be between 1 and \(MemoryLayout<T>.size)"
            )
            self.count = count
            self.endianness = endianness
        }
    }
}

// MARK: - Parser.Parser

extension Binary.Parse.Variable: Parser.`Protocol` {
    public typealias Input = ArraySlice<UInt8>
    public typealias Output = T
    public typealias Failure = Parser.EndOfInput.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        guard input.count >= count else {
            throw .unexpected(expected: "\(count) bytes for variable-width integer")
        }

        let base = input.startIndex
        var result: T = 0

        switch endianness {
        case .little:
            // Little-endian: first byte is least significant
            for i in 0..<count {
                result |= T(truncatingIfNeeded: input[base + i]) << (i * 8)
            }
            // Sign extension for signed types
            if T.isSigned {
                // reason: Last index of `base + count` slice in stdlib `[UInt8]`
                // ByteIterator; `count: Int` is a struct API parameter (1 ≤ count
                // ≤ MemoryLayout<T>.size, validated at line 47), not a typed
                // Cardinal; no typed surface available at this byte-access site.
                // The math is the canonical "last index = base + count − 1"
                // expression for variable-width integer parsing.
                // swiftlint:disable:next cardinal_count_minus_one_anti_pattern
                let signBit = (input[base + count - 1] & 0x80) != 0
                if signBit {
                    // Fill high bits with 1s
                    let shift = count * 8
                    if shift < T.bitWidth {
                        result |= ~T(0) << shift
                    }
                }
            }

        case .big:
            // Big-endian: first byte is most significant
            for i in 0..<count {
                // reason: Big-endian shift amount for byte i of count-byte
                // integer: byte i contributes to bits at positions
                // (count − 1 − i) × 8. `count: Int` is a stdlib struct property,
                // no typed surface. The math IS the (count − 1 − i) form;
                // operand-reorder rephrase obscures the bit-position derivation.
                // swiftlint:disable:next cardinal_count_minus_one_anti_pattern
                result |= T(truncatingIfNeeded: input[base + i]) << ((count - 1 - i) * 8)
            }
            // Sign extension for signed types
            if T.isSigned {
                let signBit = (input[base] & 0x80) != 0
                if signBit {
                    // Fill high bits with 1s
                    let shift = count * 8
                    if shift < T.bitWidth {
                        result |= ~T(0) << shift
                    }
                }
            }
        }

        input.removeFirst(count)
        return result
    }
}
