extension InlineArray where Element: FixedWidthInteger {

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
                (0..<elementSize).forEach { j in
                    value |= Element(truncatingIfNeeded: input[base + j].underlying) << (j * 8)
                }

            case .big:
                (0..<elementSize).forEach { j in
                    value |=
                        Element(truncatingIfNeeded: input[base + j].underlying)
                        << ((elementSize - 1 - j) * 8)
                }
            }

            input.removeFirst(elementSize)
            self[i] = value
        }
    }
}
