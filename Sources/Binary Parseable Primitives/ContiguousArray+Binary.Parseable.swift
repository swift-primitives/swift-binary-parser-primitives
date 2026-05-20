// ContiguousArray+Binary.Parseable.swift
// Binary.Parseable conformance for ContiguousArray<Byte>.

extension ContiguousArray: Binary.Parseable where Element == Byte {
    /// Parses a contiguous byte array by consuming all remaining bytes in the source.
    ///
    /// There is no internal length prefix in the wire format — the conformance
    /// is "the rest is mine." Conformers wanting length-prefixed semantics
    /// build that at a higher layer.
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> ContiguousArray<Byte>
    where Source.Element == Byte {
        let bytes = ContiguousArray(source)
        source.removeAll(keepingCapacity: false)
        return bytes
    }
}
