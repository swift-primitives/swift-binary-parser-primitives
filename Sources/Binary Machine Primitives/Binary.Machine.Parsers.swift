// Binary.Machine.Parsers.swift
// Factory functions for pre-built Machine parsers

// MARK: - Integer Parser Factories

extension Binary.Machine {
    // MARK: Unsigned Integers

    /// Creates a parser for UInt8.
    @inlinable
    public static func u8Parser() -> Parser<UInt8> {
        build { u8(in: &$0) }
    }

    /// Creates a parser for UInt16 little-endian.
    @inlinable
    public static func u16leParser() -> Parser<UInt16> {
        build { u16le(in: &$0) }
    }

    /// Creates a parser for UInt16 big-endian.
    @inlinable
    public static func u16beParser() -> Parser<UInt16> {
        build { u16be(in: &$0) }
    }

    /// Creates a parser for UInt32 little-endian.
    @inlinable
    public static func u32leParser() -> Parser<UInt32> {
        build { u32le(in: &$0) }
    }

    /// Creates a parser for UInt32 big-endian.
    @inlinable
    public static func u32beParser() -> Parser<UInt32> {
        build { u32be(in: &$0) }
    }

    /// Creates a parser for UInt64 little-endian.
    @inlinable
    public static func u64leParser() -> Parser<UInt64> {
        build { u64le(in: &$0) }
    }

    /// Creates a parser for UInt64 big-endian.
    @inlinable
    public static func u64beParser() -> Parser<UInt64> {
        build { u64be(in: &$0) }
    }

    // MARK: Signed Integers

    /// Creates a parser for Int8.
    @inlinable
    public static func i8Parser() -> Parser<Int8> {
        build { i8(in: &$0) }
    }

    /// Creates a parser for Int16 little-endian.
    @inlinable
    public static func i16leParser() -> Parser<Int16> {
        build { i16le(in: &$0) }
    }

    /// Creates a parser for Int16 big-endian.
    @inlinable
    public static func i16beParser() -> Parser<Int16> {
        build { i16be(in: &$0) }
    }

    /// Creates a parser for Int32 little-endian.
    @inlinable
    public static func i32leParser() -> Parser<Int32> {
        build { i32le(in: &$0) }
    }

    /// Creates a parser for Int32 big-endian.
    @inlinable
    public static func i32beParser() -> Parser<Int32> {
        build { i32be(in: &$0) }
    }

    /// Creates a parser for Int64 little-endian.
    @inlinable
    public static func i64leParser() -> Parser<Int64> {
        build { i64le(in: &$0) }
    }

    /// Creates a parser for Int64 big-endian.
    @inlinable
    public static func i64beParser() -> Parser<Int64> {
        build { i64be(in: &$0) }
    }

    // MARK: Variable-Length Integers

    /// Creates a parser for unsigned LEB128 (returns UInt64).
    @inlinable
    public static func uleb128Parser() -> Parser<UInt64> {
        build { uleb128(in: &$0) }
    }

    /// Creates a parser for signed LEB128 (returns Int64).
    @inlinable
    public static func sleb128Parser() -> Parser<Int64> {
        build { sleb128(in: &$0) }
    }
}
