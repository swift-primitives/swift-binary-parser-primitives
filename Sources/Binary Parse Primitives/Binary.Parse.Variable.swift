extension Binary.Parse {

    public struct Variable<T: FixedWidthInteger>: Sendable {

        public let count: Int

        public let endianness: Binary.Endianness

        @inlinable
        public init(count: Int, endianness: Binary.Endianness) {
            precondition(
                count > 0 && count <= MemoryLayout<T>.size,
                "count must be between 1 and \(MemoryLayout<T>.size)"
            )
            self.count = count
            self.endianness = endianness
        }
    }
}

extension Binary.Parse.Variable: Parser.`Protocol` {

    public typealias Input = ArraySlice<Byte>

    public typealias Output = T

    public typealias Failure = Parser.EndOfInput.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        guard input.count >= count else {
            throw .unexpected(expected: "\(count) bytes for variable-width integer")
        }

        let base = input.startIndex
        var result: T = 0

        switch endianness {
        case .little:

            (0..<count).forEach { i in
                result |= T(truncatingIfNeeded: input[base + i].underlying) << (i * 8)
            }

            if T.isSigned {

                let signBit = (input[base + count - 1] & 0x80) != 0
                if signBit {

                    let shift = count * 8
                    if shift < T.bitWidth {
                        result |= ~T(0) << shift
                    }
                }
            }

        case .big:

            (0..<count).forEach { i in

                result |= T(truncatingIfNeeded: input[base + i].underlying) << ((count - 1 - i) * 8)
            }

            if T.isSigned {
                let signBit = (input[base] & 0x80) != 0
                if signBit {

                    let shift = count * 8
                    if shift < T.bitWidth {
                        result |= ~T(0) << shift
                    }
                }
            }
        }

        input.removeFirst(count)
        return result
    }
}
