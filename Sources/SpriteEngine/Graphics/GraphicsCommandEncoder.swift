/// An encoder for recording GPU commands.
///
/// `GraphicsCommandEncoder` records commands that will be executed on the GPU.
/// Commands are not executed immediately; instead, they are recorded and then
/// submitted as a command buffer.
///
/// ## Platform Mapping
/// ```
/// Metal                          WebGPU
/// ─────────────────────────────  ─────────────────────────────
/// MTLCommandBuffer               GPUCommandEncoder
/// makeRenderCommandEncoder()     beginRenderPass()
/// commit()                       finish() → submit()
/// ```
///
/// ## Usage
/// ```swift
/// let encoder = device.makeCommandEncoder()
///
/// // Begin a render pass
/// let renderPass = encoder.beginRenderPass(descriptor: passDescriptor)
/// renderPass.setPipeline(pipeline)
/// renderPass.setVertexBuffer(buffer, offset: 0, index: 0)
/// renderPass.draw(vertexCount: 3)
/// renderPass.end()
///
/// // Finish encoding and submit
/// let commandBuffer = encoder.finish()
/// device.commandQueue.submit(commandBuffer)
/// ```
public protocol GraphicsCommandEncoder: AnyObject {
    /// Begins a render pass.
    ///
    /// - Parameter descriptor: The render pass configuration.
    /// - Returns: A render pass encoder for recording rendering commands.
    ///
    /// ## Platform Mapping
    /// - Metal: `commandBuffer.makeRenderCommandEncoder(descriptor:)`
    /// - WebGPU: `commandEncoder.beginRenderPass(descriptor)`
    func beginRenderPass(descriptor: RenderPassDescriptor) -> any GraphicsRenderPassEncoder

    /// Begins a compute pass.
    ///
    /// - Returns: A compute pass encoder for recording compute commands.
    ///
    /// ## Platform Mapping
    /// - Metal: `commandBuffer.makeComputeCommandEncoder()`
    /// - WebGPU: `commandEncoder.beginComputePass()`
    func beginComputePass() -> any GraphicsComputePassEncoder

    /// Copies data between buffers.
    ///
    /// - Parameters:
    ///   - source: The source buffer.
    ///   - sourceOffset: Offset in the source buffer.
    ///   - destination: The destination buffer.
    ///   - destinationOffset: Offset in the destination buffer.
    ///   - size: Number of bytes to copy.
    ///
    /// ## Platform Mapping
    /// - Metal: Uses blit encoder
    /// - WebGPU: `encoder.copyBufferToBuffer(...)`
    func copyBuffer(
        from source: any GraphicsBuffer,
        sourceOffset: Int,
        to destination: any GraphicsBuffer,
        destinationOffset: Int,
        size: Int
    )

    /// Copies data from a buffer to a texture.
    ///
    /// - Parameters:
    ///   - source: The source buffer.
    ///   - sourceOffset: Offset in the source buffer.
    ///   - bytesPerRow: Bytes per row of pixel data.
    ///   - destination: The destination texture.
    ///   - destinationOrigin: Origin in the texture.
    ///   - size: Size of the region to copy.
    func copyBufferToTexture(
        from source: any GraphicsBuffer,
        sourceOffset: Int,
        bytesPerRow: Int,
        to destination: any GraphicsTexture,
        destinationOrigin: TextureOrigin,
        size: TextureSize
    )

    /// Finishes encoding and returns a command buffer.
    ///
    /// After calling this method, the encoder cannot be used again.
    ///
    /// - Returns: A command buffer ready for submission.
    ///
    /// ## Platform Mapping
    /// - Metal: Returns the internal MTLCommandBuffer
    /// - WebGPU: `encoder.finish()` → GPUCommandBuffer
    func finish() -> any GraphicsCommandBuffer
}

// MARK: - Command Buffer

/// A recorded sequence of GPU commands ready for submission.
///
/// Command buffers are created by finishing a command encoder.
/// They can only be submitted once.
///
/// ## Platform Mapping
/// - Metal: `MTLCommandBuffer`
/// - WebGPU: `GPUCommandBuffer`
public protocol GraphicsCommandBuffer: AnyObject, Sendable {
    /// A label for debugging.
    var label: String? { get }
}

// MARK: - Render Pass Encoder

/// An encoder for recording rendering commands within a render pass.
///
/// ## Platform Mapping
/// - Metal: `MTLRenderCommandEncoder`
/// - WebGPU: `GPURenderPassEncoder`
public protocol GraphicsRenderPassEncoder: AnyObject {
    /// Sets the render pipeline to use.
    ///
    /// - Parameter pipeline: The render pipeline.
    func setPipeline(_ pipeline: any GraphicsRenderPipeline)

    /// Sets a vertex buffer.
    ///
    /// - Parameters:
    ///   - buffer: The vertex buffer.
    ///   - offset: Byte offset in the buffer.
    ///   - index: The buffer index (slot).
    func setVertexBuffer(_ buffer: any GraphicsBuffer, offset: Int, index: Int)

    /// Sets the viewport.
    ///
    /// - Parameter viewport: The viewport configuration.
    func setViewport(_ viewport: Viewport)

    /// Sets the scissor rectangle.
    ///
    /// - Parameter rect: The scissor rectangle.
    func setScissorRect(_ rect: ScissorRect)

    /// Draws primitives.
    ///
    /// - Parameters:
    ///   - vertexCount: Number of vertices to draw.
    ///   - instanceCount: Number of instances to draw.
    ///   - firstVertex: Index of the first vertex.
    ///   - firstInstance: Index of the first instance.
    func draw(
        vertexCount: Int,
        instanceCount: Int,
        firstVertex: Int,
        firstInstance: Int
    )

    /// Draws indexed primitives.
    ///
    /// - Parameters:
    ///   - indexCount: Number of indices to draw.
    ///   - instanceCount: Number of instances.
    ///   - firstIndex: First index in the index buffer.
    ///   - baseVertex: Value added to each index.
    ///   - firstInstance: First instance to draw.
    func drawIndexed(
        indexCount: Int,
        instanceCount: Int,
        firstIndex: Int,
        baseVertex: Int,
        firstInstance: Int
    )

    /// Sets the index buffer.
    ///
    /// - Parameters:
    ///   - buffer: The index buffer.
    ///   - format: The index format (uint16 or uint32).
    ///   - offset: Byte offset in the buffer.
    func setIndexBuffer(_ buffer: any GraphicsBuffer, format: IndexFormat, offset: Int)

    /// Ends the render pass.
    func end()
}

// MARK: - Default Implementations

extension GraphicsRenderPassEncoder {
    /// Draws with default instance and offset values.
    public func draw(vertexCount: Int) {
        draw(vertexCount: vertexCount, instanceCount: 1, firstVertex: 0, firstInstance: 0)
    }

    /// Draws indexed with default values.
    public func drawIndexed(indexCount: Int) {
        drawIndexed(indexCount: indexCount, instanceCount: 1, firstIndex: 0, baseVertex: 0, firstInstance: 0)
    }
}

// MARK: - Compute Pass Encoder

/// An encoder for recording compute commands.
///
/// ## Platform Mapping
/// - Metal: `MTLComputeCommandEncoder`
/// - WebGPU: `GPUComputePassEncoder`
public protocol GraphicsComputePassEncoder: AnyObject {
    /// Sets the compute pipeline.
    func setPipeline(_ pipeline: any GraphicsComputePipeline)

    /// Dispatches compute work.
    ///
    /// - Parameter workgroupCount: Number of workgroups in each dimension.
    func dispatchWorkgroups(x: Int, y: Int, z: Int)

    /// Ends the compute pass.
    func end()
}

// MARK: - Supporting Types

/// Viewport configuration.
public struct Viewport: Sendable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float
    public var minDepth: Float
    public var maxDepth: Float

    public init(x: Float, y: Float, width: Float, height: Float, minDepth: Float = 0, maxDepth: Float = 1) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.minDepth = minDepth
        self.maxDepth = maxDepth
    }
}

/// Scissor rectangle.
public struct ScissorRect: Sendable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// Index buffer format.
public enum IndexFormat: Sendable {
    /// 16-bit unsigned indices.
    case uint16
    /// 32-bit unsigned indices.
    case uint32
}

/// Origin point in a texture.
public struct TextureOrigin: Sendable {
    public var x: Int
    public var y: Int
    public var z: Int

    public init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Size of a texture region.
public struct TextureSize: Sendable {
    public var width: Int
    public var height: Int
    public var depth: Int

    public init(width: Int, height: Int, depth: Int = 1) {
        self.width = width
        self.height = height
        self.depth = depth
    }
}
