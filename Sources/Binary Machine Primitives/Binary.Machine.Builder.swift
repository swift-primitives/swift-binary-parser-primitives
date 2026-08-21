public import Machine_Primitives
public import Vector_Primitives

extension Binary.Machine {

    public typealias Mode = Machine_Primitives.Machine.Capture.Mode.Unchecked

    public struct Builder: ~Copyable {
        @usableFromInline
        var inner: Machine_Primitives.Machine.Builder<Instruction, Fault, Mode>

        @usableFromInline
        init(maxDepth: Int? = nil) {
            self.inner = Machine_Primitives.Machine.Builder(maxDepth: maxDepth)
        }
    }

    public struct Expression<Output> {
        @usableFromInline
        let node: Node.ID

        @usableFromInline
        init(node: Node.ID) {
            self.node = node
        }
    }

    public struct Reference<Output> {
        @usableFromInline
        let node: Node.ID

        @usableFromInline
        init(node: Node.ID) {
            self.node = node
        }
    }
}

extension Binary.Machine.Builder {
    @usableFromInline
    mutating func allocate(_ node: Binary.Machine.Node) -> Binary.Machine.Node.ID {
        inner.allocate(node)
    }

    @usableFromInline
    var captures: Machine_Primitives.Machine.Capture.Store<Binary.Machine.Mode> {
        get { inner.captures }
        _modify { yield &inner.captures }
    }

    @usableFromInline
    consuming func build() -> Binary.Machine.Program {
        inner.build()
    }

    @inlinable
    public mutating func embed<Output>(
        _ parser: Binary.Machine.Parser<Output>
    ) -> Binary.Machine.Expression<Output> {
        let offset = inner.count
        for node in parser.program.graph.nodes {
            _ = inner.allocate(parser.program.graph[node])
        }
        let adjustedRoot = parser.root + offset
        return Binary.Machine.Expression(node: adjustedRoot)
    }
}
