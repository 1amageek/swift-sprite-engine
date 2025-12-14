#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsCommandEncoder.
public final class MetalCommandEncoder: GraphicsCommandEncoder {
    // MARK: - Properties

    /// The underlying Metal command buffer.
    let mtlCommandBuffer: MTLCommandBuffer

    /// Blit encoder for copy operations.
    private var blitEncoder: MTLBlitCommandEncoder?

    // MARK: - Initialization

    /// Creates a Metal command encoder.
    ///
    /// - Parameter commandBuffer: The Metal command buffer.
    init(commandBuffer: MTLCommandBuffer) {
        self.mtlCommandBuffer = commandBuffer
    }

    // MARK: - Render Pass

    public func beginRenderPass(descriptor: RenderPassDescriptor) -> any GraphicsRenderPassEncoder {
        let mtlDescriptor = descriptor.toMTLRenderPassDescriptor()
        guard let encoder = mtlCommandBuffer.makeRenderCommandEncoder(descriptor: mtlDescriptor) else {
            fatalError("Failed to create Metal render command encoder")
        }
        return MetalRenderPassEncoder(encoder: encoder)
    }

    // MARK: - Compute Pass

    public func beginComputePass() -> any GraphicsComputePassEncoder {
        guard let encoder = mtlCommandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create Metal compute command encoder")
        }
        return MetalComputePassEncoder(encoder: encoder)
    }

    // MARK: - Copy Operations

    public func copyBuffer(
        from source: any GraphicsBuffer,
        sourceOffset: Int,
        to destination: any GraphicsBuffer,
        destinationOffset: Int,
        size: Int
    ) {
        guard let srcBuffer = source as? MetalBuffer,
              let dstBuffer = destination as? MetalBuffer else { return }

        let blit = getOrCreateBlitEncoder()
        blit.copy(
            from: srcBuffer.mtlBuffer,
            sourceOffset: sourceOffset,
            to: dstBuffer.mtlBuffer,
            destinationOffset: destinationOffset,
            size: size
        )
    }

    public func copyBufferToTexture(
        from source: any GraphicsBuffer,
        sourceOffset: Int,
        bytesPerRow: Int,
        to destination: any GraphicsTexture,
        destinationOrigin: TextureOrigin,
        size: TextureSize
    ) {
        guard let srcBuffer = source as? MetalBuffer,
              let dstTexture = destination as? MetalTexture else { return }

        let blit = getOrCreateBlitEncoder()
        blit.copy(
            from: srcBuffer.mtlBuffer,
            sourceOffset: sourceOffset,
            sourceBytesPerRow: bytesPerRow,
            sourceBytesPerImage: bytesPerRow * size.height,
            sourceSize: MTLSize(width: size.width, height: size.height, depth: size.depth),
            to: dstTexture.mtlTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: destinationOrigin.x, y: destinationOrigin.y, z: destinationOrigin.z)
        )
    }

    // MARK: - Finish

    public func finish() -> any GraphicsCommandBuffer {
        // End any active blit encoder
        blitEncoder?.endEncoding()
        blitEncoder = nil

        return MetalCommandBuffer(commandBuffer: mtlCommandBuffer)
    }

    // MARK: - Helpers

    private func getOrCreateBlitEncoder() -> MTLBlitCommandEncoder {
        if let blit = blitEncoder {
            return blit
        }
        guard let blit = mtlCommandBuffer.makeBlitCommandEncoder() else {
            fatalError("Failed to create Metal blit command encoder")
        }
        blitEncoder = blit
        return blit
    }
}

// MARK: - Command Buffer

/// Metal implementation of GraphicsCommandBuffer.
public final class MetalCommandBuffer: GraphicsCommandBuffer, @unchecked Sendable {
    /// The underlying Metal command buffer.
    let mtlCommandBuffer: MTLCommandBuffer

    /// A label for debugging.
    public var label: String? { mtlCommandBuffer.label }

    init(commandBuffer: MTLCommandBuffer) {
        self.mtlCommandBuffer = commandBuffer
    }
}

// MARK: - Render Pass Encoder

/// Metal implementation of GraphicsRenderPassEncoder.
public final class MetalRenderPassEncoder: GraphicsRenderPassEncoder {
    /// The underlying Metal render command encoder.
    let mtlEncoder: MTLRenderCommandEncoder

    init(encoder: MTLRenderCommandEncoder) {
        self.mtlEncoder = encoder
    }

    public func setPipeline(_ pipeline: any GraphicsRenderPipeline) {
        guard let metalPipeline = pipeline as? MetalRenderPipeline else { return }
        mtlEncoder.setRenderPipelineState(metalPipeline.mtlPipeline)
    }

    public func setVertexBuffer(_ buffer: any GraphicsBuffer, offset: Int, index: Int) {
        guard let metalBuffer = buffer as? MetalBuffer else { return }
        mtlEncoder.setVertexBuffer(metalBuffer.mtlBuffer, offset: offset, index: index)
    }

    public func setViewport(_ viewport: Viewport) {
        mtlEncoder.setViewport(MTLViewport(
            originX: Double(viewport.x),
            originY: Double(viewport.y),
            width: Double(viewport.width),
            height: Double(viewport.height),
            znear: Double(viewport.minDepth),
            zfar: Double(viewport.maxDepth)
        ))
    }

    public func setScissorRect(_ rect: ScissorRect) {
        mtlEncoder.setScissorRect(MTLScissorRect(
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height
        ))
    }

    public func draw(
        vertexCount: Int,
        instanceCount: Int,
        firstVertex: Int,
        firstInstance: Int
    ) {
        mtlEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: firstVertex,
            vertexCount: vertexCount,
            instanceCount: instanceCount,
            baseInstance: firstInstance
        )
    }

    public func drawIndexed(
        indexCount: Int,
        instanceCount: Int,
        firstIndex: Int,
        baseVertex: Int,
        firstInstance: Int
    ) {
        // Note: Metal requires an index buffer to be bound separately
        // This would need the index buffer and format to be set beforehand
    }

    public func setIndexBuffer(_ buffer: any GraphicsBuffer, format: IndexFormat, offset: Int) {
        // Store for use in drawIndexed
        // Metal binds index buffer at draw time, not here
    }

    public func end() {
        mtlEncoder.endEncoding()
    }
}

// MARK: - Compute Pass Encoder

/// Metal implementation of GraphicsComputePassEncoder.
public final class MetalComputePassEncoder: GraphicsComputePassEncoder {
    /// The underlying Metal compute command encoder.
    let mtlEncoder: MTLComputeCommandEncoder

    init(encoder: MTLComputeCommandEncoder) {
        self.mtlEncoder = encoder
    }

    public func setPipeline(_ pipeline: any GraphicsComputePipeline) {
        guard let metalPipeline = pipeline as? MetalComputePipeline else { return }
        mtlEncoder.setComputePipelineState(metalPipeline.mtlPipeline)
    }

    public func dispatchWorkgroups(x: Int, y: Int, z: Int) {
        mtlEncoder.dispatchThreadgroups(
            MTLSize(width: x, height: y, depth: z),
            threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1)
        )
    }

    public func end() {
        mtlEncoder.endEncoding()
    }
}

// MARK: - Render Pass Descriptor Extension

extension RenderPassDescriptor {
    func toMTLRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()

        for (index, attachment) in colorAttachments.enumerated() {
            if let textureView = attachment.texture as? MetalTextureView {
                descriptor.colorAttachments[index].texture = textureView.mtlTexture
            }
            if let resolveView = attachment.resolveTexture as? MetalTextureView {
                descriptor.colorAttachments[index].resolveTexture = resolveView.mtlTexture
            }
            descriptor.colorAttachments[index].loadAction = attachment.loadAction.toMTL()
            descriptor.colorAttachments[index].storeAction = attachment.storeAction.toMTL()
            descriptor.colorAttachments[index].clearColor = attachment.clearColor.toMTL()
        }

        if let depth = depthAttachment {
            if let textureView = depth.texture as? MetalTextureView {
                descriptor.depthAttachment.texture = textureView.mtlTexture
            }
            descriptor.depthAttachment.loadAction = depth.loadAction.toMTL()
            descriptor.depthAttachment.storeAction = depth.storeAction.toMTL()
            descriptor.depthAttachment.clearDepth = Double(depth.clearDepth)
        }

        if let stencil = stencilAttachment {
            if let textureView = stencil.texture as? MetalTextureView {
                descriptor.stencilAttachment.texture = textureView.mtlTexture
            }
            descriptor.stencilAttachment.loadAction = stencil.loadAction.toMTL()
            descriptor.stencilAttachment.storeAction = stencil.storeAction.toMTL()
            descriptor.stencilAttachment.clearStencil = stencil.clearStencil
        }

        return descriptor
    }
}

// MARK: - Type Conversions

extension LoadAction {
    func toMTL() -> MTLLoadAction {
        switch self {
        case .dontCare: return .dontCare
        case .load: return .load
        case .clear: return .clear
        }
    }
}

extension StoreAction {
    func toMTL() -> MTLStoreAction {
        switch self {
        case .dontCare: return .dontCare
        case .store: return .store
        case .multisampleResolve: return .multisampleResolve
        case .storeAndMultisampleResolve: return .storeAndMultisampleResolve
        }
    }
}

extension ClearColor {
    func toMTL() -> MTLClearColor {
        MTLClearColor(red: r, green: g, blue: b, alpha: a)
    }
}

#endif
