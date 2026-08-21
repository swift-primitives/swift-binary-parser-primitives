public import Machine_Primitives
import Tagged_Primitives

extension Binary.Machine {

    public typealias Program = Machine_Primitives.Machine.Program<Instruction, Fault, Mode>
}
