//
//  Int8+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for Int8 serialization.
//

import Input_Primitives

extension Int8 {
    /// Returns a coder for reading/writing a single byte as `Int8`.
    ///
    /// Although endianness is irrelevant for single-byte values, the parameter
    /// is accepted for API consistency with multi-byte integer coders.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = Int8.coder(endianness: .big)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0xFF, 0x00]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == -1, input has [0x00] remaining
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(-1, to: &output)
    /// // output == [0xFF]
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<Int8> {
        Binary.Coder.machine(
            Binary.Bytes.Machine.i8Parser(),
            encode: { value, output in
                output.append(UInt8(bitPattern: value))
            }
        )
    }
}
