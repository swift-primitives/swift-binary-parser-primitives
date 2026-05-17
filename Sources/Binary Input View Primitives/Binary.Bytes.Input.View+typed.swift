public import Index_Primitives
public import Byte_Primitives
public import Cursor_Span_Primitives
public import Cursor_Primitives_Core

// MARK: - Typed Subscript

extension Cursor.Span where DomainTag == Byte {
    /// Accesses the byte at the given typed index offset from the current position.
    ///
    /// This subscript encapsulates the Int conversion at the API boundary,
    /// enabling fully typed interpreter code.
    ///
    /// - Parameter index: The typed `Index<UInt8>` offset from the current position.
    /// - Precondition: `index` must be within bounds.
    /// - Returns: The byte at the given offset.
    @inlinable
    @_lifetime(copy self)
    public subscript(offset index: Index<UInt8>) -> UInt8 {
        self[offset: Int(bitPattern: index)]
    }
}
