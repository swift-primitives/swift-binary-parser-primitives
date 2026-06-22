// Binary.Parse.Fault.swift
// swift-binary-parser-primitives
//
// Aggregate structured fault for bounded / variable-length parsing.
//
// Re-homed from swift-binary-primitives' `Binary.Error` taxonomy: those
// cases describe bounded / variable-length PARSE failures (reader / writer /
// count index arithmetic), not the fixed-width integer↔bytes CODEC failures
// that remain in binary-primitives. The parser package owns the parse-fault
// vocabulary, so this is its home.
//
// Named `Fault` (not `Error`) for two reasons:
//   1. `Binary.Parse.Error` already exists in this target as a concrete
//      whole-buffer post-condition enum (`.end(remaining:)`); reusing that
//      name would collide.
//   2. It matches the existing `Binary.Machine.Fault` aggregate already in
//      this package — one consistent "structured parse fault" naming.
//
// Complements the other parser-side errors rather than replacing them:
//   - `Binary.Parse.Error`   — whole-buffer post-condition (`.end(remaining:)`)
//   - `Binary.Parse.Failure` — during-parse leaf for `Binary.Parseable`
//   - `Binary.Parse.Fault`   — structured index / bounds / bit / overflow faults

extension Binary.Parse {
    /// A structured fault from bounded or variable-length parsing.
    ///
    /// Uses typed throws (`throws(Binary.Parse.Fault)`) to provide compile-time
    /// exhaustiveness checking when handling parse faults.
    ///
    /// ## Fault Categories
    ///
    /// - `negative`: A value that must be non-negative was negative.
    /// - `bounds`: An index or position was out of valid range.
    /// - `invariant`: A required invariant was violated.
    /// - `bit`: A bit operation parameter was invalid.
    /// - `overflow`: An arithmetic operation would overflow.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     try someThrowingOp()
    /// } catch .negative(let e) {
    ///     print("\(e.field) was \(e.value)")
    /// }
    /// ```
    public enum Fault: Swift.Error, Sendable, Equatable {
        /// A value that must be non-negative was negative.
        case negative(Negative)

        /// An index or position was out of valid range.
        case bounds(Bounds)

        /// A required invariant was violated.
        case invariant(Invariant)

        /// A bit operation parameter was invalid.
        case bit(Bit)

        /// An arithmetic operation would overflow.
        case overflow(Overflow)
    }
}

// MARK: - CustomStringConvertible

extension Binary.Parse.Fault: CustomStringConvertible {
    public var description: String {
        switch self {
        case .negative(let e): return e.description
        case .bounds(let e): return e.description
        case .invariant(let e): return e.description
        case .bit(let e): return e.description
        case .overflow(let e): return e.description
        }
    }
}
