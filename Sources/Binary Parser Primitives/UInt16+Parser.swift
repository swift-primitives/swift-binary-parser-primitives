//
//  UInt16+Parser.swift
//  swift-binary-primitives
//
//  Binary coder for UInt16 serialization.
//

public import Input_Primitives

extension UInt16 {
    /// Returns a coder for reading/writing two bytes as `UInt16`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let coder = UInt16.coder(endianness: .little)
    ///
    /// // Decode
    /// let bytes: [UInt8] = [0x34, 0x12, 0x00]
    /// var input = Input.Slice(bytes[...])
    /// let value = try coder.decodePrefix(&input)
    /// // value == 0x1234, input has [0x00] remaining
    ///
    /// // Encode
    /// var output: [UInt8] = []
    /// coder.encodeAppending(0x1234, to: &output)
    /// // output == [0x34, 0x12] (little-endian)
    /// ```
    @inlinable
    public static func coder(endianness: Binary.Endianness) -> Binary.Coder<UInt16> {
        let parser: Binary.Bytes.Machine.Parser<UInt16> = switch endianness {
        case .little: Binary.Bytes.Machine.u16leParser()
        case .big: Binary.Bytes.Machine.u16beParser()
        }
        return Binary.Coder.machine(parser) { value, output in
            let bytes = value.bytes(endianness: endianness)
            output.append(contentsOf: bytes)
        }
    }
}
