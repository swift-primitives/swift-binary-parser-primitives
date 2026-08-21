public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives
public import Byte_Parser_Primitives
public import Ownership_Shared_Primitive

extension Binary {

    public struct Parser<Value> {
        @usableFromInline
        let _parse: (inout Byte.Input) throws(Binary.Machine.Fault) -> Value

        @inlinable
        public init(
            parse: @escaping (inout Byte.Input) throws(Binary.Machine.Fault) -> Value
        ) {
            self._parse = parse
        }
    }
}

extension Binary.Parser {

    @inlinable
    public func parseWhole(_ bytes: [Byte]) throws(Binary.Machine.Fault) -> Value {
        var input = Byte.Input(bytes)
        let value = try _parse(&input)
        let remaining = input.count
        guard remaining == .zero else {
            throw .expectedEnd(remaining: remaining)
        }
        return value
    }

    @inlinable
    public func parsePrefix(_ input: inout Byte.Input) throws(Binary.Machine.Fault) -> Value {
        try _parse(&input)
    }
}

extension Binary.Parser {

    @inlinable
    public static func machine(_ machineParser: Binary.Machine.Parser<Value>) -> Self {
        Self { input throws(Binary.Machine.Fault) in
            try machineParser.parse(&input)
        }
    }
}
