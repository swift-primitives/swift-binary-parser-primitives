public import Machine_Primitives
import Tagged_Primitives

extension Binary.Machine {

    public typealias Node = Machine_Primitives.Machine.Node<Instruction, Fault, Mode>
}
