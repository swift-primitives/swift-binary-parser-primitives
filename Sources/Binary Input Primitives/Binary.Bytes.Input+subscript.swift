public import Index_Primitives

extension Binary.Bytes.Input {
    /// Accesses the byte at the given offset from the current position.
    ///
    /// - Parameter offset: The offset from the current position (0-indexed).
    /// - Precondition: `offset >= 0` and `offset < count`.
    /// - Returns: The byte at the given offset.
    @inlinable
    public subscript(offset offset: Index<UInt8>.Offset) -> UInt8 {
        let offsetInt = Int(bitPattern: offset)
        precondition(offsetInt >= 0 && offsetInt < Int(bitPattern: count), "offset out of bounds")
        return storage[Int(bitPattern: position) + offsetInt]
    }

    /// Checks if the remaining bytes start with the given prefix.
    ///
    /// - Parameter prefix: The prefix to check.
    /// - Returns: `true` if the remaining bytes start with the prefix.
    @inlinable
    public func starts<Prefix: Swift.Collection>(with prefix: Prefix) -> Bool
    where Prefix.Element == UInt8 {
        guard prefix.count <= Int(bitPattern: count) else { return false }
        var idx = Int(bitPattern: position)
        for byte in prefix {
            if storage[idx] != byte { return false }
            idx += 1
        }
        return true
    }
}
