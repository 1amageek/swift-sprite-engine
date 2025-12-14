/// A renderer that draws scenes to render targets.
///
/// `Renderer` is the cross-platform equivalent of SpriteKit's `SKRenderer`.
/// It can render scenes to textures for offscreen rendering or to
/// a view's drawable for on-screen display.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKRenderer                      Renderer
/// SKRenderer(device:)             Renderer(device:)
/// render(atTime:viewport:...)     render(scene:atTime:viewport:...)
/// ```
///
/// ## Usage
/// ```swift
/// // Create renderer
/// let renderer = Renderer(device: device)
///
/// // Render to texture
/// let texture = device.makeTexture(descriptor: descriptor)
/// renderer.render(
///     scene: gameScene,
///     atTime: currentTime,
///     viewport: Viewport(x: 0, y: 0, width: 800, height: 600),
///     commandBuffer: commandBuffer,
///     renderPassDescriptor: passDescriptor
/// )
/// ```
public final class Renderer: @unchecked Sendable {
    // MARK: - Properties

    /// The graphics device used for rendering.
    public let device: any GraphicsDevice

    /// Whether to ignore sibling order for z-sorting.
    ///
    /// When `true`, nodes are sorted only by `zPosition`.
    /// When `false`, sibling order is used as a tiebreaker.
    public var ignoresSiblingOrder: Bool = false

    /// Whether to show draw count diagnostics.
    public var showsDrawCount: Bool = false

    /// Whether to show node count diagnostics.
    public var showsNodeCount: Bool = false

    /// Whether to show FPS diagnostics.
    public var showsFPS: Bool = false

    /// Whether to show quad count diagnostics.
    ///
    /// Displays the number of rectangles used to render the scene.
    public var showsQuadCount: Bool = false

    /// Whether to show physics bodies for debugging.
    ///
    /// When enabled, displays an overlay showing physics bodies
    /// that are visible in the scene.
    public var showsPhysics: Bool = false

    /// Whether to show physics fields for debugging.
    ///
    /// When enabled, displays information about physics fields in the scene.
    public var showsFields: Bool = false

    /// Whether to cull nodes that are not visible.
    ///
    /// When `true`, nodes outside the viewport are not rendered.
    /// This can improve performance for large scenes.
    public var shouldCullNonVisibleNodes: Bool = true

    /// The currently assigned scene.
    public private(set) weak var scene: SNScene?

    // MARK: - Internal State

    /// The render pipeline for sprites.
    private var spritePipeline: (any GraphicsRenderPipeline)?

    /// The render pipeline for shapes.
    private var shapePipeline: (any GraphicsRenderPipeline)?

    /// Vertex buffer for batched sprites.
    private var spriteVertexBuffer: (any GraphicsBuffer)?

    /// Index buffer for sprites.
    private var spriteIndexBuffer: (any GraphicsBuffer)?

    /// Current draw call count.
    private var drawCount: Int = 0

    /// Current node count.
    private var nodeCount: Int = 0

    /// Current quad count.
    private var quadCount: Int = 0

    /// Last update time for frame calculations.
    private var lastUpdateTime: Double = 0

    /// Time accumulator for fixed timestep updates.
    private var accumulator: Float = 0

    /// Fixed timestep for deterministic updates (default: 1/60 second).
    public var fixedTimestep: Float = 1.0 / 60.0

    /// Maximum time to process per frame to prevent spiral of death.
    public var maxFrameTime: Float = 0.25

    // MARK: - Initialization

    /// Creates a renderer with the specified device.
    ///
    /// - Parameter device: The graphics device to use.
    public init(device: any GraphicsDevice) {
        self.device = device
        setupPipelines()
    }

    // MARK: - Scene Management

    /// Updates the renderer's scene.
    ///
    /// - Parameter scene: The scene to render.
    public func update(scene: SNScene) {
        self.scene = scene
    }

    // MARK: - Update Cycle

    /// Drives the scene's update cycle at the specified time.
    ///
    /// This method uses a fixed timestep accumulator to ensure deterministic updates.
    /// It calls the scene's delegate functions in the proper order:
    /// 1. `update(currentTime:)` - Called first to allow game logic
    /// 2. Actions are evaluated
    /// 3. Physics simulation runs
    /// 4. Constraints are applied
    ///
    /// Call this method before rendering to advance the scene's simulation.
    ///
    /// - Parameter time: The current time, in seconds.
    ///
    /// ## Platform Mapping
    /// - SpriteKit: `SKRenderer.update(atTime:)`
    public func update(atTime time: Double) {
        guard let scene = scene else { return }

        // Calculate delta time
        let dt: Float
        if lastUpdateTime > 0 {
            dt = Float(time - lastUpdateTime)
        } else {
            dt = fixedTimestep
        }
        lastUpdateTime = time

        // Clamp to prevent spiral of death
        let frameTime = min(dt, maxFrameTime)
        accumulator += frameTime

        // Fixed timestep updates for deterministic behavior
        while accumulator >= fixedTimestep {
            scene.processFrame(dt: fixedTimestep)
            accumulator -= fixedTimestep
        }
    }

    // MARK: - Rendering

    /// Renders the scene at the specified time.
    ///
    /// This method renders the current scene into the provided command buffer.
    /// The scene is not updated; call `update(atTime:)` before rendering to
    /// advance the scene's simulation.
    ///
    /// - Parameters:
    ///   - viewport: The viewport rectangle defining the render area.
    ///   - commandBuffer: The command buffer to record rendering commands to.
    ///   - passDescriptor: The render pass configuration.
    ///
    /// ## Platform Mapping
    /// - SpriteKit: `SKRenderer.render(withViewport:commandBuffer:renderPassDescriptor:)`
    ///
    /// ## Usage
    /// ```swift
    /// // Update the scene first
    /// renderer.update(atTime: currentTime)
    ///
    /// // Then render
    /// renderer.render(
    ///     withViewport: viewport,
    ///     commandBuffer: commandBuffer,
    ///     renderPassDescriptor: passDescriptor
    /// )
    /// ```
    public func render(
        withViewport viewport: Viewport,
        commandBuffer: any GraphicsCommandBuffer,
        renderPassDescriptor: RenderPassDescriptor
    ) {
        guard let scene = scene else { return }

        drawCount = 0
        nodeCount = 0
        quadCount = 0

        // Collect visible nodes
        let visibleNodes = collectVisibleNodes(scene: scene, viewport: viewport)
        nodeCount = visibleNodes.count

        // Sort nodes by z-order
        let sortedNodes = sortNodes(visibleNodes)

        // Create command encoder
        let encoder = device.makeCommandEncoder()

        // Begin render pass
        let renderPass = encoder.beginRenderPass(descriptor: renderPassDescriptor)
        renderPass.setViewport(viewport)

        // Render each node
        for node in sortedNodes {
            renderNode(node, renderPass: renderPass, scene: scene)
        }

        // Render debug overlays if enabled
        if showsPhysics {
            renderPhysicsDebug(renderPass: renderPass, scene: scene)
        }

        if showsFields {
            renderFieldsDebug(renderPass: renderPass, scene: scene)
        }

        // End render pass
        renderPass.end()

        // Finish and submit
        let buffer = encoder.finish()
        device.commandQueue.submit(buffer)
    }

    /// Renders the scene using a provided render command encoder.
    ///
    /// Use this method when you need to integrate SpriteKit-style rendering
    /// into an existing rendering pipeline. This allows layering Wisp content
    /// at a specific z-position within a custom rendering setup.
    ///
    /// - Parameters:
    ///   - viewport: The viewport rectangle defining the render area.
    ///   - renderCommandEncoder: An existing render command encoder to use.
    ///   - passDescriptor: The render pass configuration.
    ///   - commandQueue: The command queue for submitting work.
    ///
    /// ## Platform Mapping
    /// - SpriteKit: `SKRenderer.render(withViewport:renderCommandEncoder:renderPassDescriptor:commandQueue:)`
    public func render(
        withViewport viewport: Viewport,
        renderCommandEncoder: any GraphicsRenderPassEncoder,
        renderPassDescriptor: RenderPassDescriptor,
        commandQueue: any GraphicsCommandQueue
    ) {
        guard let scene = scene else { return }

        drawCount = 0
        nodeCount = 0
        quadCount = 0

        // Collect visible nodes
        let visibleNodes = collectVisibleNodes(scene: scene, viewport: viewport)
        nodeCount = visibleNodes.count

        // Sort nodes by z-order
        let sortedNodes = sortNodes(visibleNodes)

        // Set viewport on the provided encoder
        renderCommandEncoder.setViewport(viewport)

        // Render each node using the provided encoder
        for node in sortedNodes {
            renderNode(node, renderPass: renderCommandEncoder, scene: scene)
        }

        // Render debug overlays if enabled
        if showsPhysics {
            renderPhysicsDebug(renderPass: renderCommandEncoder, scene: scene)
        }

        if showsFields {
            renderFieldsDebug(renderPass: renderCommandEncoder, scene: scene)
        }
    }

    /// Renders the scene at the specified time (convenience method).
    ///
    /// This method combines update and render into a single call.
    /// For more control, use `update(atTime:)` followed by `render(withViewport:...)`.
    ///
    /// - Parameters:
    ///   - scene: The scene to render (updates the renderer's scene).
    ///   - time: The current simulation time.
    ///   - viewport: The viewport to render to.
    ///   - commandBuffer: The command buffer to record to.
    ///   - passDescriptor: The render pass configuration.
    public func render(
        scene: SNScene,
        atTime time: Double,
        viewport: Viewport,
        commandBuffer: any GraphicsCommandBuffer,
        renderPassDescriptor: RenderPassDescriptor
    ) {
        self.scene = scene
        update(atTime: time)
        render(
            withViewport: viewport,
            commandBuffer: commandBuffer,
            renderPassDescriptor: renderPassDescriptor
        )
    }

    /// Renders the scene to the current drawable (convenience method).
    ///
    /// This method combines update and render into a single call,
    /// targeting a drawable texture view.
    ///
    /// - Parameters:
    ///   - scene: The scene to render.
    ///   - time: The current simulation time.
    ///   - viewport: The viewport dimensions.
    ///   - drawable: The drawable texture view.
    ///   - passDescriptor: The render pass configuration.
    public func render(
        scene: SNScene,
        atTime time: Double,
        viewport: Viewport,
        drawable: any GraphicsTextureView,
        passDescriptor: RenderPassDescriptor
    ) {
        var descriptor = passDescriptor
        if descriptor.colorAttachments.isEmpty {
            descriptor.colorAttachments.append(RenderPassColorAttachment())
        }
        descriptor.colorAttachments[0].texture = drawable

        render(
            scene: scene,
            atTime: time,
            viewport: viewport,
            commandBuffer: device.makeCommandEncoder().finish(),
            renderPassDescriptor: descriptor
        )
    }

    // MARK: - Private Methods

    private func setupPipelines() {
        // Setup will be implemented by platform-specific code
        // This creates the sprite and shape rendering pipelines
    }

    private func collectVisibleNodes(scene: SNScene, viewport: Viewport) -> [SNNode] {
        var nodes: [SNNode] = []

        func traverse(_ node: SNNode) {
            // Skip invisible nodes
            guard !node.isHidden && node.alpha > 0 else { return }

            // Check if node is within viewport (culling)
            if shouldCullNonVisibleNodes {
                let worldTransform = node.calculateRenderTransform()
                if !isNodeVisible(node, transform: worldTransform, viewport: viewport) {
                    return
                }
            }

            // Add renderable nodes
            if node is SNSpriteNode || node is SNShapeNode {
                nodes.append(node)
            }

            // Traverse children
            for child in node.children {
                traverse(child)
            }
        }

        traverse(scene)
        return nodes
    }

    private func isNodeVisible(_ node: SNNode, transform: RenderTransform, viewport: Viewport) -> Bool {
        // Get node bounds in world space
        let size: Size
        if let sprite = node as? SNSpriteNode {
            size = sprite.size
        } else if node is SNShapeNode {
            // Approximate bounds from path
            size = Size(width: 100, height: 100) // TODO: Calculate from path bounds
        } else {
            // Non-renderable nodes are always "visible" for traversal
            return true
        }

        // Calculate scaled size
        let scaledWidth = size.width * transform.scale.width
        let scaledHeight = size.height * transform.scale.height

        // Simple AABB intersection test
        let nodeLeft = transform.position.x - scaledWidth / 2
        let nodeRight = transform.position.x + scaledWidth / 2
        let nodeBottom = transform.position.y - scaledHeight / 2
        let nodeTop = transform.position.y + scaledHeight / 2

        let viewLeft = viewport.x
        let viewRight = viewport.x + viewport.width
        let viewBottom = viewport.y
        let viewTop = viewport.y + viewport.height

        return nodeRight >= viewLeft &&
               nodeLeft <= viewRight &&
               nodeTop >= viewBottom &&
               nodeBottom <= viewTop
    }

    private func sortNodes(_ nodes: [SNNode]) -> [SNNode] {
        if ignoresSiblingOrder {
            return nodes.sorted { $0.zPosition < $1.zPosition }
        } else {
            // Sort by z-position, then by tree order
            return nodes.sorted { lhs, rhs in
                if lhs.zPosition != rhs.zPosition {
                    return lhs.zPosition < rhs.zPosition
                }
                // Use sibling order as tiebreaker
                return nodeTreeOrder(lhs) < nodeTreeOrder(rhs)
            }
        }
    }

    private func nodeTreeOrder(_ node: SNNode) -> Int {
        // Calculate tree order based on parent hierarchy
        var order = 0
        var current: SNNode? = node
        var multiplier = 1

        while let parent = current?.parent {
            if let index = parent.children.firstIndex(where: { $0 === current }) {
                order += index * multiplier
            }
            multiplier *= 1000 // Assume max 1000 siblings
            current = parent
        }

        return order
    }

    private func renderNode(_ node: SNNode, renderPass: any GraphicsRenderPassEncoder, scene: SNScene) {
        // Calculate world transform
        let worldTransform = node.calculateRenderTransform()

        if let sprite = node as? SNSpriteNode {
            renderSprite(sprite, transform: worldTransform, renderPass: renderPass)
        } else if let shape = node as? SNShapeNode {
            renderSNShapeNode(shape, transform: worldTransform, renderPass: renderPass)
        }

        drawCount += 1
    }

    private func renderSprite(_ sprite: SNSpriteNode, transform: RenderTransform, renderPass: any GraphicsRenderPassEncoder) {
        guard let pipeline = spritePipeline else { return }

        renderPass.setPipeline(pipeline)

        // Setup vertex data for sprite quad
        // This will be implemented with actual vertex buffer updates

        renderPass.draw(vertexCount: 6) // Two triangles
        quadCount += 1 // Each sprite is one quad
    }

    private func renderSNShapeNode(_ shape: SNShapeNode, transform: RenderTransform, renderPass: any GraphicsRenderPassEncoder) {
        guard let pipeline = shapePipeline else { return }

        renderPass.setPipeline(pipeline)

        // Setup vertex data based on shape path
        // This will be implemented with actual vertex buffer updates

        // renderPass.draw(vertexCount: vertexCount)
    }

    // MARK: - Debug Rendering

    private func renderPhysicsDebug(renderPass: any GraphicsRenderPassEncoder, scene: SNScene) {
        // Render physics body outlines for debugging
        // This traverses all nodes and draws their physics body shapes
        func traversePhysics(_ node: SNNode) {
            if let body = node.physicsBody {
                let worldTransform = node.calculateRenderTransform()
                renderSNPhysicsBody(body, transform: worldTransform, renderPass: renderPass)
            }

            for child in node.children {
                traversePhysics(child)
            }
        }

        traversePhysics(scene)
    }

    private func renderSNPhysicsBody(_ body: SNPhysicsBody, transform: RenderTransform, renderPass: any GraphicsRenderPassEncoder) {
        // Draw physics body outline
        // The actual implementation would use a debug line pipeline
        // to render the body's shape (circle, rectangle, polygon, etc.)

        // This is a placeholder - actual implementation depends on physics body shape
        drawCount += 1
    }

    private func renderFieldsDebug(renderPass: any GraphicsRenderPassEncoder, scene: SNScene) {
        // Render physics field visualizations for debugging
        // This would draw field regions with their influence areas
        func traverseFields(_ node: SNNode) {
            if let fieldNode = node as? SNFieldNode {
                let worldTransform = node.calculateRenderTransform()
                renderSNFieldNode(fieldNode, transform: worldTransform, renderPass: renderPass)
            }

            for child in node.children {
                traverseFields(child)
            }
        }

        traverseFields(scene)
    }

    private func renderSNFieldNode(_ field: SNFieldNode, transform: RenderTransform, renderPass: any GraphicsRenderPassEncoder) {
        // Draw field visualization
        // The actual implementation would render the field's region
        // and possibly directional indicators

        // This is a placeholder - actual implementation depends on field type
        drawCount += 1
    }

    // MARK: - Diagnostics

    /// Returns the current draw count.
    public var currentDrawCount: Int { drawCount }

    /// Returns the current node count.
    public var currentNodeCount: Int { nodeCount }

    /// Returns the current quad count.
    public var currentQuadCount: Int { quadCount }
}

// MARK: - Render Transform

/// A 2D transformation for rendering.
public struct RenderTransform: Sendable {
    /// The position component.
    public var position: Point

    /// The rotation in radians.
    public var rotation: Float

    /// The scale component.
    public var scale: Size

    public init(position: Point = .zero, rotation: Float = 0, scale: Size = Size(width: 1, height: 1)) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    /// Identity transform.
    public static let identity = RenderTransform()

    /// Combines this transform with another.
    public func concatenating(_ other: RenderTransform) -> RenderTransform {
        // Simplified concatenation - full implementation would use matrix math
        let cosR = cos(rotation)
        let sinR = sin(rotation)

        let rotatedX = other.position.x * cosR - other.position.y * sinR
        let rotatedY = other.position.x * sinR + other.position.y * cosR

        return RenderTransform(
            position: Point(
                x: position.x + rotatedX * scale.width,
                y: position.y + rotatedY * scale.height
            ),
            rotation: rotation + other.rotation,
            scale: Size(
                width: scale.width * other.scale.width,
                height: scale.height * other.scale.height
            )
        )
    }

    /// Converts to a 4x4 matrix for GPU.
    public func toMatrix4x4() -> [Float] {
        let cosR = cos(rotation)
        let sinR = sin(rotation)

        return [
            scale.width * cosR,  scale.width * sinR,   0, 0,
            -scale.height * sinR, scale.height * cosR, 0, 0,
            0,                    0,                   1, 0,
            position.x,           position.y,          0, 1
        ]
    }
}

// MARK: - Transform Helper

extension SNNode {
    /// Calculates the render transform by combining parent transforms.
    func calculateRenderTransform() -> RenderTransform {
        var transform = RenderTransform(
            position: position,
            rotation: rotation,
            scale: scale
        )

        if let parent = parent {
            let parentTransform = parent.calculateRenderTransform()
            transform = parentTransform.concatenating(transform)
        }

        return transform
    }
}

// Math functions are defined in Vector2.swift
