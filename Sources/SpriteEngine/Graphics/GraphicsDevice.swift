/// A protocol representing a GPU device.
///
/// `GraphicsDevice` abstracts the GPU interface for cross-platform rendering.
/// It provides a unified API that works with both Metal (iOS/macOS) and
/// WebGPU (Web/WASM) backends.
///
/// ## Platform Mapping
/// ```
/// Metal                          WebGPU
/// ─────────────────────────────  ─────────────────────────────
/// MTLDevice                      GPUDevice
/// MTLCommandQueue                GPUQueue
/// MTLBuffer                      GPUBuffer
/// MTLTexture                     GPUTexture
/// MTLRenderPipelineState         GPURenderPipeline
/// MTLLibrary                     GPUShaderModule
/// ```
///
/// ## Usage
/// ```swift
/// // Get the default device asynchronously
/// GraphicsDeviceFactory.requestDevice { device in
///     guard let device = device else {
///         fatalError("No GPU available")
///     }
///     // Create resources
///     let queue = device.commandQueue
///     let buffer = device.makeBuffer(length: 1024)
/// }
/// ```
///
/// ## Design Notes
/// Unlike Metal's synchronous `MTLCreateSystemDefaultDevice()`, WebGPU requires
/// async initialization via `requestAdapter()` and `requestDevice()`. This
/// abstraction uses async patterns to accommodate both.
public protocol GraphicsDevice: AnyObject, Sendable {
    // MARK: - Device Information

    /// The name of the GPU device.
    var name: String { get }

    /// The command queue for this device.
    ///
    /// Unlike Metal where you create queues, WebGPU provides a single queue
    /// per device via `device.queue`. This abstraction follows WebGPU's model.
    var commandQueue: any GraphicsCommandQueue { get }

    // MARK: - Buffer Creation

    /// Creates a new buffer with uninitialized contents.
    ///
    /// - Parameters:
    ///   - length: The size of the buffer in bytes.
    ///   - usage: How the buffer will be used.
    /// - Returns: A new buffer, or `nil` if creation fails.
    ///
    /// ## Platform Mapping
    /// - Metal: `device.makeBuffer(length:options:)`
    /// - WebGPU: `device.createBuffer({size, usage})`
    func makeBuffer(length: Int, usage: BufferUsage) -> (any GraphicsBuffer)?

    /// Creates a new buffer initialized with data.
    ///
    /// - Parameters:
    ///   - data: The data to copy into the buffer.
    ///   - usage: How the buffer will be used.
    /// - Returns: A new buffer, or `nil` if creation fails.
    func makeBuffer(data: [UInt8], usage: BufferUsage) -> (any GraphicsBuffer)?

    // MARK: - Texture Creation

    /// Creates a new texture with the specified descriptor.
    ///
    /// - Parameter descriptor: The texture configuration.
    /// - Returns: A new texture, or `nil` if creation fails.
    ///
    /// ## Platform Mapping
    /// - Metal: `device.makeTexture(descriptor:)`
    /// - WebGPU: `device.createTexture({...})`
    func makeTexture(descriptor: GraphicsTextureDescriptor) -> (any GraphicsTexture)?

    // MARK: - Sampler Creation

    /// Creates a new texture sampler.
    ///
    /// - Parameter descriptor: The sampler configuration.
    /// - Returns: A new sampler, or `nil` if creation fails.
    func makeSampler(descriptor: GraphicsSamplerDescriptor) -> (any GraphicsSampler)?

    // MARK: - Shader Creation

    /// Creates a shader module from source code.
    ///
    /// - Parameter source: Shader source code (MSL for Metal, WGSL for WebGPU).
    /// - Returns: A shader module, or throws if compilation fails.
    ///
    /// ## Shader Languages
    /// - Metal: Metal Shading Language (MSL)
    /// - WebGPU: WebGPU Shading Language (WGSL)
    func makeShaderModule(source: String) throws -> any GraphicsShaderModule

    // MARK: - Pipeline Creation

    /// Creates a render pipeline state.
    ///
    /// - Parameter descriptor: The pipeline configuration.
    /// - Returns: A render pipeline, or throws if creation fails.
    ///
    /// ## Platform Mapping
    /// - Metal: `device.makeRenderPipelineState(descriptor:)`
    /// - WebGPU: `device.createRenderPipeline({...})`
    func makeRenderPipeline(descriptor: RenderPipelineDescriptor) throws -> any GraphicsRenderPipeline

    // MARK: - Command Encoding

    /// Creates a new command encoder.
    ///
    /// - Returns: A command encoder for recording GPU commands.
    ///
    /// ## Platform Mapping
    /// - Metal: Returns a wrapper that creates MTLCommandBuffer internally
    /// - WebGPU: `device.createCommandEncoder()`
    func makeCommandEncoder() -> any GraphicsCommandEncoder
}

// MARK: - Default Implementations

extension GraphicsDevice {
    /// Creates a buffer with default vertex usage.
    public func makeBuffer(length: Int) -> (any GraphicsBuffer)? {
        makeBuffer(length: length, usage: .vertex)
    }

    /// Creates a buffer from Float array.
    public func makeBuffer(floats: [CGFloat], usage: BufferUsage = .vertex) -> (any GraphicsBuffer)? {
        let data = floats.withUnsafeBytes { Array($0) }
        return makeBuffer(data: data, usage: usage)
    }
}

// MARK: - Buffer Usage

/// Specifies how a buffer will be used.
///
/// ## Platform Mapping
/// - Metal: Maps to `MTLResourceOptions` and pipeline bindings
/// - WebGPU: Maps to `GPUBufferUsage` flags
public struct BufferUsage: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Buffer can be used as vertex data.
    /// - Metal: Bound via `setVertexBuffer`
    /// - WebGPU: `GPUBufferUsage.VERTEX`
    public static let vertex = BufferUsage(rawValue: 1 << 0)

    /// Buffer can be used as index data.
    /// - Metal: Used with `drawIndexedPrimitives`
    /// - WebGPU: `GPUBufferUsage.INDEX`
    public static let index = BufferUsage(rawValue: 1 << 1)

    /// Buffer can be used as uniform data.
    /// - Metal: Bound via `setVertexBuffer`/`setFragmentBuffer`
    /// - WebGPU: `GPUBufferUsage.UNIFORM`
    public static let uniform = BufferUsage(rawValue: 1 << 2)

    /// Buffer can be used as storage (read/write in shaders).
    /// - Metal: Bound as buffer with `MTLResourceUsage.read/write`
    /// - WebGPU: `GPUBufferUsage.STORAGE`
    public static let storage = BufferUsage(rawValue: 1 << 3)

    /// Buffer can be the source of a copy operation.
    /// - WebGPU: `GPUBufferUsage.COPY_SRC`
    public static let copySrc = BufferUsage(rawValue: 1 << 4)

    /// Buffer can be the destination of a copy operation.
    /// - WebGPU: `GPUBufferUsage.COPY_DST`
    public static let copyDst = BufferUsage(rawValue: 1 << 5)

    /// Buffer can be mapped for reading by the CPU.
    /// - WebGPU: `GPUBufferUsage.MAP_READ`
    public static let mapRead = BufferUsage(rawValue: 1 << 6)

    /// Buffer can be mapped for writing by the CPU.
    /// - WebGPU: `GPUBufferUsage.MAP_WRITE`
    public static let mapWrite = BufferUsage(rawValue: 1 << 7)
}

// MARK: - Device Factory

/// Factory for creating graphics devices.
///
/// ## Async Initialization
/// WebGPU requires async device creation. This factory provides a unified
/// async interface that works for both Metal and WebGPU.
///
/// ```swift
/// GraphicsDeviceFactory.requestDevice { device in
///     // Use device
/// }
/// ```
public enum GraphicsDeviceFactory {
    /// Callback type for device request.
    public typealias DeviceCallback = @Sendable ((any GraphicsDevice)?) -> Void

    /// Requests the default graphics device asynchronously.
    ///
    /// - Parameter completion: Called with the device when available.
    ///
    /// ## Platform Behavior
    /// - Metal: Calls completion immediately with device
    /// - WebGPU: Waits for adapter/device promises to resolve
    public static func requestDevice(completion: @escaping DeviceCallback) {
        #if canImport(Metal)
        // Metal: synchronous, but we use async pattern for consistency
        completion(MetalDevice.createSystemDefault())
        #else
        // WASM uses WebGPURenderer directly via SwiftWebGPU, not this abstraction
        completion(nil)
        #endif
    }

    /// Returns a device synchronously if available.
    ///
    /// - Returns: The device, or `nil` if not available synchronously.
    ///
    /// - Warning: This only works on Metal. WebGPU requires async initialization.
    public static func createSystemDefaultSync() -> (any GraphicsDevice)? {
        #if canImport(Metal)
        return MetalDevice.createSystemDefault()
        #else
        return nil
        #endif
    }
}
