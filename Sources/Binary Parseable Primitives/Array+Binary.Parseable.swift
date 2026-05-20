// Array+Binary.Parseable.swift
// Binary.Parseable conformance for Array<Byte>.

extension Array: Binary.Parseable where Element == Byte {
    /// Parses a byte array by consuming all remaining bytes in the source.
    ///
    /// There is no internal length prefix in the wire format — the conformance
    /// is "the rest is mine." Conformers wanting length-prefixed semantics
    /// build that at a higher layer.
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> [Byte]
    where Source.Element == Byte {
        let bytes = Array(source)
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
