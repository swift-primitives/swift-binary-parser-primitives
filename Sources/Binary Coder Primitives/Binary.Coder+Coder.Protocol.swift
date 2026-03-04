//
//  Binary.Coder+Coder.Protocol.swift
//  swift-binary-parser-primitives
//
//  Conforms Binary.Coder to Coder.Protocol.
//

public import Coder_Primitives

extension Binary.Coder: Coder.`Protocol` {
    public typealias DecodeInput = Binary.Bytes.Input
    public typealias EncodeBuffer = [UInt8]
    public typealias DecodeFailure = Binary.Bytes.Machine.Fault
    public typealias EncodeFailure = Never

    @inlinable
    public func decode(_ input: inout Binary.Bytes.Input) throws(Binary.Bytes.Machine.Fault) -> Output {
        try self.decode(&input)
    }

    @inlinable
    public func encode(_ output: Output, into buffer: inout [UInt8]) {
        self.encode(output, &buffer)
    }
}
