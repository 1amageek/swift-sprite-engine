#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsTexture.
public final class MetalTexture: GraphicsTexture, @unchecked Sendable {
    // MARK: - Properties

    /// The underlying Metal texture.
    public let mtlTexture: MTLTexture

    /// The width in pixels.
    public var width: Int { mtlTexture.width }

    /// The height in pixels.
    public var height: Int { mtlTexture.height }

    /// The depth (for 3D textures).
    public var depth: Int { mtlTexture.depth }

    /// The pixel format.
    public var format: PixelFormat { mtlTexture.pixelFormat.toWisp() }

    /// The texture type.
    public var textureType: TextureType { mtlTexture.textureType.toWisp() }

    /// The number of mip levels.
    public var mipLevelCount: Int { mtlTexture.mipmapLevelCount }

    /// A label for debugging.
    public var label: String? {
        get { mtlTexture.label }
        set { mtlTexture.label = newValue }
    }

    // MARK: - Initialization

    /// Creates a Metal texture wrapper.
    ///
    /// - Parameter texture: The Metal texture.
    init(texture: MTLTexture) {
        self.mtlTexture = texture
    }

    // MARK: - Views

    public func createView(descriptor: TextureViewDescriptor?) -> any GraphicsTextureView {
        // Metal doesn't have separate texture views like WebGPU
        // We return a view that references this texture
        return MetalTextureView(texture: self, descriptor: descriptor)
    }
}

// MARK: - Texture View

/// Metal implementation of GraphicsTextureView.
public final class MetalTextureView: GraphicsTextureView, @unchecked Sendable {
    /// The referenced texture.
    public let texture: any GraphicsTexture

    /// The underlying Metal texture.
    public var mtlTexture: MTLTexture {
        (texture as! MetalTexture).mtlTexture
    }

    /// A label for debugging.
    public var label: String? {
        mtlTexture.label
    }

    /// The view descriptor.
    let descriptor: TextureViewDescriptor?

    init(texture: MetalTexture, descriptor: TextureViewDescriptor?) {
        self.texture = texture
        self.descriptor = descriptor
    }
}

// MARK: - Sampler

/// Metal implementation of GraphicsSampler.
public final class MetalSampler: GraphicsSampler, @unchecked Sendable {
    /// The underlying Metal sampler state.
    public let mtlSampler: MTLSamplerState

    /// A label for debugging.
    public let label: String?

    init(sampler: MTLSamplerState, label: String?) {
        self.mtlSampler = sampler
        self.label = label
    }
}

// MARK: - Type Conversions

extension MTLPixelFormat {
    func toWisp() -> PixelFormat {
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
        case .rgba8Unorm_srgb: return .rgba8UnormSrgb
        case .rgba8Snorm: return .rgba8Snorm
        case .rgba8Uint: return .rgba8Uint
        case .rgba8Sint: return .rgba8Sint
        case .bgra8Unorm: return .bgra8Unorm
        case .bgra8Unorm_srgb: return .bgra8UnormSrgb
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
        case .depth24Unorm_stencil8: return .depth24UnormStencil8
        case .depth32Float_stencil8: return .depth32FloatStencil8
        default: return .rgba8Unorm
        }
    }
}

extension MTLTextureType {
    func toWisp() -> TextureType {
        switch self {
        case .type1D: return .type1D
        case .type2D: return .type2D
        case .type2DArray: return .type2DArray
        case .typeCube: return .typeCube
        case .typeCubeArray: return .typeCubeArray
        case .type3D: return .type3D
        default: return .type2D
        }
    }
}

#endif
