// Binary.Parser.swift
// swift-binary-parser-primitives
//
// Plain witness for binary parsing — the canonical institute Parser witness
// for the binary domain. Mirrors `Binary.Coder<Output>`'s shape and intent:
// a closure-based struct that conforms to the canonical `Parser.Protocol`.
//
// `Binary.Parser<Value>` coexists with `Binary.Machine.Parser<Output>`:
// - `Binary.Parser<Value>` — institute canonical witness for `Parseable`
//   conformers; binds `Input = Byte.Input`, `Failure = Binary.Machine.Fault`.
// - `Binary.Machine.Parser<Output>` — borrowed-Span machine specialization
//   parameterized over `Input: Input_Primitives.Input.Protocol`.
//
// Consumers conforming to the canonical `Parseable` (from
// `swift-parser-primitives`) declare `static var parser: Binary.Parser<Self>`.

public import Byte_Parser_Primitives

extension Binary {
    /// A witness for binary parsing as a closure-based plain witness.
    ///
    /// `Binary.Parser<Value>` is the canonical institute witness for
    /// `Parseable` conformance in the binary domain. It conforms to
    /// ``Parser/Protocol`` with `Input = Byte.Input`, `Output = Value`, and
    /// `Failure = Binary.Machine.Fault`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = Binary.Parser<UInt16> { input in
    ///     let lo = try input.removeFirst()
    ///     let hi = try input.removeFirst()
    ///     return UInt16(hi.underlying) << 8 | UInt16(lo.underlying)
    /// }
    ///
    /// var input = Byte.Input([0x34, 0x12])
    /// let value = try parser.parse(&input)  // 0x1234
    /// ```
    ///
    /// ## Composition with `Binary.Machine.Parser`
    ///
    /// Use ``machine(_:)`` to wrap an existing `Binary.Machine.Parser<Value>`:
    ///
    /// ```swift
    /// let machineParser = Binary.Machine.build { ... }
    /// let canonical = Binary.Parser.machine(machineParser)
    /// ```
    public struct Parser<Value> {
        @usableFromInline
        let _parse: (inout Byte.Input) throws(Binary.Machine.Fault) -> Value

        /// Creates a parser with the given parse closure.
        ///
        /// - Parameter parse: A closure that consumes bytes from the input and
        ///   produces a `Value`, throwing `Binary.Machine.Fault` on failure.
        @inlinable
        public init(
            parse: @escaping (inout Byte.Input) throws(Binary.Machine.Fault) -> Value
        ) {
            self._parse = parse
        }
    }
}

// MARK: - Execution Helpers

extension Binary.Parser {
    /// Parses a value from a complete byte array, requiring all bytes consumed.
    ///
    /// - Parameter bytes: The bytes to parse.
    /// - Returns: The parsed value.
    /// - Throws: `Binary.Machine.Fault` if parsing fails or bytes remain.
    @inlinable
    public func parseWhole(_ bytes: [Byte]) throws(Binary.Machine.Fault) -> Value {
        var input = Byte.Input(bytes)
        let value = try _parse(&input)
        let remaining = input.count
        guard remaining == .zero else {
            throw .expectedEnd(remaining: remaining)
        }
        return value
    }

    /// Parses a value from a byte input, consuming only what's needed.
    ///
    /// - Parameter input: The byte cursor to parse from.
    /// - Returns: The parsed value.
    /// - Throws: `Binary.Machine.Fault` if parsing fails.
    @inlinable
    public func parsePrefix(_ input: inout Byte.Input) throws(Binary.Machine.Fault) -> Value {
        try _parse(&input)
    }
}

// MARK: - Machine Integration

extension Binary.Parser {
    /// Creates a parser by wrapping an existing `Binary.Machine.Parser`.
    ///
    /// - Parameter machineParser: The Machine parser to delegate to.
    /// - Returns: A `Binary.Parser` whose parse closure invokes the Machine parser.
    @inlinable
    public static func machine(_ machineParser: Binary.Machine.Parser<Value>) -> Self {
        Self { input throws(Binary.Machine.Fault) in
            try machineParser.parse(&input)
        }
    }
}
