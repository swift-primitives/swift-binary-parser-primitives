// Binary.Bytes.Machine.Program.swift
// Program storage for machine nodes

public import Machine_Primitives
import Tagged_Primitives

extension Binary.Bytes.Machine {
    /// Program is a typealias to the core Machine.Program with Binary's Instruction type.
    public typealias Program = Machine_Primitives.Machine.Program<Instruction, Fault, Mode>
}
