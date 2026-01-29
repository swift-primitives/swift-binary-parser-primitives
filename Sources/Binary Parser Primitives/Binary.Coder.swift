//
//  Binary.Coder.swift
//  swift-binary-primitives
//
//  Witness-based bidirectional coder with separate decode/encode types.
//
//  Parsing input and printing output are different algebraic operations:
//  - Decoding: streaming + checkpoint/restore (Binary.Bytes.Input)
//  - Encoding: mutable, insertable buffer ([UInt8])
//
//  This witness separates these concerns cleanly.
//

extension Binary {
    /// A witness for bidirectional binary coding with separate input/output types.
    ///
    /// Unlike `Parser.ParserPrinter` which requires the same `Input` type for both
    /// directions, `Coder` uses the appropriate type for each operation:
    /// - Decoding from `Binary.Bytes.Input` (read-only cursor)
    /// - Encoding into `[UInt8]` (mutable buffer)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = Binary.Coder<UInt16>(
    ///     decode: { input in
    ///         let lo = try! input.advance()
    ///         let hi = try! input.advance()
    ///         return UInt16(hi) << 8 | UInt16(lo)
    ///     },
    ///     encode: { value, output in
    ///         output.append(UInt8(truncatingIfNeeded: value))
    ///         output.append(UInt8(truncatingIfNeeded: value >> 8))
    ///     }
    /// )
    ///
    /// let bytes: [UInt8] = [0x34, 0x12]
    /// let value = try coder.decodeWhole(bytes)  // 0x1234
    /// let encoded = coder.encodeToArray(value)  // [0x34, 0x12]
    /// ```
    public struct Coder<Output>: Sendable {
        /// Decodes a value from a read-only byte cursor.
        public var decode: @Sendable (inout Binary.Bytes.Input) throws(Binary.Bytes.Machine.Fault) -> Output

        /// Encodes a value into a mutable byte buffer.
        public var encode: @Sendable (Output, inout [UInt8]) -> Void

        /// Creates a coder with the given decode and encode operations.
        @inlinable
        public init(
            decode: @escaping @Sendable (inout Binary.Bytes.Input) throws(Binary.Bytes.Machine.Fault) -> Output,
            encode: @escaping @Sendable (Output, inout [UInt8]) -> Void
        ) {
            self.decode = decode
            self.encode = encode
        }
    }
}

// MARK: - Execution Helpers

extension Binary.Coder {
    /// Decodes a value from a complete byte array, requiring all bytes consumed.
    ///
    /// - Parameter bytes: The bytes to decode.
    /// - Returns: The decoded value.
    /// - Throws: `Binary.Bytes.Machine.Fault` if decoding fails or bytes remain.
    @inlinable
    public func decodeWhole(_ bytes: [UInt8]) throws(Binary.Bytes.Machine.Fault) -> Output {
        var input = Binary.Bytes.Input(bytes)
        let value = try decode(&input)
        guard input.isEmpty else {
            throw .expectedEnd(remaining: input.count)
        }
        return value
    }

    /// Decodes a value from a byte input, consuming only what's needed.
    ///
    /// - Parameter input: The byte cursor to decode from.
    /// - Returns: The decoded value.
    /// - Throws: `Binary.Bytes.Machine.Fault` if decoding fails.
    @inlinable
    public func decodePrefix(_ input: inout Binary.Bytes.Input) throws(Binary.Bytes.Machine.Fault) -> Output {
        try decode(&input)
    }

    /// Encodes a value to a new byte array.
    ///
    /// - Parameter value: The value to encode.
    /// - Returns: The encoded bytes.
    @inlinable
    public func encodeToArray(_ value: Output) -> [UInt8] {
        var out: [UInt8] = []
        encode(value, &out)
        return out
    }

    /// Encodes a value by appending to an existing byte buffer.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - buffer: The buffer to append to.
    @inlinable
    public func encodeAppending(_ value: Output, to buffer: inout [UInt8]) {
        encode(value, &buffer)
    }
}

// MARK: - Machine Integration

extension Binary.Coder {
    /// Creates a coder from a Machine parser and an encode function.
    ///
    /// - Parameters:
    ///   - parser: The Machine parser for decoding.
    ///   - encode: The encode function.
    /// - Returns: A coder wrapping the parser.
    @inlinable
    public static func machine(
        _ parser: Binary.Bytes.Machine.Parser<Output>,
        encode: @escaping @Sendable (Output, inout [UInt8]) -> Void
    ) -> Self {
        Self(
            decode: { input throws(Binary.Bytes.Machine.Fault) in
                try parser.parse(&input)
            },
            encode: encode
        )
    }
}
