//
//  Int16+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for Int16 serialization.
//

import Input_Primitives

extension Int16 {
    /// Returns a coder for reading/writing two bytes as `Int16`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = Int16.coder(endianness: .big)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0xFF, 0xFE, 0x00]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == -2, input has [0x00] remaining
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(-2, to: &output)
    /// // output == [0xFF, 0xFE] (big-endian)
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<Int16> {
        let parser: Binary.Bytes.Machine.Parser<Int16> =
            switch endianness {
            case .little: Binary.Bytes.Machine.i16leParser()
            case .big: Binary.Bytes.Machine.i16beParser()
            }
        return Binary.Coder.machine(parser) { value, output in
            let bytes = value.bytes(endianness: endianness)
            output.append(contentsOf: bytes)
        }
    }
}
