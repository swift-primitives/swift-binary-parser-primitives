// Binary.Machine.Frame.swift
// Stack frame for machine interpreter

import Index_Primitives
public import Machine_Primitives

extension Binary.Machine {
    /// Checkpoint for backtracking - typed position index.
    public typealias Checkpoint = Index<Byte>

    /// Frame is a typealias to the core Machine.Frame with Binary's types.
    ///
    /// Binary uses `Never` for Extra since it has no memoization (the extra case is uninhabited).
    public typealias Frame = Machine_Primitives.Machine.Frame<Node.ID, Checkpoint, Mode, Fault, Never>
}
