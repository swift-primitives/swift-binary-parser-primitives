// Binary.Bytes.Machine.Frame.swift
// Stack frame for machine interpreter

public import Machine_Primitives
import Index_Primitives

extension Binary.Bytes.Machine {
    /// Checkpoint for backtracking - typed position index.
    public typealias Checkpoint = Index<UInt8>

    /// Frame is a typealias to the core Machine.Frame with Binary's types.
    ///
    /// Binary uses `Never` for Extra since it has no memoization (the extra case is uninhabited).
    public typealias Frame = Machine_Primitives.Machine.Frame<Node.ID, Checkpoint, Machine_Primitives.Machine.Capture.Mode.Reference, Fault, Never>
}
