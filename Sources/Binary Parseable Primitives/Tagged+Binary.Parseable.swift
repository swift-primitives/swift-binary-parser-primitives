// Tagged+Binary.Parseable.swift
// Binary.Parseable conformance for Tagged.

@_spi(Internal) import Tagged_Primitives

extension Tagged: Binary.Parseable where Underlying: Binary.Parseable {
    /// Parses a tagged value by parsing its underlying raw value.
    ///
    /// Delegates to the underlying type's parse implementation.
    public static func parse<Source: RangeReplaceableCollection>(
        from source: inout Source
    ) throws(Binary.Parse.Failure) -> Tagged<Tag, Underlying>
    where Source.Element == Byte {
        let underlying = try Underlying.parse(from: &source)
        return Tagged(underlying)
    }
}
