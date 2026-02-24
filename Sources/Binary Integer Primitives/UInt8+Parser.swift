//
//  UInt8+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for UInt8 serialization.
//

import Input_Primitives

extension UInt8 {
    /// Returns a coder for reading/writing a single byte as `UInt8`.
    ///
    /// Although endianness is irrelevant for single-byte values, the parameter
    /// is accepted for API consistency with multi-byte integer coders.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = UInt8.coder(endianness: .big)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0x42, 0x00]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == 0x42, input has [0x00] remaining
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(0x42, to: &output)
    /// // output == [0x42]
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<UInt8> {
        Binary.Coder.machine(
            Binary.Bytes.Machine.u8Parser(),
            encode: { value, output in
                output.append(value)
            }
        )
    }
}
