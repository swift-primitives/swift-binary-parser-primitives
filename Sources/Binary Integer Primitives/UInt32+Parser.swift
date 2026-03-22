//
//  UInt32+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for UInt32 serialization.
//

internal import Input_Primitives

extension UInt32 {
    /// Returns a coder for reading/writing four bytes as `UInt32`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = UInt32.coder(endianness: .little)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0x78, 0x56, 0x34, 0x12]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == 0x12345678
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(0x12345678, to: &output)
    /// // output == [0x78, 0x56, 0x34, 0x12] (little-endian)
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<UInt32> {
        let parser: Binary.Bytes.Machine.Parser<UInt32> = switch endianness {
        case .little: Binary.Bytes.Machine.u32leParser()
        case .big: Binary.Bytes.Machine.u32beParser()
        }
        return Binary.Coder.machine(parser) { value, output in
            let bytes = value.bytes(endianness: endianness)
            output.append(contentsOf: bytes)
        }
    }
}
