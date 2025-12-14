/// Configuration for a render pass.
///
/// ## Platform Mapping
/// - Metal: `MTLRenderPassDescriptor`
/// - WebGPU: `GPURenderPassDescriptor`
///
/// ## Usage
/// ```swift
/// var descriptor = RenderPassDescriptor()
/// descriptor.colorAttachments[0].texture = renderTarget
/// descriptor.colorAttachments[0].loadAction = .clear
/// descriptor.colorAttachments[0].clearColor = Color(r: 0, g: 0, b: 0, a: 1)
/// descriptor.colorAttachments[0].storeAction = .store
///
/// let renderPass = encoder.beginRenderPass(descriptor: descriptor)
/// ```
public struct RenderPassDescriptor: Sendable {
    /// Color attachment configurations.
    public var colorAttachments: [RenderPassColorAttachment]

    /// Depth attachment configuration.
    public var depthAttachment: RenderPassDepthAttachment?

    /// Stencil attachment configuration.
    public var stencilAttachment: RenderPassStencilAttachment?

    /// A label for debugging.
    public var label: String?

    public init() {
        self.colorAttachments = []
        self.depthAttachment = nil
        self.stencilAttachment = nil
        self.label = nil
    }

    /// Creates a render pass descriptor for a single color attachment.
    public init(
        colorTexture: any GraphicsTextureView,
        clearColor: ClearColor = ClearColor(r: 0, g: 0, b: 0, a: 1),
        loadAction: LoadAction = .clear,
        storeAction: StoreAction = .store
    ) {
        self.colorAttachments = [
            RenderPassColorAttachment(
                texture: colorTexture,
                loadAction: loadAction,
                storeAction: storeAction,
                clearColor: clearColor
            )
        ]
        self.depthAttachment = nil
        self.stencilAttachment = nil
        self.label = nil
    }
}

// MARK: - Color Attachment

/// Configuration for a color attachment in a render pass.
public struct RenderPassColorAttachment: Sendable {
    /// The texture to render to.
    public var texture: (any GraphicsTextureView)?

    /// The texture to resolve MSAA to.
    public var resolveTexture: (any GraphicsTextureView)?

    /// What to do at the start of the pass.
    public var loadAction: LoadAction

    /// What to do at the end of the pass.
    public var storeAction: StoreAction

    /// The clear color (when loadAction is .clear).
    public var clearColor: ClearColor

    public init(
        texture: (any GraphicsTextureView)? = nil,
        loadAction: LoadAction = .clear,
        storeAction: StoreAction = .store,
        clearColor: ClearColor = ClearColor(r: 0, g: 0, b: 0, a: 1)
    ) {
        self.texture = texture
        self.resolveTexture = nil
        self.loadAction = loadAction
        self.storeAction = storeAction
        self.clearColor = clearColor
    }
}

// MARK: - Depth Attachment

/// Configuration for a depth attachment in a render pass.
public struct RenderPassDepthAttachment: Sendable {
    /// The depth texture.
    public var texture: (any GraphicsTextureView)?

    /// What to do at the start of the pass.
    public var loadAction: LoadAction

    /// What to do at the end of the pass.
    public var storeAction: StoreAction

    /// The clear depth value (when loadAction is .clear).
    public var clearDepth: Float

    public init(
        texture: (any GraphicsTextureView)? = nil,
        loadAction: LoadAction = .clear,
        storeAction: StoreAction = .store,
        clearDepth: Float = 1.0
    ) {
        self.texture = texture
        self.loadAction = loadAction
        self.storeAction = storeAction
        self.clearDepth = clearDepth
    }
}

// MARK: - Stencil Attachment

/// Configuration for a stencil attachment in a render pass.
public struct RenderPassStencilAttachment: Sendable {
    /// The stencil texture.
    public var texture: (any GraphicsTextureView)?

    /// What to do at the start of the pass.
    public var loadAction: LoadAction

    /// What to do at the end of the pass.
    public var storeAction: StoreAction

    /// The clear stencil value (when loadAction is .clear).
    public var clearStencil: UInt32

    public init(
        texture: (any GraphicsTextureView)? = nil,
        loadAction: LoadAction = .clear,
        storeAction: StoreAction = .store,
        clearStencil: UInt32 = 0
    ) {
        self.texture = texture
        self.loadAction = loadAction
        self.storeAction = storeAction
        self.clearStencil = clearStencil
    }
}

// MARK: - Load/Store Actions

/// Action to take when beginning a render pass.
public enum LoadAction: Sendable {
    /// Don't care about existing contents.
    /// - Metal: `.dontCare`
    /// - WebGPU: `"load": undefined` (implicit clear)
    case dontCare

    /// Preserve existing contents.
    /// - Metal: `.load`
    /// - WebGPU: `"load": "load"`
    case load

    /// Clear to a specified value.
    /// - Metal: `.clear`
    /// - WebGPU: `"load": "clear"` with `clearValue`
    case clear
}

/// Action to take when ending a render pass.
public enum StoreAction: Sendable {
    /// Don't care about contents (may discard).
    /// - Metal: `.dontCare`
    /// - WebGPU: `"store": "discard"`
    case dontCare

    /// Store the contents.
    /// - Metal: `.store`
    /// - WebGPU: `"store": "store"`
    case store

    /// Resolve MSAA and discard.
    /// - Metal: `.multisampleResolve`
    case multisampleResolve

    /// Store and resolve MSAA.
    /// - Metal: `.storeAndMultisampleResolve`
    case storeAndMultisampleResolve
}

// MARK: - Clear Color

/// A color used for clearing render targets.
public struct ClearColor: Sendable {
    public var r: Double
    public var g: Double
    public var b: Double
    public var a: Double

    public init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// Black color.
    public static let black = ClearColor(r: 0, g: 0, b: 0, a: 1)

    /// White color.
    public static let white = ClearColor(r: 1, g: 1, b: 1, a: 1)

    /// Transparent.
    public static let clear = ClearColor(r: 0, g: 0, b: 0, a: 0)

    /// Creates a clear color from 0-255 integer values.
    public init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.r = Double(red) / 255.0
        self.g = Double(green) / 255.0
        self.b = Double(blue) / 255.0
        self.a = Double(alpha) / 255.0
    }
}
