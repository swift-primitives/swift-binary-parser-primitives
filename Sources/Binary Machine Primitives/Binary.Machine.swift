public import Machine_Primitives

extension Binary {

    public enum Machine {}
}

extension Binary.Machine {

    public typealias Value = Machine_Primitives.Machine.Value<Mode>

    public typealias Transform = Machine_Primitives.Machine.Transform

    public typealias Combine = Machine_Primitives.Machine.Combine

    public typealias Finalize = Machine_Primitives.Machine.Finalize

    public typealias Next = Machine_Primitives.Machine.Next
}
