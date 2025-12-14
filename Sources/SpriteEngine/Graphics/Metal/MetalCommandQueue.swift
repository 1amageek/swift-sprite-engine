#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsCommandQueue.
public final class MetalCommandQueue: GraphicsCommandQueue, @unchecked Sendable {
    // MARK: - Properties

    /// The underlying Metal command queue.
    public let mtlQueue: MTLCommandQueue

    // MARK: - Initialization

    /// Creates a Metal command queue wrapper.
    ///
    /// - Parameter queue: The Metal command queue.
    init(queue: MTLCommandQueue) {
        self.mtlQueue = queue
    }

    // MARK: - Submission

    public func submit(_ commandBuffers: [any GraphicsCommandBuffer]) {
        for buffer in commandBuffers {
            guard let metalBuffer = buffer as? MetalCommandBuffer else { continue }
            metalBuffer.mtlCommandBuffer.commit()
        }
    }

    // MARK: - Direct Writes

    public func writeBuffer(_ buffer: any GraphicsBuffer, data: [UInt8], offset: Int) {
        guard let metalBuffer = buffer as? MetalBuffer else { return }
        metalBuffer.write(data, offset: offset)
    }

    public func writeTexture(_ texture: any GraphicsTexture, data: [UInt8], region: TextureRegion, mipLevel: Int) {
        guard let metalTexture = texture as? MetalTexture else { return }

        let mtlRegion = MTLRegion(
            origin: MTLOrigin(x: region.x, y: region.y, z: region.z),
            size: MTLSize(width: region.width, height: region.height, depth: region.depth)
        )

        // Calculate bytes per row based on pixel format
        let bytesPerPixel = bytesPerPixel(for: metalTexture.mtlTexture.pixelFormat)
        let bytesPerRow = region.width * bytesPerPixel

        data.withUnsafeBytes { bytes in
            metalTexture.mtlTexture.replace(
                region: mtlRegion,
                mipmapLevel: mipLevel,
                withBytes: bytes.baseAddress!,
                bytesPerRow: bytesPerRow
            )
        }
    }

    // MARK: - Helpers

    private func bytesPerPixel(for format: MTLPixelFormat) -> Int {
        switch format {
        case .r8Unorm, .r8Snorm, .r8Uint, .r8Sint:
            return 1
        case .r16Uint, .r16Sint, .r16Float, .rg8Unorm, .rg8Snorm, .rg8Uint, .rg8Sint:
            return 2
        case .r32Uint, .r32Sint, .r32Float, .rg16Uint, .rg16Sint, .rg16Float,
             .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint,
             .bgra8Unorm, .bgra8Unorm_srgb:
            return 4
        case .rg32Uint, .rg32Sint, .rg32Float, .rgba16Uint, .rgba16Sint, .rgba16Float:
            return 8
        case .rgba32Uint, .rgba32Sint, .rgba32Float:
            return 16
        default:
            return 4
        }
    }
}

#endif
