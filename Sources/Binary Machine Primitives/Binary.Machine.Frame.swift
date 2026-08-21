import Index_Primitives
public import Machine_Primitives

extension Binary.Machine {

    public typealias Checkpoint = Index<Byte>

    public typealias Frame = Machine_Primitives.Machine.Frame<
        Node.ID, Checkpoint, Mode, Fault, Never
    >
}
