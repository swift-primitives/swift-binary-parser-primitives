// InlineArray+Binary.swift
// swift-binary-primitives
//
// InlineArray parsing support for fixed-size binary sequences.

extension InlineArray where Element: FixedWidthInteger {
    /// Initialize by parsing elements from binary input.
    ///
    /// Parses `count` elements of type `Element` from the input,
    /// where `count` is determined by the InlineArray's static size.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var input: ArraySlice<Byte> = [0x00, 0x01, 0x00, 0x02, 0x00, 0x03][...]
    /// let array = try InlineArray<3, UInt16>(parsing: &input, endianness: .big)
    /// // array == [1, 2, 3]
    /// ```
    ///
    /// - Parameters:
    ///   - input: The binary input to parse from.
    ///   - endianness: Byte order for parsing each element.
    /// - Throws: `Parser.EndOfInput.Error` if insufficient bytes remain.
    @inlinable
    public init(
        parsing input: inout ArraySlice<Byte>,
        endianness: Binary.Endianness
    ) throws(Parser.EndOfInput.Error) {
        self = Self(repeating: 0)
        let elementSize = MemoryLayout<Element>.size

        for i in indices {
            guard input.count >= elementSize else {
                throw .unexpected(expected: "\(elementSize) bytes for \(Element.self)")
            }

            let base = input.startIndex
            var value: Element = 0

            switch endianness {
            case .little:
                for j in 0..<elementSize {
                    value |= Element(truncatingIfNeeded: input[base + j].underlying) << (j * 8)
                }
            case .big:
                for j in 0..<elementSize {
                    value |= Element(truncatingIfNeeded: input[base + j].underlying) << ((elementSize - 1 - j) * 8)
                }
            }

            input.removeFirst(elementSize)
            self[i] = value
        }
    }
}
