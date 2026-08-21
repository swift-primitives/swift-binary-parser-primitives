public import Machine_Primitives

extension Binary.Machine {

    public struct Parser<Output> {

        public let program: Program

        public let root: Node.ID

        @usableFromInline
        init(program: Program, root: Node.ID) {
            self.program = program
            self.root = root
        }
    }

    @inlinable
    public static func build<Output>(
        _ build: (inout Builder) -> Expression<Output>
    ) -> Parser<Output> {
        var builder = Builder()
        let root = build(&builder)
        return Parser(program: builder.build(), root: root.node)
    }

    @inlinable
    public static func recursive<Output>(
        maxDepth: Int? = nil,
        _ build: (inout Builder, Reference<Output>) -> Expression<Output>
    ) -> Parser<Output> {
        var builder = Builder(maxDepth: maxDepth)

        let holeID = builder.allocate(.hole)
        let ref = Reference<Output>(node: holeID)

        let root = build(&builder, ref)

        builder.inner[holeID] = .ref(root.node)

        return Parser(program: builder.build(), root: root.node)
    }
}

extension Binary.Machine.Reference {

    @inlinable
    public func expression(
        in builder: inout Binary.Machine.Builder
    ) -> Binary.Machine.Expression<Output> {
        let node = Binary.Machine.Node.ref(self.node)
        let nodeID = builder.allocate(node)
        return Binary.Machine.Expression(node: nodeID)
    }
}
