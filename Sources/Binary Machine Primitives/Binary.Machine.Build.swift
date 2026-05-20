// Binary.Machine.Build.swift
// Entry points for building machine programs

public import Machine_Primitives

extension Binary.Machine {
    /// The final parser type that can be executed on borrowed byte views.
    ///
    /// ## Error Type
    ///
    /// The machine uses a fixed error type `Machine.Fault` for all failures.
    /// This enables the interpreter to be inlined into `withBorrowed` without
    /// generic error type parameters that would prevent proper lifetime analysis.
    public struct Parser<Output> {
        public let program: Program

        public let root: Node.ID

        @usableFromInline
        init(program: Program, root: Node.ID) {
            self.program = program
            self.root = root
        }
    }

    /// Creates a non-recursive parser from a builder closure.
    @inlinable
    public static func build<Output>(
        _ build: (inout Builder) -> Expression<Output>
    ) -> Parser<Output> {
        var builder = Builder()
        let root = build(&builder)
        return Parser(program: builder.build(), root: root.node)
    }

    /// Creates a recursive parser.
    @inlinable
    public static func recursive<Output>(
        maxDepth: Int? = nil,
        _ build: (inout Builder, Reference<Output>) -> Expression<Output>
    ) -> Parser<Output> {
        var builder = Builder(maxDepth: maxDepth)

        // Allocate a hole for the recursive reference
        let holeID = builder.allocate(.hole)
        let ref = Reference<Output>(node: holeID)

        // Build the grammar
        let root = build(&builder, ref)

        // Patch the hole to point to the actual root
        builder.inner[holeID] = .ref(root.node)

        return Parser(program: builder.build(), root: root.node)
    }
}

// MARK: - Reference Expression

// `Binary.Machine.Parser` is intentionally NOT Sendable. With
// `Mode.Unchecked` non-Sendable and `Instruction` non-Sendable per
// [MEM-SEND-013] Pattern B (post-Phase-B), consumers transport assembled
// parsers via `sending` at the boundary rather than via structural
// Sendable conformance.

extension Binary.Machine.Reference {
    /// Creates an expression from this reference, for use in recursive definitions.
    @inlinable
    public func expression(
        in builder: inout Binary.Machine.Builder
    ) -> Binary.Machine.Expression<Output> {
        let node = Binary.Machine.Node.ref(self.node)
        let nodeID = builder.allocate(node)
        return Binary.Machine.Expression(node: nodeID)
    }
}
