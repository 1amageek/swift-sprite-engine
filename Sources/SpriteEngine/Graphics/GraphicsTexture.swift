/// A GPU texture for storing image data.
///
/// ## Platform Mapping
/// ```
/// Metal                          WebGPU
/// ─────────────────────────────  ─────────────────────────────
/// MTLTexture                     GPUTexture
/// MTLTextureDescriptor           GPUTextureDescriptor
/// texture.width                  texture.width
/// texture.height                 texture.height
/// ```
///
/// ## Usage
/// ```swift
/// let descriptor = GraphicsTextureDescriptor(
///     width: 256,
///     height: 256,
///     format: .rgba8Unorm,
///     usage: [.sampled, .renderTarget]
/// )
/// let texture = device.makeTexture(descriptor: descriptor)
/// ```
public protocol GraphicsTexture: AnyObject, Sendable {
    /// The width of the texture in pixels.
    var width: Int { get }

    /// The height of the texture in pixels.
    var height: Int { get }

    /// The depth of the texture (for 3D textures).
    var depth: Int { get }

    /// The pixel format.
    var format: PixelFormat { get }

    /// The texture type.
    var textureType: TextureType { get }

    /// The number of mip levels.
    var mipLevelCount: Int { get }

    /// A label for debugging.
    var label: String? { get set }

    /// Creates a view into this texture.
    ///
    /// - Parameter descriptor: The view configuration.
    /// - Returns: A texture view.
    func createView(descriptor: TextureViewDescriptor?) -> any GraphicsTextureView
}

// MARK: - Texture View

/// A view into a texture, used for binding to pipelines.
///
/// ## Platform Mapping
/// - Metal: MTLTexture (same object, different usage)
/// - WebGPU: GPUTextureView
public protocol GraphicsTextureView: AnyObject, Sendable {
    /// The texture this view references.
    var texture: any GraphicsTexture { get }

    /// A label for debugging.
    var label: String? { get }
}

// MARK: - Texture Descriptor

/// Configuration for creating a texture.
public struct GraphicsTextureDescriptor: Sendable {
    /// The width in pixels.
    public var width: Int

    /// The height in pixels.
    public var height: Int

    /// The depth (for 3D textures).
    public var depth: Int

    /// The pixel format.
    public var format: PixelFormat

    /// How the texture will be used.
    public var usage: TextureUsage

    /// The texture type.
    public var textureType: TextureType

    /// Number of mip levels.
    public var mipLevelCount: Int

    /// Number of array layers.
    public var arrayLength: Int

    /// Number of samples (for MSAA).
    public var sampleCount: Int

    /// A label for debugging.
    public var label: String?

    /// Creates a 2D texture descriptor.
    public init(
        width: Int,
        height: Int,
        format: PixelFormat,
        usage: TextureUsage = .sampled
    ) {
        self.width = width
        self.height = height
        self.depth = 1
        self.format = format
        self.usage = usage
        self.textureType = .type2D
        self.mipLevelCount = 1
        self.arrayLength = 1
        self.sampleCount = 1
        self.label = nil
    }

    /// Creates a texture descriptor with full configuration.
    public init(
        width: Int,
        height: Int,
        depth: Int = 1,
        format: PixelFormat,
        usage: TextureUsage,
        textureType: TextureType,
        mipLevelCount: Int = 1,
        arrayLength: Int = 1,
        sampleCount: Int = 1,
        label: String? = nil
    ) {
        self.width = width
        self.height = height
        self.depth = depth
        self.format = format
        self.usage = usage
        self.textureType = textureType
        self.mipLevelCount = mipLevelCount
        self.arrayLength = arrayLength
        self.sampleCount = sampleCount
        self.label = label
    }
}

// MARK: - Texture View Descriptor

/// Configuration for creating a texture view.
public struct TextureViewDescriptor: Sendable {
    /// The pixel format (defaults to texture's format).
    public var format: PixelFormat?

    /// The view dimension.
    public var dimension: TextureViewDimension?

    /// Base mip level.
    public var baseMipLevel: Int

    /// Number of mip levels to include.
    public var mipLevelCount: Int?

    /// Base array layer.
    public var baseArrayLayer: Int

    /// Number of array layers to include.
    public var arrayLayerCount: Int?

    /// Aspect of the texture to view.
    public var aspect: TextureAspect

    /// A label for debugging.
    public var label: String?

    public init(
        format: PixelFormat? = nil,
        dimension: TextureViewDimension? = nil,
        baseMipLevel: Int = 0,
        mipLevelCount: Int? = nil,
        baseArrayLayer: Int = 0,
        arrayLayerCount: Int? = nil,
        aspect: TextureAspect = .all,
        label: String? = nil
    ) {
        self.format = format
        self.dimension = dimension
        self.baseMipLevel = baseMipLevel
        self.mipLevelCount = mipLevelCount
        self.baseArrayLayer = baseArrayLayer
        self.arrayLayerCount = arrayLayerCount
        self.aspect = aspect
        self.label = label
    }
}

// MARK: - Texture Types

/// The type of texture.
public enum TextureType: Sendable {
    /// 1D texture.
    case type1D
    /// 2D texture.
    case type2D
    /// 2D texture array.
    case type2DArray
    /// Cube texture.
    case typeCube
    /// Cube texture array.
    case typeCubeArray
    /// 3D texture.
    case type3D
}

/// How a texture view is interpreted.
public enum TextureViewDimension: Sendable {
    case dimension1D
    case dimension2D
    case dimension2DArray
    case dimensionCube
    case dimensionCubeArray
    case dimension3D
}

/// Which aspect of a texture to view.
public enum TextureAspect: Sendable {
    /// All aspects (color or depth+stencil).
    case all
    /// Stencil only.
    case stencilOnly
    /// Depth only.
    case depthOnly
}

// MARK: - Texture Usage

/// How a texture will be used.
public struct TextureUsage: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Texture can be sampled in shaders.
    /// - Metal: `MTLTextureUsage.shaderRead`
    /// - WebGPU: `GPUTextureUsage.TEXTURE_BINDING`
    public static let sampled = TextureUsage(rawValue: 1 << 0)

    /// Texture can be written in shaders.
    /// - Metal: `MTLTextureUsage.shaderWrite`
    /// - WebGPU: `GPUTextureUsage.STORAGE_BINDING`
    public static let storage = TextureUsage(rawValue: 1 << 1)

    /// Texture can be used as a render target.
    /// - Metal: `MTLTextureUsage.renderTarget`
    /// - WebGPU: `GPUTextureUsage.RENDER_ATTACHMENT`
    public static let renderTarget = TextureUsage(rawValue: 1 << 2)

    /// Texture can be the source of a copy operation.
    /// - WebGPU: `GPUTextureUsage.COPY_SRC`
    public static let copySrc = TextureUsage(rawValue: 1 << 3)

    /// Texture can be the destination of a copy operation.
    /// - WebGPU: `GPUTextureUsage.COPY_DST`
    public static let copyDst = TextureUsage(rawValue: 1 << 4)
}

// MARK: - Pixel Format

/// Pixel formats for textures.
///
/// ## Platform Mapping
/// ```
/// Wisp                Metal                  WebGPU
/// ─────────────────   ─────────────────────  ─────────────────────
/// .rgba8Unorm         .rgba8Unorm            "rgba8unorm"
/// .rgba8UnormSrgb     .rgba8Unorm_sRGB       "rgba8unorm-srgb"
/// .bgra8Unorm         .bgra8Unorm            "bgra8unorm"
/// .depth32Float       .depth32Float          "depth32float"
/// ```
public enum PixelFormat: Sendable {
    // 8-bit formats
    case r8Unorm
    case r8Snorm
    case r8Uint
    case r8Sint

    // 16-bit formats
    case r16Uint
    case r16Sint
    case r16Float
    case rg8Unorm
    case rg8Snorm
    case rg8Uint
    case rg8Sint

    // 32-bit formats
    case r32Uint
    case r32Sint
    case r32Float
    case rg16Uint
    case rg16Sint
    case rg16Float
    case rgba8Unorm
    case rgba8UnormSrgb
    case rgba8Snorm
    case rgba8Uint
    case rgba8Sint
    case bgra8Unorm
    case bgra8UnormSrgb

    // 64-bit formats
    case rg32Uint
    case rg32Sint
    case rg32Float
    case rgba16Uint
    case rgba16Sint
    case rgba16Float

    // 128-bit formats
    case rgba32Uint
    case rgba32Sint
    case rgba32Float

    // Depth/Stencil formats
    case depth16Unorm
    case depth32Float
    case depth24UnormStencil8
    case depth32FloatStencil8

    // Compressed formats (BC)
    case bc1RgbaUnorm
    case bc1RgbaUnormSrgb
    case bc2RgbaUnorm
    case bc2RgbaUnormSrgb
    case bc3RgbaUnorm
    case bc3RgbaUnormSrgb
    case bc4RUnorm
    case bc4RSnorm
    case bc5RgUnorm
    case bc5RgSnorm
    case bc6hRgbUfloat
    case bc6hRgbFloat
    case bc7RgbaUnorm
    case bc7RgbaUnormSrgb
}

// MARK: - Sampler

/// A texture sampler that defines how textures are sampled in shaders.
///
/// ## Platform Mapping
/// - Metal: `MTLSamplerState`
/// - WebGPU: `GPUSampler`
public protocol GraphicsSampler: AnyObject, Sendable {
    /// A label for debugging.
    var label: String? { get }
}

// MARK: - Sampler Descriptor

/// Configuration for creating a sampler.
public struct GraphicsSamplerDescriptor: Sendable {
    /// How to sample when texture coordinates are outside [0, 1].
    public var addressModeU: AddressMode
    public var addressModeV: AddressMode
    public var addressModeW: AddressMode

    /// Filtering mode when magnifying.
    public var magFilter: FilterMode

    /// Filtering mode when minifying.
    public var minFilter: FilterMode

    /// Filtering between mip levels.
    public var mipmapFilter: MipmapFilterMode

    /// LOD clamping.
    public var lodMinClamp: Float
    public var lodMaxClamp: Float

    /// Comparison function for shadow maps.
    public var compare: CompareFunction?

    /// Maximum anisotropy.
    public var maxAnisotropy: Int

    /// A label for debugging.
    public var label: String?

    public init(
        addressModeU: AddressMode = .clampToEdge,
        addressModeV: AddressMode = .clampToEdge,
        addressModeW: AddressMode = .clampToEdge,
        magFilter: FilterMode = .linear,
        minFilter: FilterMode = .linear,
        mipmapFilter: MipmapFilterMode = .linear,
        lodMinClamp: Float = 0,
        lodMaxClamp: Float = 32,
        compare: CompareFunction? = nil,
        maxAnisotropy: Int = 1,
        label: String? = nil
    ) {
        self.addressModeU = addressModeU
        self.addressModeV = addressModeV
        self.addressModeW = addressModeW
        self.magFilter = magFilter
        self.minFilter = minFilter
        self.mipmapFilter = mipmapFilter
        self.lodMinClamp = lodMinClamp
        self.lodMaxClamp = lodMaxClamp
        self.compare = compare
        self.maxAnisotropy = maxAnisotropy
        self.label = label
    }
}

// MARK: - Sampler Types

/// Texture addressing mode.
public enum AddressMode: Sendable {
    /// Clamp to edge color.
    case clampToEdge
    /// Repeat the texture.
    case `repeat`
    /// Mirror and repeat.
    case mirrorRepeat
    /// Clamp to border color.
    case clampToBorder
}

/// Texture filtering mode.
public enum FilterMode: Sendable {
    /// Nearest neighbor.
    case nearest
    /// Linear interpolation.
    case linear
}

/// Mipmap filtering mode.
public enum MipmapFilterMode: Sendable {
    /// Nearest mip level.
    case nearest
    /// Linear interpolation between mip levels.
    case linear
}

/// Comparison function for depth/stencil.
public enum CompareFunction: Sendable {
    case never
    case less
    case equal
    case lessEqual
    case greater
    case notEqual
    case greaterEqual
    case always
}
