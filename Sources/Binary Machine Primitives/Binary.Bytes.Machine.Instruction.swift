// Binary.Bytes.Machine.Instruction.swift
// Closed-world instruction set for byte parsing

public import Byte_Primitives
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
    /// - **Predicates on `Byte`**: Predicates receive a single byte, not the view
    /// - **Transforms on outputs**: Via `map`/`tryMap` on `Value`
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types; `@safe` documents that this type performs no
    // SAFETY: unsafe operations.
    @safe
    public enum Instruction {
        // MARK: - Cursor Operations

        /// Consume and return one byte. Fails if input is empty.
        case take1

        /// Consume exactly `n` bytes and return as `[Byte]`.
        case take(Int)

        /// Consume and discard `n` bytes.
        case skip(Int)

        /// Return the next byte without consuming. Returns `nil` if empty.
        case peek

        // MARK: - Matching Operations

        /// Match a specific byte. Fails if mismatch or empty.
        case byte(Byte)

        /// Match an exact byte sequence. Fails if mismatch or insufficient bytes.
        case bytes([Byte])

        /// Consume one byte if it satisfies the predicate.
        case satisfy((Byte) -> Bool)

        /// Consume bytes while predicate holds, return as `[Byte]`.
        case takeWhile((Byte) -> Bool)

        /// Skip bytes while predicate holds.
        case skipWhile((Byte) -> Bool)

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

// `Binary.Bytes.Machine.Instruction` is intentionally NOT Sendable: predicate
// closures on `.satisfy`, `.takeWhile`, `.skipWhile` are not constrained
// `@Sendable` per [MEM-SEND-013] Pattern B. Consumers transport assembled
// `Program`/`Parser` values across isolation domains via `sending` at the
// program-transport boundary, not via a structural Sendable conformance.
