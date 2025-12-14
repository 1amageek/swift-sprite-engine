/// A queue for submitting command buffers to the GPU.
///
/// `GraphicsCommandQueue` abstracts command submission to the GPU.
///
/// ## Platform Mapping
/// ```
/// Metal                          WebGPU
/// ─────────────────────────────  ─────────────────────────────
/// MTLCommandQueue                GPUQueue
/// queue.makeCommandBuffer()      (via encoder.finish())
/// commandBuffer.commit()         queue.submit([commandBuffer])
/// ```
///
/// ## Usage
/// ```swift
/// let encoder = device.makeCommandEncoder()
/// // ... encode commands ...
/// let commandBuffer = encoder.finish()
/// device.commandQueue.submit(commandBuffer)
/// ```
public protocol GraphicsCommandQueue: AnyObject, Sendable {
    /// Submits a command buffer for execution.
    ///
    /// - Parameter commandBuffer: The command buffer to execute.
    ///
    /// ## Platform Mapping
    /// - Metal: `commandBuffer.commit()`
    /// - WebGPU: `queue.submit([commandBuffer])`
    func submit(_ commandBuffer: any GraphicsCommandBuffer)

    /// Submits multiple command buffers for execution.
    ///
    /// - Parameter commandBuffers: The command buffers to execute.
    func submit(_ commandBuffers: [any GraphicsCommandBuffer])

    /// Writes data directly to a buffer.
    ///
    /// This is a convenience method that bypasses command encoding for
    /// simple buffer updates.
    ///
    /// - Parameters:
    ///   - buffer: The destination buffer.
    ///   - data: The data to write.
    ///   - offset: The byte offset in the buffer.
    ///
    /// ## Platform Mapping
    /// - Metal: Uses `buffer.contents()` memcpy
    /// - WebGPU: `queue.writeBuffer(buffer, offset, data)`
    func writeBuffer(_ buffer: any GraphicsBuffer, data: [UInt8], offset: Int)

    /// Writes data directly to a texture.
    ///
    /// - Parameters:
    ///   - texture: The destination texture.
    ///   - data: The pixel data to write.
    ///   - region: The region to update.
    ///   - mipLevel: The mip level to update.
    ///
    /// ## Platform Mapping
    /// - Metal: `texture.replace(region:mipmapLevel:withBytes:bytesPerRow:)`
    /// - WebGPU: `queue.writeTexture({texture}, data, {bytesPerRow}, {size})`
    func writeTexture(_ texture: any GraphicsTexture, data: [UInt8], region: TextureRegion, mipLevel: Int)
}

// MARK: - Default Implementations

extension GraphicsCommandQueue {
    /// Submits a single command buffer.
    public func submit(_ commandBuffer: any GraphicsCommandBuffer) {
        submit([commandBuffer])
    }

    /// Writes data with zero offset.
    public func writeBuffer(_ buffer: any GraphicsBuffer, data: [UInt8]) {
        writeBuffer(buffer, data: data, offset: 0)
    }
}

// MARK: - Texture Region

/// A region within a texture.
public struct TextureRegion: Sendable {
    /// The x origin of the region.
    public var x: Int

    /// The y origin of the region.
    public var y: Int

    /// The z origin of the region (for 3D textures).
    public var z: Int

    /// The width of the region.
    public var width: Int

    /// The height of the region.
    public var height: Int

    /// The depth of the region (for 3D textures).
    public var depth: Int

    /// Creates a 2D texture region.
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.z = 0
        self.width = width
        self.height = height
        self.depth = 1
    }

    /// Creates a 3D texture region.
    public init(x: Int, y: Int, z: Int, width: Int, height: Int, depth: Int) {
        self.x = x
        self.y = y
        self.z = z
        self.width = width
        self.height = height
        self.depth = depth
    }

    /// A region covering the entire texture at the origin.
    public static func fullTexture(width: Int, height: Int) -> TextureRegion {
        TextureRegion(x: 0, y: 0, width: width, height: height)
    }
}
