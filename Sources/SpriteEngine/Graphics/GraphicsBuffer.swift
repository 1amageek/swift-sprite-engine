/// A GPU buffer for storing vertex, index, or uniform data.
///
/// ## Platform Mapping
/// ```
/// Metal                          WebGPU
/// ─────────────────────────────  ─────────────────────────────
/// MTLBuffer                      GPUBuffer
/// buffer.contents()              buffer.getMappedRange()
/// buffer.length                  buffer.size
/// ```
///
/// ## Usage
/// ```swift
/// // Create a vertex buffer
/// let vertices: [CGFloat] = [0, 0.5, 0, -0.5, -0.5, 0, 0.5, -0.5, 0]
/// let buffer = device.makeBuffer(floats: vertices, usage: .vertex)
///
/// // Use in render pass
/// renderPass.setVertexBuffer(buffer, offset: 0, index: 0)
/// ```
public protocol GraphicsBuffer: AnyObject, Sendable {
    /// The size of the buffer in bytes.
    ///
    /// - Metal: `buffer.length`
    /// - WebGPU: `buffer.size`
    var length: Int { get }

    /// A label for debugging.
    var label: String? { get set }

    /// The usage flags for this buffer.
    var usage: BufferUsage { get }

    /// Updates the buffer contents.
    ///
    /// - Parameters:
    ///   - data: The data to write.
    ///   - offset: Byte offset in the buffer.
    ///
    /// - Note: For WebGPU, this requires the buffer to have `mapWrite` usage
    ///         or uses `queue.writeBuffer()` internally.
    func write(_ data: [UInt8], offset: Int)

    /// Maps the buffer for reading.
    ///
    /// - Parameter range: The range to map (offset and size).
    /// - Returns: The mapped data, or nil if mapping fails.
    ///
    /// - Note: For WebGPU, this is async. Metal can map synchronously.
    func mapRead(range: BufferRange) -> [UInt8]?
}

// MARK: - Default Implementations

extension GraphicsBuffer {
    /// Writes data at offset 0.
    public func write(_ data: [UInt8]) {
        write(data, offset: 0)
    }

    /// Maps the entire buffer for reading.
    public func mapRead() -> [UInt8]? {
        mapRead(range: BufferRange(offset: 0, size: length))
    }
}

// MARK: - Buffer Range

/// A range within a buffer.
public struct BufferRange: Sendable {
    /// The byte offset.
    public var offset: Int

    /// The size in bytes.
    public var size: Int

    public init(offset: Int, size: Int) {
        self.offset = offset
        self.size = size
    }
}
