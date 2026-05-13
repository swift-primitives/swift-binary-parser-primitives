// Binary.Bytes.Machine.Node.swift
// IR node representing a parsing operation

public import Machine_Primitives
import Tagged_Primitives

extension Binary.Bytes.Machine {
    /// Node is a typealias to the core Machine.Node with Binary's Instruction type.
    public typealias Node = Machine_Primitives.Machine.Node<Instruction, Fault, Mode>
}
