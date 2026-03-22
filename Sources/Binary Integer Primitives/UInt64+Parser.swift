//
//  UInt64+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for UInt64 serialization.
//

internal import Input_Primitives

extension UInt64 {
    /// Returns a coder for reading/writing eight bytes as `UInt64`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = UInt64.coder(endianness: .little)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0xEF, 0xCD, 0xAB, 0x90, 0x78, 0x56, 0x34, 0x12]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == 0x1234567890ABCDEF
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(0x1234567890ABCDEF, to: &output)
    /// // output == [0xEF, 0xCD, 0xAB, 0x90, 0x78, 0x56, 0x34, 0x12] (little-endian)
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<UInt64> {
        let parser: Binary.Bytes.Machine.Parser<UInt64> = switch endianness {
        case .little: Binary.Bytes.Machine.u64leParser()
        case .big: Binary.Bytes.Machine.u64beParser()
        }
        return Binary.Coder.machine(parser) { value, output in
            let bytes = value.bytes(endianness: endianness)
            output.append(contentsOf: bytes)
        }
    }
}
