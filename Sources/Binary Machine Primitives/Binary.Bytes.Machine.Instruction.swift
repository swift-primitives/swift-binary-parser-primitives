// Binary.Bytes.Machine.Instruction.swift
// Closed-world instruction set for byte parsing

import Machine_Primitives

extension Binary.Bytes.Machine {
    /// A byte parsing instruction that operates on `Input.View`.
    ///
    /// ## Closed World Design
    ///
    /// Instructions form a closed set of operations. The interpreter switches
    /// over this enum and manipulates `Input.View` directly. User code never
    /// receives the view - only the results.
    ///
    /// ## Allowed Extensibility
    ///
    /// - **Predicates on `UInt8`**: Predicates receive a single byte, not the view
    /// - **Transforms on outputs**: Via `map`/`tryMap` on `Value`
    @safe
    public enum Instruction {
        // MARK: - Cursor Operations

        /// Consume and return one byte. Fails if input is empty.
        case take1

        /// Consume exactly `n` bytes and return as `[UInt8]`.
        case take(Int)

        /// Consume and discard `n` bytes.
        case skip(Int)

        /// Return the next byte without consuming. Returns `nil` if empty.
        case peek

        // MARK: - Matching Operations

        /// Match a specific byte. Fails if mismatch or empty.
        case byte(UInt8)

        /// Match an exact byte sequence. Fails if mismatch or insufficient bytes.
        case bytes([UInt8])

        /// Consume one byte if it satisfies the predicate.
        case satisfy(@Sendable (UInt8) -> Bool)

        /// Consume bytes while predicate holds, return as `[UInt8]`.
        case takeWhile(@Sendable (UInt8) -> Bool)

        /// Skip bytes while predicate holds.
        case skipWhile(@Sendable (UInt8) -> Bool)

        // MARK: - Control Operations

        /// Succeed only if at end of input. Returns `Void`.
        case end

        /// Require at least `n` bytes remaining. Returns `Void`.
        case require(Int)

        // MARK: - Integer Decoding (Unsigned)

        case u8
        case u16le
        case u16be
        case u32le
        case u32be
        case u64le
        case u64be

        // MARK: - Integer Decoding (Signed)

        case i8
        case i16le
        case i16be
        case i32le
        case i32be
        case i64le
        case i64be

        // MARK: - Variable-Length Integers

        case uleb128
        case sleb128
    }
}

extension Binary.Bytes.Machine.Instruction: Sendable {}
