public import Byte_Primitives
public import Index_Primitives

extension Binary.Parse {

    public enum Error: Swift.Error, Sendable, Equatable {

        case end(remaining: Index<Byte>.Count)
    }
}
