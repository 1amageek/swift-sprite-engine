#if arch(wasm32)
import SwiftWebGPU
import JavaScriptKit

/// WebGPU-based renderer for SpriteEngine.
///
/// Renders sprites using instanced drawing for efficient batched rendering.
///
/// ## Usage
/// ```swift
/// let renderer = try await WebGPURenderer.create(canvas: canvasElement)
/// renderer.render(commands: drawCommands, backgroundColor: .black)
/// ```
public final class WebGPURenderer {
    // MARK: - Properties

    /// The GPU device.
    public let device: GPUDevice

    /// The canvas context for presenting frames.
    private let context: GPUCanvasContext

    /// The preferred texture format.
    private let format: GPUTextureFormat

    /// The canvas size.
    private var canvasWidth: UInt32
    private var canvasHeight: UInt32

    /// Texture manager for handling textures.
    let textureManager: WebGPUTextureManager

    // MARK: - GPU Resources

    /// The render pipeline for textured sprites.
    private var renderPipeline: GPURenderPipeline!

    /// The render pipeline for solid color sprites.
    private var solidColorPipeline: GPURenderPipeline!

    /// Vertex buffer containing quad geometry.
    private var quadVertexBuffer: GPUBuffer!

    /// Instance buffer for sprite data.
    private var instanceBuffer: GPUBuffer!

    /// Uniform buffer for view-projection matrix.
    private var uniformBuffer: GPUBuffer!

    /// Bind group layout.
    private var bindGroupLayout: GPUBindGroupLayout!

    /// Bind groups for each texture (cached).
    private var bindGroupCache: [UInt32: GPUBindGroup] = [:]

    /// Maximum number of sprites per draw call.
    private let maxSpritesPerBatch: Int = 10000

    // MARK: - Initialization

    /// Creates a WebGPU renderer asynchronously.
    ///
    /// - Parameter canvas: The HTML canvas element to render to.
    /// - Returns: A configured WebGPU renderer.
    public static func create(canvas: JSObject) async throws -> WebGPURenderer {
        guard let gpu = GPU.shared else {
            throw WebGPURendererError.webGPUNotSupported
        }

        guard let adapter = try await gpu.requestAdapter() else {
            throw WebGPURendererError.noAdapterFound
        }

        let device = try await adapter.requestDevice()
        let context = GPUCanvasContext(canvas: canvas)
        let format = gpu.preferredCanvasFormat

        let width = UInt32(canvas.width.number ?? 800)
        let height = UInt32(canvas.height.number ?? 600)

        context.configure(GPUCanvasConfiguration(
            device: device,
            format: format,
            alphaMode: .premultiplied
        ))

        let renderer = WebGPURenderer(
            device: device,
            context: context,
            format: format,
            width: width,
            height: height
        )

        renderer.setupPipelines()
        renderer.setupBuffers()

        return renderer
    }

    private init(
        device: GPUDevice,
        context: GPUCanvasContext,
        format: GPUTextureFormat,
        width: UInt32,
        height: UInt32
    ) {
        self.device = device
        self.context = context
        self.format = format
        self.canvasWidth = width
        self.canvasHeight = height
        self.textureManager = WebGPUTextureManager(device: device)
    }

    // MARK: - Setup

    private func setupPipelines() {
        // Create shader module
        let shaderModule = device.createShaderModule(descriptor: GPUShaderModuleDescriptor(
            code: SpriteShader.source,
            label: "SpriteShader"
        ))

        // Create bind group layout
        bindGroupLayout = device.createBindGroupLayout(descriptor: GPUBindGroupLayoutDescriptor(
            entries: [
                // Uniforms
                GPUBindGroupLayoutEntry(
                    binding: 0,
                    visibility: .vertex,
                    buffer: GPUBufferBindingLayout(type: .uniform)
                ),
                // Sampler
                GPUBindGroupLayoutEntry(
                    binding: 1,
                    visibility: .fragment,
                    sampler: GPUSamplerBindingLayout(type: .filtering)
                ),
                // Texture
                GPUBindGroupLayoutEntry(
                    binding: 2,
                    visibility: .fragment,
                    texture: GPUTextureBindingLayout(sampleType: .float)
                )
            ],
            label: "SpriteBindGroupLayout"
        ))

        let pipelineLayout = device.createPipelineLayout(descriptor: GPUPipelineLayoutDescriptor(
            bindGroupLayouts: [bindGroupLayout],
            label: "SpritePipelineLayout"
        ))

        // Vertex buffer layouts
        let vertexBufferLayout = GPUVertexBufferLayout(
            arrayStride: 8,  // 2 floats * 4 bytes
            stepMode: .vertex,
            attributes: [
                GPUVertexAttribute(format: .float32x2, offset: 0, shaderLocation: 0)
            ]
        )

        let instanceBufferLayout = GPUVertexBufferLayout(
            arrayStride: SpriteShader.instanceStride,
            stepMode: .instance,
            attributes: [
                // position (offset 0, 8 bytes)
                GPUVertexAttribute(format: .float32x2, offset: 0, shaderLocation: 1),
                // size (offset 8, 8 bytes)
                GPUVertexAttribute(format: .float32x2, offset: 8, shaderLocation: 2),
                // rotation (offset 16, 4 bytes)
                GPUVertexAttribute(format: .float32, offset: 16, shaderLocation: 3),
                // padding at offset 20 (4 bytes)
                // anchor (offset 24, 8 bytes)
                GPUVertexAttribute(format: .float32x2, offset: 24, shaderLocation: 4),
                // texRect (offset 32, 16 bytes)
                GPUVertexAttribute(format: .float32x4, offset: 32, shaderLocation: 5),
                // color (offset 48, 16 bytes)
                GPUVertexAttribute(format: .float32x4, offset: 48, shaderLocation: 6),
                // alpha (offset 64, 4 bytes)
                GPUVertexAttribute(format: .float32, offset: 64, shaderLocation: 7),
                // padding at offset 68 (12 bytes to reach stride of 80)
            ]
        )

        // Create textured sprite pipeline
        renderPipeline = device.createRenderPipeline(descriptor: GPURenderPipelineDescriptor(
            vertex: GPUVertexState(
                module: shaderModule,
                entryPoint: "vs_main",
                buffers: [vertexBufferLayout, instanceBufferLayout]
            ),
            primitive: GPUPrimitiveState(topology: .triangleList),
            fragment: GPUFragmentState(
                module: shaderModule,
                entryPoint: "fs_main",
                targets: [
                    GPUColorTargetState(
                        format: format,
                        blend: .premultipliedAlpha
                    )
                ]
            ),
            layout: .layout(pipelineLayout),
            label: "SpriteRenderPipeline"
        ))

        // Create solid color pipeline
        solidColorPipeline = device.createRenderPipeline(descriptor: GPURenderPipelineDescriptor(
            vertex: GPUVertexState(
                module: shaderModule,
                entryPoint: "vs_main",
                buffers: [vertexBufferLayout, instanceBufferLayout]
            ),
            primitive: GPUPrimitiveState(topology: .triangleList),
            fragment: GPUFragmentState(
                module: shaderModule,
                entryPoint: "fs_solid",
                targets: [
                    GPUColorTargetState(
                        format: format,
                        blend: .premultipliedAlpha
                    )
                ]
            ),
            layout: .layout(pipelineLayout),
            label: "SolidColorPipeline"
        ))
    }

    private func setupBuffers() {
        // Create quad vertex buffer
        let vertexData = SpriteShader.quadVertices
        quadVertexBuffer = device.createBuffer(descriptor: GPUBufferDescriptor(
            size: UInt64(vertexData.count * MemoryLayout<Float>.size),
            usage: [.vertex, .copyDst],
            label: "QuadVertexBuffer"
        ))

        // Upload vertex data
        vertexData.withUnsafeBytes { bytes in
            let float32Array = JSObject.global.Float32Array.function!.new(vertexData.count)
            for i in 0..<vertexData.count {
                float32Array[i] = .number(Double(vertexData[i]))
            }
            device.queue.writeBuffer(quadVertexBuffer, bufferOffset: 0, data: float32Array)
        }

        // Create instance buffer (sized for max sprites)
        let instanceBufferSize = UInt64(maxSpritesPerBatch) * SpriteShader.instanceStride
        instanceBuffer = device.createBuffer(descriptor: GPUBufferDescriptor(
            size: instanceBufferSize,
            usage: [.vertex, .copyDst],
            label: "InstanceBuffer"
        ))

        // Create uniform buffer (mat4x4 + vec2 + padding = 80 bytes, aligned to 256)
        uniformBuffer = device.createBuffer(descriptor: GPUBufferDescriptor(
            size: 256,
            usage: [.uniform, .copyDst],
            label: "UniformBuffer"
        ))

        // Initialize uniforms with orthographic projection
        updateUniforms()
    }

    // MARK: - Rendering

    /// Updates the uniform buffer with current view-projection matrix.
    private func updateUniforms() {
        // Create orthographic projection matrix
        // Maps (0,0)-(width,height) to (-1,-1)-(1,1)
        let left: Float = 0
        let right = CGFloat(canvasWidth)
        let bottom: Float = 0
        let top = CGFloat(canvasHeight)
        let near: Float = -1
        let far: Float = 1

        let ortho: [CGFloat] = [
            2.0 / (right - left), 0, 0, 0,
            0, 2.0 / (top - bottom), 0, 0,
            0, 0, -2.0 / (far - near), 0,
            -(right + left) / (right - left),
            -(top + bottom) / (top - bottom),
            -(far + near) / (far - near),
            1
        ]

        // Add screen size
        let uniforms = ortho + [CGFloat(canvasWidth), CGFloat(canvasHeight), 0, 0]

        let float32Array = JSObject.global.Float32Array.function!.new(uniforms.count)
        for i in 0..<uniforms.count {
            float32Array[i] = .number(Double(uniforms[i]))
        }
        device.queue.writeBuffer(uniformBuffer, bufferOffset: 0, data: float32Array)
    }

    /// Resizes the renderer to match the canvas size.
    ///
    /// - Parameters:
    ///   - width: New width in pixels.
    ///   - height: New height in pixels.
    public func resize(width: UInt32, height: UInt32) {
        canvasWidth = width
        canvasHeight = height
        updateUniforms()
    }

    /// Renders a frame with the given draw commands.
    ///
    /// - Parameters:
    ///   - commands: The draw commands to render.
    ///   - backgroundColor: The background clear color.
    func render(commands: [DrawCommand], backgroundColor: Color) {
        // Get current texture
        let currentTexture = context.getCurrentTexture()
        let textureView = currentTexture.createView()

        // Create command encoder
        let encoder = device.createCommandEncoder(descriptor: GPUCommandEncoderDescriptor(
            label: "FrameEncoder"
        ))

        // Begin render pass
        let renderPass = encoder.beginRenderPass(descriptor: GPURenderPassDescriptor(
            colorAttachments: [
                GPURenderPassColorAttachment(
                    view: textureView,
                    clearValue: GPUColor(
                        r: Double(backgroundColor.red),
                        g: Double(backgroundColor.green),
                        b: Double(backgroundColor.blue),
                        a: Double(backgroundColor.alpha)
                    ),
                    loadOp: .clear,
                    storeOp: .store
                )
            ],
            label: "MainRenderPass"
        ))

        // Batch and render sprites
        let batches = SpriteBatcher.batch(commands)

        for batch in batches {
            renderBatch(batch, renderPass: renderPass)
        }

        renderPass.end()

        // Submit commands
        let commandBuffer = encoder.finish()
        device.queue.submit([commandBuffer])
    }

    /// Renders a single batch of sprites.
    private func renderBatch(_ batch: SpriteBatch, renderPass: GPURenderPassEncoder) {
        guard !batch.instances.isEmpty else { return }

        // Upload instance data
        uploadInstanceData(batch.instances)

        // Get or create bind group for this texture
        let bindGroup = getBindGroup(for: batch.textureID)

        // Set pipeline based on whether we have a texture
        if batch.textureID == 0 {
            renderPass.setPipeline(solidColorPipeline)
        } else {
            renderPass.setPipeline(renderPipeline)
        }

        renderPass.setBindGroup(0, bindGroup: bindGroup)
        renderPass.setVertexBuffer(0, buffer: quadVertexBuffer)
        renderPass.setVertexBuffer(1, buffer: instanceBuffer)

        renderPass.draw(
            vertexCount: SpriteShader.verticesPerQuad,
            instanceCount: UInt32(batch.instances.count)
        )
    }

    /// Uploads instance data to the GPU buffer.
    private func uploadInstanceData(_ instances: [SpriteInstance]) {
        // Convert to flat float array
        // 20 floats per instance (80 bytes stride)
        var floatData: [CGFloat] = []
        floatData.reserveCapacity(instances.count * 20)

        for instance in instances {
            // position (offset 0, 8 bytes)
            floatData.append(instance.positionX)
            floatData.append(instance.positionY)
            // size (offset 8, 8 bytes)
            floatData.append(instance.sizeWidth)
            floatData.append(instance.sizeHeight)
            // rotation (offset 16, 4 bytes)
            floatData.append(instance.rotation)
            // padding (offset 20, 4 bytes)
            floatData.append(0)
            // anchor (offset 24, 8 bytes)
            floatData.append(instance.anchorX)
            floatData.append(instance.anchorY)
            // texRect (offset 32, 16 bytes)
            floatData.append(instance.texRectX)
            floatData.append(instance.texRectY)
            floatData.append(instance.texRectW)
            floatData.append(instance.texRectH)
            // color (offset 48, 16 bytes)
            floatData.append(instance.colorR)
            floatData.append(instance.colorG)
            floatData.append(instance.colorB)
            floatData.append(instance.colorA)
            // alpha (offset 64, 4 bytes)
            floatData.append(instance.alpha)
            // padding (offset 68, 12 bytes)
            floatData.append(0)
            floatData.append(0)
            floatData.append(0)
        }

        let float32Array = JSObject.global.Float32Array.function!.new(floatData.count)
        for i in 0..<floatData.count {
            float32Array[i] = .number(Double(floatData[i]))
        }
        device.queue.writeBuffer(instanceBuffer, bufferOffset: 0, data: float32Array)
    }

    /// Gets or creates a bind group for the given texture ID.
    private func getBindGroup(for textureID: UInt32) -> GPUBindGroup {
        if let cached = bindGroupCache[textureID] {
            return cached
        }

        let textureView = textureManager.getTextureView(for: textureID)

        let bindGroup = device.createBindGroup(descriptor: GPUBindGroupDescriptor(
            layout: bindGroupLayout,
            entries: [
                GPUBindGroupEntry(binding: 0, resource: .bufferBinding(GPUBufferBinding(buffer: uniformBuffer))),
                GPUBindGroupEntry(binding: 1, resource: .sampler(textureManager.defaultSampler)),
                GPUBindGroupEntry(binding: 2, resource: .textureView(textureView))
            ],
            label: "SpriteBindGroup_\(textureID)"
        ))

        bindGroupCache[textureID] = bindGroup
        return bindGroup
    }

    /// Invalidates the bind group cache for a texture.
    ///
    /// Call this when a texture is updated or removed.
    public func invalidateBindGroup(for textureID: UInt32) {
        bindGroupCache.removeValue(forKey: textureID)
    }

    /// Clears all cached bind groups.
    public func clearBindGroupCache() {
        bindGroupCache.removeAll()
    }
}

// MARK: - Errors

/// Errors that can occur during WebGPU renderer initialization.
public enum WebGPURendererError: Error {
    case webGPUNotSupported
    case noAdapterFound
    case deviceCreationFailed
}
#endif
