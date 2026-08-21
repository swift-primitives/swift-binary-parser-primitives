extension Binary.Parse {

    public struct Validated<T>: Sendable
    where T: RawRepresentable, T.RawValue: FixedWidthInteger {

        public let endianness: Binary.Endianness

        @inlinable
        public init(endianness: Binary.Endianness) {
            self.endianness = endianness
        }
    }
}

extension Binary.Parse.Validated {

    public enum Error: Swift.Error {

        case endOfInput(expected: String)

        case invalid(rawValue: T.RawValue)
    }
}

extension Binary.Parse.Validated.Error: Sendable where T.RawValue: Sendable {}

extension Binary.Parse.Validated: Parser.`Protocol` {

    public typealias Input = ArraySlice<Byte>

    public typealias Output = T

    public typealias Failure = Binary.Parse.Validated<T>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        let rawSize = MemoryLayout<T.RawValue>.size
        guard input.count >= rawSize else {
            throw .endOfInput(expected: "\(rawSize) bytes for \(T.RawValue.self)")
        }

        let base = input.startIndex
        var rawValue: T.RawValue = 0

        switch endianness {
        case .little:
            (0..<rawSize).forEach { i in
                rawValue |= T.RawValue(truncatingIfNeeded: input[base + i].underlying) << (i * 8)
            }

        case .big:
            (0..<rawSize).forEach { i in
                rawValue |=
                    T.RawValue(truncatingIfNeeded: input[base + i].underlying)
                    << ((rawSize - 1 - i) * 8)
            }
        }

        input.removeFirst(rawSize)

        guard let result = T(rawValue: rawValue) else {
            throw .invalid(rawValue: rawValue)
        }

        return result
    }
}

extension Binary.Parse.Validated.Error: CustomStringConvertible {

    public var description: String {
        switch self {
        case .endOfInput(let expected):
            return "End of input: expected \(expected)"

        case .invalid(let rawValue):
            return "Invalid raw value \(rawValue) for \(T.self)"
        }
    }
}

extension Binary.Parse.Validated.Error: Equatable where T.RawValue: Equatable {}
