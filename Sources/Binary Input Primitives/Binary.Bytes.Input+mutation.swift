public import Input_Primitives

extension Binary.Bytes.Input {
    /// Consumes and returns the first byte.
    ///
    /// - Returns: The first byte.
    /// - Throws: ``Input.Stream.Error.empty`` if the input is empty.
    @inlinable
    @discardableResult
    public mutating func advance() throws(Input.Stream.Error) -> UInt8 {
        guard position < totalCount else {
            throw .empty
        }
        let byte = storage[Int(bitPattern: position)]
        position += .one
        return byte
    }

    /// Advances by `count` bytes.
    ///
    /// - Parameter count: The number of bytes to skip.
    /// - Precondition: `count <= self.count`.
    @inlinable
    public mutating func advance(by count: Index<UInt8>.Count) {
        position += count
    }
}
