#if canImport(Metal)
import Metal

/// Metal implementation of GraphicsRenderPipeline.
public final class MetalRenderPipeline: GraphicsRenderPipeline, @unchecked Sendable {
    /// The underlying Metal render pipeline state.
    public let mtlPipeline: MTLRenderPipelineState

    /// A label for debugging.
    public let label: String?

    init(pipeline: MTLRenderPipelineState, label: String?) {
        self.mtlPipeline = pipeline
        self.label = label
    }
}

/// Metal implementation of GraphicsComputePipeline.
public final class MetalComputePipeline: GraphicsComputePipeline, @unchecked Sendable {
    /// The underlying Metal compute pipeline state.
    public let mtlPipeline: MTLComputePipelineState

    /// A label for debugging.
    public let label: String?

    init(pipeline: MTLComputePipelineState, label: String?) {
        self.mtlPipeline = pipeline
        self.label = label
    }
}

/// Metal implementation of GraphicsShaderModule.
public final class MetalShaderModule: GraphicsShaderModule, @unchecked Sendable {
    /// The underlying Metal library.
    public let mtlLibrary: MTLLibrary

    /// A label for debugging.
    public var label: String? { mtlLibrary.label }

    init(library: MTLLibrary) {
        self.mtlLibrary = library
    }

    public func function(named name: String) -> (any GraphicsShaderFunction)? {
        guard let function = mtlLibrary.makeFunction(name: name) else {
            return nil
        }
        return MetalShaderFunction(function: function)
    }
}

/// Metal implementation of GraphicsShaderFunction.
public final class MetalShaderFunction: GraphicsShaderFunction, @unchecked Sendable {
    /// The underlying Metal function.
    public let mtlFunction: MTLFunction

    /// The function name.
    public var name: String { mtlFunction.name }

    /// The function type.
    public var functionType: ShaderFunctionType {
        switch mtlFunction.functionType {
        case .vertex: return .vertex
        case .fragment: return .fragment
        case .kernel: return .kernel
        default: return .vertex
        }
    }

    init(function: MTLFunction) {
        self.mtlFunction = function
    }
}

#endif
