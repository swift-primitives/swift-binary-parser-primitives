public import Binary_Parse_Primitives

extension Binary.Parse {

    public enum Failure: Swift.Error, Sendable, Equatable {

        case insufficient(needed: Int)

        case malformed

        case outOfRange
    }
}
