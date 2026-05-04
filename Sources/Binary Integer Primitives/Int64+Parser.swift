//
//  Int64+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for Int64 serialization.
//

import Input_Primitives

extension Int64 {
    /// Returns a coder for reading/writing eight bytes as `Int64`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = Int64.coder(endianness: .big)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == -2
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(-2, to: &output)
    /// // output == [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE] (big-endian)
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<Int64> {
        let parser: Binary.Bytes.Machine.Parser<Int64> =
            switch endianness {
            case .little: Binary.Bytes.Machine.i64leParser()
            case .big: Binary.Bytes.Machine.i64beParser()
            }
        return Binary.Coder.machine(parser) { value, output in
            let bytes = value.bytes(endianness: endianness)
            output.append(contentsOf: bytes)
        }
    }
}
