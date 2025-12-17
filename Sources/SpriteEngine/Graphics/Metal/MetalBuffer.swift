#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsBuffer.
public final class MetalBuffer: GraphicsBuffer, @unchecked Sendable {
    // MARK: - Properties

    /// The underlying Metal buffer.
    public let mtlBuffer: MTLBuffer

    /// The buffer length in bytes.
    public var length: Int { mtlBuffer.length }

    /// A label for debugging.
    public var label: String? {
        get { mtlBuffer.label }
        set { mtlBuffer.label = newValue }
    }

    /// The usage flags.
    public let usage: BufferUsage

    // MARK: - Initialization

    /// Creates a Metal buffer wrapper.
    ///
    /// - Parameters:
    ///   - buffer: The Metal buffer.
    ///   - usage: The buffer usage flags.
    init(buffer: MTLBuffer, usage: BufferUsage) {
        self.mtlBuffer = buffer
        self.usage = usage
    }

    // MARK: - Data Access

    public func write(_ data: [UInt8], offset: Int) {
        guard offset + data.count <= length else {
            return
        }

        let pointer = mtlBuffer.contents().advanced(by: offset)
        _ = data.withUnsafeBytes { bytes in
            memcpy(pointer, bytes.baseAddress, data.count)
        }

        #if os(macOS)
        // Notify Metal of the modified range on macOS with managed storage
        if mtlBuffer.storageMode == .managed {
            mtlBuffer.didModifyRange(offset..<(offset + data.count))
        }
        #endif
    }

    public func mapRead(range: BufferRange) -> [UInt8]? {
        guard range.offset + range.size <= length else {
            return nil
        }

        let pointer = mtlBuffer.contents().advanced(by: range.offset)
        return Array(UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: UInt8.self), count: range.size))
    }

    // MARK: - Direct Access

    /// Returns a pointer to the buffer contents.
    ///
    /// - Warning: Be careful with memory management.
    public var contents: UnsafeMutableRawPointer {
        mtlBuffer.contents()
    }

    /// Writes typed data to the buffer.
    ///
    /// - Parameters:
    ///   - value: The value to write.
    ///   - offset: Byte offset in the buffer.
    public func write<T>(_ value: T, offset: Int = 0) {
        guard offset + MemoryLayout<T>.size <= length else { return }
        let pointer = mtlBuffer.contents().advanced(by: offset)
        pointer.storeBytes(of: value, as: T.self)

        #if os(macOS)
        if mtlBuffer.storageMode == .managed {
            mtlBuffer.didModifyRange(offset..<(offset + MemoryLayout<T>.size))
        }
        #endif
    }

    /// Writes an array of typed data to the buffer.
    ///
    /// - Parameters:
    ///   - values: The values to write.
    ///   - offset: Byte offset in the buffer.
    public func write<T>(_ values: [T], offset: Int = 0) {
        let size = values.count * MemoryLayout<T>.stride
        guard offset + size <= length else { return }

        let pointer = mtlBuffer.contents().advanced(by: offset)
        _ = values.withUnsafeBytes { bytes in
            memcpy(pointer, bytes.baseAddress, size)
        }

        #if os(macOS)
        if mtlBuffer.storageMode == .managed {
            mtlBuffer.didModifyRange(offset..<(offset + size))
        }
        #endif
    }
}

#endif
