public import Byte_Primitives
import Machine_Primitives

extension Binary.Machine {

    @safe
    public enum Instruction {

        case take1

        case take(Int)

        case skip(Int)

        case peek

        case byte(Byte)

        case bytes([Byte])

        case satisfy((Byte) -> Bool)

        case takeWhile((Byte) -> Bool)

        case skipWhile((Byte) -> Bool)

        case end

        case require(Int)

        case u8
        case u16le
        case u16be
        case u32le
        case u32be
        case u64le
        case u64be

        case i8
        case i16le
        case i16be
        case i32le
        case i32be
        case i64le
        case i64be

        case uleb128
        case sleb128
    }
}
