// Binary.Machine.Builder.swift
// Builder context for constructing machine programs

public import Machine_Primitives
public import Vector_Primitives

extension Binary.Machine {
    /// The capture mode used by Binary.Machine programs.
    ///
    /// Uses `Mode.Unchecked` per [MEM-SEND-013] Pattern B (terminal direction):
    /// combinator factories accept non-Sendable predicate/transform closures,
    /// and the resulting `Parser<Output>` is itself non-Sendable. Consumers
    /// transport assembled parsers across isolation domains via `sending` at
    /// the program-transport boundary — not via a structural Sendable
    /// conformance on the assembled value.
    public typealias Mode = Machine_Primitives.Machine.Capture.Mode.Unchecked

    /// A builder context for constructing machine programs.
    public struct Builder: ~Copyable {
        @usableFromInline
        var inner: Machine_Primitives.Machine.Builder<Instruction, Fault, Mode>

        @usableFromInline
        init(maxDepth: Int? = nil) {
            self.inner = Machine_Primitives.Machine.Builder(maxDepth: maxDepth)
        }

        @usableFromInline
        mutating func allocate(_ node: Node) -> Node.ID {
            inner.allocate(node)
        }

        /// Access to the capture store for registering closures.
        @usableFromInline
        var captures: Machine_Primitives.Machine.Capture.Store<Mode> {
            get { inner.captures }
            _modify { yield &inner.captures }
        }

        /// Builds the final immutable program.
        @usableFromInline
        consuming func build() -> Program {
            inner.build()
        }

        /// Embeds an existing parser's program into this builder.
        ///
        /// Copies all nodes from the source parser, adjusting IDs to fit
        /// in this builder's program. Returns an expression pointing to
        /// the copied root node.
        ///
        /// Use this to compose existing parsers into new ones:
        /// ```swift
        /// let combined = Machine.build { builder in
        ///     let inner = builder.embed(existingParser)
        ///     let end = Combinators.end(in: &builder)
        ///     return Combinators.sequence(inner, end, combine: { v, _ in v }, in: &builder)
        /// }
        /// ```
        @inlinable
        public mutating func embed<Output>(_ parser: Parser<Output>) -> Expression<Output> {
            let offset = inner.count
            for node in parser.program.graph.nodes {
                _ = inner.allocate(parser.program.graph[node])
            }
            let adjustedRoot = parser.root + offset
            return Expression(node: adjustedRoot)
        }
    }

    /// An expression in the machine program, representing a parser that produces Output.
    public struct Expression<Output> {
        @usableFromInline
        let node: Node.ID

        @usableFromInline
        init(node: Node.ID) {
            self.node = node
        }
    }

    /// A reference to a node in the program, used for recursive grammar definitions.
    public struct Reference<Output> {
        @usableFromInline
        let node: Node.ID

        @usableFromInline
        init(node: Node.ID) {
            self.node = node
        }
    }
}
