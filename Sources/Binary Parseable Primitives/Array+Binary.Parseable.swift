// Array+Binary.Parseable.swift
// Binary.Parseable conformance for Array<Byte>.

public import Binary_Parse_Primitives
public import Cardinal_Primitives
public import Index_Primitives

extension Swift.Array: Binary.Parseable where Element == Byte {
    /// Parses a byte array by consuming all remaining bytes in the source.
    ///
    /// There is no internal length prefix in the wire format — the conformance
    /// is "the rest is mine." Conformers wanting length-prefixed semantics
    /// build that at a higher layer.
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Self
    where Source.Element == Byte {
        var bytes = Self()
        // `Source.count` returns stdlib `Int` from `Collection.count`; the W2
        // byte cascade retyped `Array<Byte>.reserveCapacity` to take
        // `Index<Byte>.Count` but hasn't (yet) typed `Collection<Byte>.count`.
        // Bridge via the canonical `Index<Byte>.Count(Cardinal(UInt(_)))` form
        // used elsewhere (Binary.parse.swift, Binary.Machine.Run.swift).
        // Fully-qualify `Index_Primitives.Index` because the bare `Index` name
        // inside `extension Array` resolves to Array's own nested `Index`
        // typealias.
        bytes.reserveCapacity(
            Index_Primitives.Index<Byte>.Count(Cardinal(UInt(source.count)))
        )
        for byte in source {
            bytes.append(byte)
        }
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
