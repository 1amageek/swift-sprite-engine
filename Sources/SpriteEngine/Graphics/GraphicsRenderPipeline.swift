/// A compiled render pipeline state.
///
/// ## Platform Mapping
/// - Metal: `MTLRenderPipelineState`
/// - WebGPU: `GPURenderPipeline`
///
/// ## Usage
/// ```swift
/// let descriptor = RenderPipelineDescriptor()
/// descriptor.vertexFunction = shader.function(named: "vertexMain")
/// descriptor.fragmentFunction = shader.function(named: "fragmentMain")
/// descriptor.colorAttachments[0].format = .bgra8Unorm
///
/// let pipeline = try device.makeRenderPipeline(descriptor: descriptor)
/// renderPass.setPipeline(pipeline)
/// ```
public protocol GraphicsRenderPipeline: AnyObject, Sendable {
    /// A label for debugging.
    var label: String? { get }
}

// MARK: - Compute Pipeline

/// A compiled compute pipeline state.
///
/// ## Platform Mapping
/// - Metal: `MTLComputePipelineState`
/// - WebGPU: `GPUComputePipeline`
public protocol GraphicsComputePipeline: AnyObject, Sendable {
    /// A label for debugging.
    var label: String? { get }
}

// MARK: - Shader Module

/// A compiled shader module.
///
/// ## Platform Mapping
/// - Metal: `MTLLibrary`
/// - WebGPU: `GPUShaderModule`
///
/// ## Shader Languages
/// - Metal: Metal Shading Language (MSL)
/// - WebGPU: WebGPU Shading Language (WGSL)
public protocol GraphicsShaderModule: AnyObject, Sendable {
    /// A label for debugging.
    var label: String? { get }

    /// Gets a function from this shader module.
    ///
    /// - Parameter name: The function name.
    /// - Returns: The shader function, or nil if not found.
    func function(named name: String) -> (any GraphicsShaderFunction)?
}

// MARK: - Shader Function

/// A function within a shader module.
///
/// ## Platform Mapping
/// - Metal: `MTLFunction`
/// - WebGPU: Entry point name string
public protocol GraphicsShaderFunction: AnyObject, Sendable {
    /// The function name.
    var name: String { get }

    /// The function type.
    var functionType: ShaderFunctionType { get }
}

/// The type of shader function.
public enum ShaderFunctionType: Sendable {
    /// Vertex shader.
    case vertex
    /// Fragment shader.
    case fragment
    /// Compute kernel.
    case kernel
}

// MARK: - Render Pipeline Descriptor

/// Configuration for creating a render pipeline.
public struct RenderPipelineDescriptor: Sendable {
    /// A label for debugging.
    public var label: String?

    /// The vertex shader function.
    public var vertexFunction: (any GraphicsShaderFunction)?

    /// The fragment shader function.
    public var fragmentFunction: (any GraphicsShaderFunction)?

    /// The vertex buffer layout.
    public var vertexDescriptor: VertexDescriptor?

    /// Color attachment configurations.
    public var colorAttachments: [ColorAttachmentDescriptor]

    /// Depth attachment format.
    public var depthAttachmentFormat: PixelFormat?

    /// Stencil attachment format.
    public var stencilAttachmentFormat: PixelFormat?

    /// Number of samples for MSAA.
    public var sampleCount: Int

    /// Primitive topology.
    public var primitiveTopology: PrimitiveTopology

    public init() {
        self.label = nil
        self.vertexFunction = nil
        self.fragmentFunction = nil
        self.vertexDescriptor = nil
        self.colorAttachments = [ColorAttachmentDescriptor()]
        self.depthAttachmentFormat = nil
        self.stencilAttachmentFormat = nil
        self.sampleCount = 1
        self.primitiveTopology = .triangle
    }
}

// MARK: - Color Attachment Descriptor

/// Configuration for a color attachment in a render pipeline.
public struct ColorAttachmentDescriptor: Sendable {
    /// The pixel format.
    public var format: PixelFormat

    /// Whether blending is enabled.
    public var blendingEnabled: Bool

    /// Source RGB blend factor.
    public var sourceRGBBlendFactor: BlendFactor

    /// Destination RGB blend factor.
    public var destinationRGBBlendFactor: BlendFactor

    /// RGB blend operation.
    public var rgbBlendOperation: BlendOperation

    /// Source alpha blend factor.
    public var sourceAlphaBlendFactor: BlendFactor

    /// Destination alpha blend factor.
    public var destinationAlphaBlendFactor: BlendFactor

    /// Alpha blend operation.
    public var alphaBlendOperation: BlendOperation

    /// Write mask for color channels.
    public var writeMask: ColorWriteMask

    public init(
        format: PixelFormat = .bgra8Unorm,
        blendingEnabled: Bool = false,
        sourceRGBBlendFactor: BlendFactor = .one,
        destinationRGBBlendFactor: BlendFactor = .zero,
        rgbBlendOperation: BlendOperation = .add,
        sourceAlphaBlendFactor: BlendFactor = .one,
        destinationAlphaBlendFactor: BlendFactor = .zero,
        alphaBlendOperation: BlendOperation = .add,
        writeMask: ColorWriteMask = .all
    ) {
        self.format = format
        self.blendingEnabled = blendingEnabled
        self.sourceRGBBlendFactor = sourceRGBBlendFactor
        self.destinationRGBBlendFactor = destinationRGBBlendFactor
        self.rgbBlendOperation = rgbBlendOperation
        self.sourceAlphaBlendFactor = sourceAlphaBlendFactor
        self.destinationAlphaBlendFactor = destinationAlphaBlendFactor
        self.alphaBlendOperation = alphaBlendOperation
        self.writeMask = writeMask
    }

    /// Creates a standard alpha blending configuration.
    public static var alphaBlending: ColorAttachmentDescriptor {
        ColorAttachmentDescriptor(
            blendingEnabled: true,
            sourceRGBBlendFactor: .sourceAlpha,
            destinationRGBBlendFactor: .oneMinusSourceAlpha,
            rgbBlendOperation: .add,
            sourceAlphaBlendFactor: .one,
            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
            alphaBlendOperation: .add
        )
    }

    /// Creates a premultiplied alpha blending configuration.
    public static var premultipliedAlphaBlending: ColorAttachmentDescriptor {
        ColorAttachmentDescriptor(
            blendingEnabled: true,
            sourceRGBBlendFactor: .one,
            destinationRGBBlendFactor: .oneMinusSourceAlpha,
            rgbBlendOperation: .add,
            sourceAlphaBlendFactor: .one,
            destinationAlphaBlendFactor: .oneMinusSourceAlpha,
            alphaBlendOperation: .add
        )
    }

    /// Creates an additive blending configuration.
    public static var additiveBlending: ColorAttachmentDescriptor {
        ColorAttachmentDescriptor(
            blendingEnabled: true,
            sourceRGBBlendFactor: .sourceAlpha,
            destinationRGBBlendFactor: .one,
            rgbBlendOperation: .add,
            sourceAlphaBlendFactor: .one,
            destinationAlphaBlendFactor: .one,
            alphaBlendOperation: .add
        )
    }
}

// MARK: - Blend Types

/// Blend factor for color blending.
public enum BlendFactor: Sendable {
    case zero
    case one
    case sourceColor
    case oneMinusSourceColor
    case sourceAlpha
    case oneMinusSourceAlpha
    case destinationColor
    case oneMinusDestinationColor
    case destinationAlpha
    case oneMinusDestinationAlpha
    case sourceAlphaSaturated
    case blendColor
    case oneMinusBlendColor
    case blendAlpha
    case oneMinusBlendAlpha
}

/// Blend operation.
public enum BlendOperation: Sendable {
    case add
    case subtract
    case reverseSubtract
    case min
    case max
}

/// Color write mask.
public struct ColorWriteMask: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let red = ColorWriteMask(rawValue: 1 << 0)
    public static let green = ColorWriteMask(rawValue: 1 << 1)
    public static let blue = ColorWriteMask(rawValue: 1 << 2)
    public static let alpha = ColorWriteMask(rawValue: 1 << 3)
    public static let all: ColorWriteMask = [.red, .green, .blue, .alpha]
    public static let none = ColorWriteMask(rawValue: 0)
}

// MARK: - Primitive Topology

/// The type of primitive to render.
public enum PrimitiveTopology: Sendable {
    /// Individual points.
    case point
    /// Line segments.
    case line
    /// Connected line segments.
    case lineStrip
    /// Triangles.
    case triangle
    /// Connected triangles.
    case triangleStrip
}

// MARK: - Vertex Descriptor

/// Describes the layout of vertex data.
public struct VertexDescriptor: Sendable {
    /// The vertex attributes.
    public var attributes: [VertexAttribute]

    /// The vertex buffer layouts.
    public var layouts: [VertexBufferLayout]

    public init(attributes: [VertexAttribute] = [], layouts: [VertexBufferLayout] = []) {
        self.attributes = attributes
        self.layouts = layouts
    }
}

/// A vertex attribute in the vertex buffer.
public struct VertexAttribute: Sendable {
    /// The attribute format.
    public var format: VertexFormat

    /// Byte offset within the vertex.
    public var offset: Int

    /// The buffer index this attribute comes from.
    public var bufferIndex: Int

    /// The shader location/index.
    public var shaderLocation: Int

    public init(format: VertexFormat, offset: Int, bufferIndex: Int, shaderLocation: Int) {
        self.format = format
        self.offset = offset
        self.bufferIndex = bufferIndex
        self.shaderLocation = shaderLocation
    }
}

/// Layout of a vertex buffer.
public struct VertexBufferLayout: Sendable {
    /// Bytes between vertices.
    public var stride: Int

    /// How the buffer advances.
    public var stepMode: VertexStepMode

    public init(stride: Int, stepMode: VertexStepMode = .vertex) {
        self.stride = stride
        self.stepMode = stepMode
    }
}

/// How vertex buffer advances.
public enum VertexStepMode: Sendable {
    /// Advance per vertex.
    case vertex
    /// Advance per instance.
    case instance
}

/// Vertex attribute format.
public enum VertexFormat: Sendable {
    // 8-bit formats
    case uint8x2
    case uint8x4
    case sint8x2
    case sint8x4
    case unorm8x2
    case unorm8x4
    case snorm8x2
    case snorm8x4

    // 16-bit formats
    case uint16x2
    case uint16x4
    case sint16x2
    case sint16x4
    case unorm16x2
    case unorm16x4
    case snorm16x2
    case snorm16x4
    case float16x2
    case float16x4

    // 32-bit formats
    case float32
    case float32x2
    case float32x3
    case float32x4
    case uint32
    case uint32x2
    case uint32x3
    case uint32x4
    case sint32
    case sint32x2
    case sint32x3
    case sint32x4
}

// MARK: - Compute Pipeline Descriptor

/// Configuration for creating a compute pipeline.
public struct ComputePipelineDescriptor: Sendable {
    /// A label for debugging.
    public var label: String?

    /// The compute function.
    public var computeFunction: (any GraphicsShaderFunction)?

    public init() {
        self.label = nil
        self.computeFunction = nil
    }
}
