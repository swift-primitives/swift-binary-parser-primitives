// Binary.Machine.swift
// Defunctionalized parsing machine for borrowed byte views

public import Machine_Primitives

extension Binary {
    /// Defunctionalized parsing machine for borrowed byte views.
    ///
    /// ## Design Rationale
    ///
    /// This machine exists because `Input.View` is `~Escapable`, meaning it cannot
    /// be passed to closure parameters or protocol witnesses. The machine solves
    /// this by representing parsers as data (instruction programs) rather than
    /// callable code.
    ///
    /// ## Closed World Constraint
    ///
    /// The input cursor (`Input.View`) never crosses an opaque callable boundary.
    /// All cursor manipulation happens inside the interpreter's `switch` over
    /// instructions. User extensibility is available on:
    /// - **Outputs**: via `map`, `tryMap`, `combine`
    /// - **Byte predicates**: via predicates on `UInt8` (not on `Input.View`)
    ///
    /// ## Two Canonical Worlds
    ///
    /// | World | Input Type | Machine | Leaf Representation |
    /// |-------|-----------|---------|---------------------|
    /// | **Owned** | `Byte.Input` | `Parser.Machine` | Closure `(inout Input) -> Value` |
    /// | **Borrowed** | `Cursor<Byte>` | `Binary.Machine` | `Instruction` enum |
    ///
    /// ## Invariant
    ///
    /// Machine closures (transforms, combines) operate on `Value` only and must
    /// not capture input-bound or lifetime-dependent data.
    public enum Machine {}
}

// MARK: - Core Type Aliases

extension Binary.Machine {
    /// Type-erased value container from Machine Primitives.
    public typealias Value = Machine_Primitives.Machine.Value<Mode>

    /// Transform operations from Machine Primitives.
    public typealias Transform = Machine_Primitives.Machine.Transform

    /// Combine operations from Machine Primitives.
    public typealias Combine = Machine_Primitives.Machine.Combine

    /// Finalize operations from Machine Primitives.
    public typealias Finalize = Machine_Primitives.Machine.Finalize

    /// Next-node selection for flatMap from Machine Primitives.
    public typealias Next = Machine_Primitives.Machine.Next
}
