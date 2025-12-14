#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsDevice.
public final class MetalDevice: GraphicsDevice, @unchecked Sendable {
    // MARK: - Properties

    /// The underlying Metal device.
    public let mtlDevice: MTLDevice

    /// The name of the GPU.
    public var name: String { mtlDevice.name }

    /// The command queue.
    public let commandQueue: any GraphicsCommandQueue

    // MARK: - Initialization

    /// Creates a Metal device wrapper.
    ///
    /// - Parameter device: The Metal device.
    public init(device: MTLDevice) {
        self.mtlDevice = device
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = MetalCommandQueue(queue: queue)
    }

    /// Creates the system default Metal device.
    ///
    /// - Returns: The default device, or nil if Metal is not available.
    public static func createSystemDefault() -> MetalDevice? {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return nil
        }
        return MetalDevice(device: device)
    }

    // MARK: - Buffer Creation

    public func makeBuffer(length: Int, usage: BufferUsage) -> (any GraphicsBuffer)? {
        let options = usage.metalResourceOptions
        guard let buffer = mtlDevice.makeBuffer(length: length, options: options) else {
            return nil
        }
        return MetalBuffer(buffer: buffer, usage: usage)
    }

    public func makeBuffer(data: [UInt8], usage: BufferUsage) -> (any GraphicsBuffer)? {
        let options = usage.metalResourceOptions
        guard let buffer = mtlDevice.makeBuffer(bytes: data, length: data.count, options: options) else {
            return nil
        }
        return MetalBuffer(buffer: buffer, usage: usage)
    }

    // MARK: - Texture Creation

    public func makeTexture(descriptor: GraphicsTextureDescriptor) -> (any GraphicsTexture)? {
        let mtlDescriptor = descriptor.toMTLTextureDescriptor()
        guard let texture = mtlDevice.makeTexture(descriptor: mtlDescriptor) else {
            return nil
        }
        return MetalTexture(texture: texture)
    }

    // MARK: - Sampler Creation

    public func makeSampler(descriptor: GraphicsSamplerDescriptor) -> (any GraphicsSampler)? {
        let mtlDescriptor = descriptor.toMTLSamplerDescriptor()
        guard let sampler = mtlDevice.makeSamplerState(descriptor: mtlDescriptor) else {
            return nil
        }
        return MetalSampler(sampler: sampler, label: descriptor.label)
    }

    // MARK: - Shader Creation

    public func makeShaderModule(source: String) throws -> any GraphicsShaderModule {
        let library = try mtlDevice.makeLibrary(source: source, options: nil)
        return MetalShaderModule(library: library)
    }

    // MARK: - Pipeline Creation

    public func makeRenderPipeline(descriptor: RenderPipelineDescriptor) throws -> any GraphicsRenderPipeline {
        let mtlDescriptor = MTLRenderPipelineDescriptor()
        mtlDescriptor.label = descriptor.label

        if let vertexFunction = descriptor.vertexFunction as? MetalShaderFunction {
            mtlDescriptor.vertexFunction = vertexFunction.mtlFunction
        }

        if let fragmentFunction = descriptor.fragmentFunction as? MetalShaderFunction {
            mtlDescriptor.fragmentFunction = fragmentFunction.mtlFunction
        }

        if let vertexDescriptor = descriptor.vertexDescriptor {
            mtlDescriptor.vertexDescriptor = vertexDescriptor.toMTLVertexDescriptor()
        }

        for (index, attachment) in descriptor.colorAttachments.enumerated() {
            mtlDescriptor.colorAttachments[index].pixelFormat = attachment.format.toMTLPixelFormat()
            mtlDescriptor.colorAttachments[index].isBlendingEnabled = attachment.blendingEnabled
            mtlDescriptor.colorAttachments[index].sourceRGBBlendFactor = attachment.sourceRGBBlendFactor.toMTL()
            mtlDescriptor.colorAttachments[index].destinationRGBBlendFactor = attachment.destinationRGBBlendFactor.toMTL()
            mtlDescriptor.colorAttachments[index].rgbBlendOperation = attachment.rgbBlendOperation.toMTL()
            mtlDescriptor.colorAttachments[index].sourceAlphaBlendFactor = attachment.sourceAlphaBlendFactor.toMTL()
            mtlDescriptor.colorAttachments[index].destinationAlphaBlendFactor = attachment.destinationAlphaBlendFactor.toMTL()
            mtlDescriptor.colorAttachments[index].alphaBlendOperation = attachment.alphaBlendOperation.toMTL()
            mtlDescriptor.colorAttachments[index].writeMask = attachment.writeMask.toMTL()
        }

        if let depthFormat = descriptor.depthAttachmentFormat {
            mtlDescriptor.depthAttachmentPixelFormat = depthFormat.toMTLPixelFormat()
        }

        if let stencilFormat = descriptor.stencilAttachmentFormat {
            mtlDescriptor.stencilAttachmentPixelFormat = stencilFormat.toMTLPixelFormat()
        }

        mtlDescriptor.rasterSampleCount = descriptor.sampleCount

        let pipelineState = try mtlDevice.makeRenderPipelineState(descriptor: mtlDescriptor)
        return MetalRenderPipeline(pipeline: pipelineState, label: descriptor.label)
    }

    // MARK: - Command Encoding

    public func makeCommandEncoder() -> any GraphicsCommandEncoder {
        guard let mtlQueue = (commandQueue as? MetalCommandQueue)?.mtlQueue,
              let commandBuffer = mtlQueue.makeCommandBuffer() else {
            fatalError("Failed to create Metal command buffer")
        }
        return MetalCommandEncoder(commandBuffer: commandBuffer)
    }
}

// MARK: - Buffer Usage Extension

extension BufferUsage {
    var metalResourceOptions: MTLResourceOptions {
        // For simplicity, use shared storage on iOS/macOS
        #if os(iOS) || os(tvOS)
        return .storageModeShared
        #else
        if contains(.mapRead) || contains(.mapWrite) {
            return .storageModeManaged
        }
        return .storageModeShared
        #endif
    }
}

// MARK: - Texture Descriptor Extension

extension GraphicsTextureDescriptor {
    func toMTLTextureDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.width = width
        descriptor.height = height
        descriptor.depth = depth
        descriptor.pixelFormat = format.toMTLPixelFormat()
        descriptor.textureType = textureType.toMTL()
        descriptor.usage = usage.toMTL()
        descriptor.mipmapLevelCount = mipLevelCount
        descriptor.arrayLength = arrayLength
        descriptor.sampleCount = sampleCount
        return descriptor
    }
}

// MARK: - Sampler Descriptor Extension

extension GraphicsSamplerDescriptor {
    func toMTLSamplerDescriptor() -> MTLSamplerDescriptor {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = addressModeU.toMTL()
        descriptor.tAddressMode = addressModeV.toMTL()
        descriptor.rAddressMode = addressModeW.toMTL()
        descriptor.magFilter = magFilter.toMTL()
        descriptor.minFilter = minFilter.toMTL()
        descriptor.mipFilter = mipmapFilter.toMTL()
        descriptor.lodMinClamp = lodMinClamp
        descriptor.lodMaxClamp = lodMaxClamp
        descriptor.maxAnisotropy = maxAnisotropy
        if let compare = compare {
            descriptor.compareFunction = compare.toMTL()
        }
        descriptor.label = label
        return descriptor
    }
}

// MARK: - Vertex Descriptor Extension

extension VertexDescriptor {
    func toMTLVertexDescriptor() -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()

        for (index, attr) in attributes.enumerated() {
            descriptor.attributes[index].format = attr.format.toMTL()
            descriptor.attributes[index].offset = attr.offset
            descriptor.attributes[index].bufferIndex = attr.bufferIndex
        }

        for (index, layout) in layouts.enumerated() {
            descriptor.layouts[index].stride = layout.stride
            descriptor.layouts[index].stepFunction = layout.stepMode.toMTL()
            descriptor.layouts[index].stepRate = 1
        }

        return descriptor
    }
}

// MARK: - Type Conversions

extension PixelFormat {
    func toMTLPixelFormat() -> MTLPixelFormat {
        switch self {
        case .r8Unorm: return .r8Unorm
        case .r8Snorm: return .r8Snorm
        case .r8Uint: return .r8Uint
        case .r8Sint: return .r8Sint
        case .r16Uint: return .r16Uint
        case .r16Sint: return .r16Sint
        case .r16Float: return .r16Float
        case .rg8Unorm: return .rg8Unorm
        case .rg8Snorm: return .rg8Snorm
        case .rg8Uint: return .rg8Uint
        case .rg8Sint: return .rg8Sint
        case .r32Uint: return .r32Uint
        case .r32Sint: return .r32Sint
        case .r32Float: return .r32Float
        case .rg16Uint: return .rg16Uint
        case .rg16Sint: return .rg16Sint
        case .rg16Float: return .rg16Float
        case .rgba8Unorm: return .rgba8Unorm
        case .rgba8UnormSrgb: return .rgba8Unorm_srgb
        case .rgba8Snorm: return .rgba8Snorm
        case .rgba8Uint: return .rgba8Uint
        case .rgba8Sint: return .rgba8Sint
        case .bgra8Unorm: return .bgra8Unorm
        case .bgra8UnormSrgb: return .bgra8Unorm_srgb
        case .rg32Uint: return .rg32Uint
        case .rg32Sint: return .rg32Sint
        case .rg32Float: return .rg32Float
        case .rgba16Uint: return .rgba16Uint
        case .rgba16Sint: return .rgba16Sint
        case .rgba16Float: return .rgba16Float
        case .rgba32Uint: return .rgba32Uint
        case .rgba32Sint: return .rgba32Sint
        case .rgba32Float: return .rgba32Float
        case .depth16Unorm: return .depth16Unorm
        case .depth32Float: return .depth32Float
        case .depth24UnormStencil8: return .depth24Unorm_stencil8
        case .depth32FloatStencil8: return .depth32Float_stencil8
        case .bc1RgbaUnorm: return .bc1_rgba
        case .bc1RgbaUnormSrgb: return .bc1_rgba_srgb
        case .bc2RgbaUnorm: return .bc2_rgba
        case .bc2RgbaUnormSrgb: return .bc2_rgba_srgb
        case .bc3RgbaUnorm: return .bc3_rgba
        case .bc3RgbaUnormSrgb: return .bc3_rgba_srgb
        case .bc4RUnorm: return .bc4_rUnorm
        case .bc4RSnorm: return .bc4_rSnorm
        case .bc5RgUnorm: return .bc5_rgUnorm
        case .bc5RgSnorm: return .bc5_rgSnorm
        case .bc6hRgbUfloat: return .bc6H_rgbuFloat
        case .bc6hRgbFloat: return .bc6H_rgbFloat
        case .bc7RgbaUnorm: return .bc7_rgbaUnorm
        case .bc7RgbaUnormSrgb: return .bc7_rgbaUnorm_srgb
        }
    }
}

extension TextureType {
    func toMTL() -> MTLTextureType {
        switch self {
        case .type1D: return .type1D
        case .type2D: return .type2D
        case .type2DArray: return .type2DArray
        case .typeCube: return .typeCube
        case .typeCubeArray: return .typeCubeArray
        case .type3D: return .type3D
        }
    }
}

extension TextureUsage {
    func toMTL() -> MTLTextureUsage {
        var usage: MTLTextureUsage = []
        if contains(.sampled) { usage.insert(.shaderRead) }
        if contains(.storage) { usage.insert(.shaderWrite) }
        if contains(.renderTarget) { usage.insert(.renderTarget) }
        return usage
    }
}

extension AddressMode {
    func toMTL() -> MTLSamplerAddressMode {
        switch self {
        case .clampToEdge: return .clampToEdge
        case .repeat: return .repeat
        case .mirrorRepeat: return .mirrorRepeat
        case .clampToBorder: return .clampToBorderColor
        }
    }
}

extension FilterMode {
    func toMTL() -> MTLSamplerMinMagFilter {
        switch self {
        case .nearest: return .nearest
        case .linear: return .linear
        }
    }
}

extension MipmapFilterMode {
    func toMTL() -> MTLSamplerMipFilter {
        switch self {
        case .nearest: return .nearest
        case .linear: return .linear
        }
    }
}

extension CompareFunction {
    func toMTL() -> MTLCompareFunction {
        switch self {
        case .never: return .never
        case .less: return .less
        case .equal: return .equal
        case .lessEqual: return .lessEqual
        case .greater: return .greater
        case .notEqual: return .notEqual
        case .greaterEqual: return .greaterEqual
        case .always: return .always
        }
    }
}

extension BlendFactor {
    func toMTL() -> MTLBlendFactor {
        switch self {
        case .zero: return .zero
        case .one: return .one
        case .sourceColor: return .sourceColor
        case .oneMinusSourceColor: return .oneMinusSourceColor
        case .sourceAlpha: return .sourceAlpha
        case .oneMinusSourceAlpha: return .oneMinusSourceAlpha
        case .destinationColor: return .destinationColor
        case .oneMinusDestinationColor: return .oneMinusDestinationColor
        case .destinationAlpha: return .destinationAlpha
        case .oneMinusDestinationAlpha: return .oneMinusDestinationAlpha
        case .sourceAlphaSaturated: return .sourceAlphaSaturated
        case .blendColor: return .blendColor
        case .oneMinusBlendColor: return .oneMinusBlendColor
        case .blendAlpha: return .blendAlpha
        case .oneMinusBlendAlpha: return .oneMinusBlendAlpha
        }
    }
}

extension BlendOperation {
    func toMTL() -> MTLBlendOperation {
        switch self {
        case .add: return .add
        case .subtract: return .subtract
        case .reverseSubtract: return .reverseSubtract
        case .min: return .min
        case .max: return .max
        }
    }
}

extension ColorWriteMask {
    func toMTL() -> MTLColorWriteMask {
        var mask: MTLColorWriteMask = []
        if contains(.red) { mask.insert(.red) }
        if contains(.green) { mask.insert(.green) }
        if contains(.blue) { mask.insert(.blue) }
        if contains(.alpha) { mask.insert(.alpha) }
        return mask
    }
}

extension VertexFormat {
    func toMTL() -> MTLVertexFormat {
        switch self {
        case .uint8x2: return .uchar2
        case .uint8x4: return .uchar4
        case .sint8x2: return .char2
        case .sint8x4: return .char4
        case .unorm8x2: return .uchar2Normalized
        case .unorm8x4: return .uchar4Normalized
        case .snorm8x2: return .char2Normalized
        case .snorm8x4: return .char4Normalized
        case .uint16x2: return .ushort2
        case .uint16x4: return .ushort4
        case .sint16x2: return .short2
        case .sint16x4: return .short4
        case .unorm16x2: return .ushort2Normalized
        case .unorm16x4: return .ushort4Normalized
        case .snorm16x2: return .short2Normalized
        case .snorm16x4: return .short4Normalized
        case .float16x2: return .half2
        case .float16x4: return .half4
        case .float32: return .float
        case .float32x2: return .float2
        case .float32x3: return .float3
        case .float32x4: return .float4
        case .uint32: return .uint
        case .uint32x2: return .uint2
        case .uint32x3: return .uint3
        case .uint32x4: return .uint4
        case .sint32: return .int
        case .sint32x2: return .int2
        case .sint32x3: return .int3
        case .sint32x4: return .int4
        }
    }
}

extension VertexStepMode {
    func toMTL() -> MTLVertexStepFunction {
        switch self {
        case .vertex: return .perVertex
        case .instance: return .perInstance
        }
    }
}

#endif
