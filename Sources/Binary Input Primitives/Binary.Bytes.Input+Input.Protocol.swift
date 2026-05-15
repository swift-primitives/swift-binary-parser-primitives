//
//  Binary.Bytes.Input+Input.Protocol.swift
//  swift-binary-primitives
//
//  Conformance of Binary.Bytes.Input to Input.Protocol for parsing integration.
//

public import Input_Primitives

extension Binary.Bytes.Input: Input_Primitives.Input.`Protocol` {
    public typealias Element = UInt8
    public typealias Checkpoint = Index<UInt8>

    /// The current position as a checkpoint for backtracking.
    @inlinable
    public var checkpoint: Checkpoint {
        position
    }

    /// The range of valid checkpoints (start to end of input).
    @inlinable
    public var checkpointRange: ClosedRange<Checkpoint> {
        .zero...totalCount.map(Ordinal.init)
    }

    /// Sets the input position to a previously saved checkpoint.
    ///
    /// - Parameter checkpoint: A checkpoint obtained from `checkpoint`.
    /// - Precondition: The checkpoint was created from this input instance
    ///   and is within valid bounds.
    @inlinable
    public mutating func setPosition(to checkpoint: Checkpoint) {
        precondition(
            checkpoint <= totalCount.map(Ordinal.init),
            "Invalid checkpoint: out of bounds"
        )
        position = checkpoint
    }
}

// MARK: - Random Access

extension Binary.Bytes.Input: Input.Access.Random {}
