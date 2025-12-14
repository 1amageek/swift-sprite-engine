/// The root node of all Wisp content.
///
/// `SNScene` represents a single screen or level in your game. It manages
/// the update cycle, provides the coordinate system, and optionally uses
/// a camera to control the viewport.
///
/// `SNScene` inherits from `SNEffectNode`, meaning it can apply shaders and
/// warp geometry to the entire scene. It also has all the spatial and
/// hierarchy properties from `SNNode`.
///
/// ## Example
/// ```swift
/// class GameScene: SNScene {
///     var player: SNSpriteNode!
///
///     override func sceneDidLoad() {
///         player = SNSpriteNode(color: .blue, size: Size(width: 50, height: 50))
///         player.position = Point(x: size.width / 2, y: size.height / 2)
///         addChild(player)
///
///         let camera = SNCamera()
///         addChild(camera)
///         self.camera = camera
///     }
///
///     override func update(dt: Float) {
///         // Game logic here
///         camera?.position = player.position
///     }
/// }
///
/// let scene = GameScene(size: Size(width: 800, height: 600))
/// scene.scaleMode = .aspectFit
/// ```
///
/// ## Frame Cycle
/// ```
/// 1. update(dt:)           ← Your game logic
/// 2. didEvaluateActions()  ← After actions processed
/// 3. didSimulatePhysics()  ← After physics simulation
/// 4. didApplyConstraints() ← After constraints applied
/// 5. didFinishUpdate()     ← Final pre-render hook
/// 6. render()              ← Internal: draw commands
/// ```
///
/// ## Effect Node Features (inherited)
/// Since `SNScene` inherits from `SNEffectNode`, you can:
/// - Apply shaders to the entire scene via `shader`
/// - Use warp geometry via `warpGeometry`
/// - Cache static content via `shouldRasterize`
/// - Configure blending via `blendMode`
open class SNScene: SNEffectNode {
    // MARK: - Scene Configuration

    /// The dimensions of the scene in points.
    /// Defines the scene's coordinate space.
    public var size: Size

    /// Determines how the scene is scaled to fit the view.
    public var scaleMode: ScaleMode = .aspectFit

    /// The point in the view that corresponds to the scene's origin.
    /// Default: (0.5, 0.5) for center.
    /// Only used when no camera is assigned.
    public var anchorPoint: Point = Point(x: 0.5, y: 0.5)

    /// The background color of the scene.
    public var backgroundColor: Color = .black

    // MARK: - Camera

    /// The camera node that determines what portion of the scene is visible.
    /// When `nil`, the scene uses `anchorPoint` for viewport positioning.
    /// The camera must be added to the scene's node tree before being assigned.
    public var camera: SNCamera?

    // MARK: - Timing

    /// The fixed timestep for updates (default: 1/60 second).
    public var fixedTimestep: Float = 1.0 / 60.0

    // MARK: - Physics

    /// The physics world for this scene.
    public let physicsWorld: SNPhysicsWorld = SNPhysicsWorld()

    // MARK: - State

    /// Whether the scene is currently paused.
    public var isPaused: Bool = false

    /// Total elapsed simulation time in seconds.
    public private(set) var currentTime: Float = 0

    /// Current input state for this frame.
    public var input: InputState = InputState()

    // MARK: - Audio

    /// The audio system for this scene.
    ///
    /// Use this to play sound effects and music. Commands are collected
    /// during the frame and consumed by the audio runtime after the update loop.
    ///
    /// ## Usage
    /// ```swift
    /// // Play a sound effect
    /// audio.play(Sounds.explosion)
    ///
    /// // Play background music
    /// audio.playMusic(Sounds.bgmLevel1)
    /// ```
    public var audio: AudioSystem {
        get { audioEngine.audioSystem }
        set { audioEngine.audioSystem = newValue }
    }

    /// The audio engine used to play audio from audio nodes contained in the scene.
    ///
    /// The audio engine provides master control over all audio playback.
    /// Use it to control overall volume, pause/resume all audio, etc.
    ///
    /// ## Usage
    /// ```swift
    /// // Reduce the overall volume
    /// scene.audioEngine.mainMixerNode.outputVolume = 0.5
    ///
    /// // Pause all audio
    /// scene.audioEngine.pause()
    ///
    /// // Resume audio
    /// scene.audioEngine.start()
    /// ```
    public let audioEngine: AudioEngine = AudioEngine()

    /// A node used to determine the position of the listener for positional audio.
    ///
    /// When set, audio nodes in the scene are mixed with 2D positional characteristics.
    /// Audio from nodes further from the listener will be quieter.
    ///
    /// A common pattern is to set the listener to the camera:
    /// ```swift
    /// scene.listener = scene.camera
    /// ```
    ///
    /// - Note: If `nil`, all audio is played without positional effects.
    public weak var listener: SNNode?

    // MARK: - Delegate

    /// A delegate that is called during the animation loop.
    ///
    /// If the delegate implements a particular method, that method is called
    /// instead of the corresponding method on the scene.
    public weak var delegate: SNSceneDelegate?

    // MARK: - View Reference

    /// The view that is currently presenting the scene.
    ///
    /// This property is set automatically when the scene is presented
    /// via `SNView.presentScene(_:)`.
    public internal(set) weak var view: SNView?

    // MARK: - Initialization

    /// Creates a scene with the specified size.
    ///
    /// - Parameter size: The logical size of the scene in points.
    public init(size: Size) {
        self.size = size
        super.init()
        self.scene = self  // Scene is its own scene reference
        self.physicsWorld.scene = self
    }

    /// Creates a scene with zero size.
    /// The size should be set before presenting the scene.
    public override init() {
        self.size = .zero
        super.init()
        self.scene = self
        self.physicsWorld.scene = self
    }

    // MARK: - Lifecycle

    /// Called immediately after the scene is initialized.
    /// Override to perform one-time setup.
    open func sceneDidLoad() {
        // Override in subclasses
    }

    /// Called when the scene is presented in a view.
    /// Override to start gameplay.
    ///
    /// - Parameter view: The view presenting this scene.
    open func didMove(to view: SNView) {
        // Override in subclasses
    }

    /// Called when the scene is about to be removed from a view.
    /// Override to clean up resources.
    ///
    /// - Parameter view: The view that was presenting this scene.
    open func willMove(from view: SNView) {
        // Override in subclasses
    }

    /// Called when the scene's size has changed.
    ///
    /// Override this method to respond to size changes, such as device rotation
    /// or window resizing. You might need to reposition nodes or update
    /// the camera to accommodate the new size.
    ///
    /// - Parameter oldSize: The previous size of the scene.
    open func didChangeSize(_ oldSize: Size) {
        // Override in subclasses
    }

    /// Changes the scene's size and notifies via `didChangeSize(_:)`.
    ///
    /// - Parameter newSize: The new size for the scene.
    public func resize(to newSize: Size) {
        let oldSize = size
        size = newSize
        if let delegate = delegate {
            delegate.didChangeSize(oldSize, for: self)
        } else {
            didChangeSize(oldSize)
        }
    }

    // MARK: - Frame Cycle

    /// Called every frame to update game logic.
    ///
    /// - Parameter dt: The fixed timestep interval (typically 1/60 second).
    ///
    /// Override this method to implement your game logic. The base
    /// implementation updates all child nodes recursively.
    open override func update(dt: Float) {
        // Update all children
        for child in children {
            child.updateRecursive(dt: dt)
        }
    }

    /// Called after scene actions have been evaluated.
    ///
    /// Override to perform logic that depends on action results.
    open func didEvaluateActions() {
        // Override in subclasses
    }

    /// Called after physics simulations have been performed.
    ///
    /// Override to perform logic that depends on physics results.
    open func didSimulatePhysics() {
        // Override in subclasses
    }

    /// Called after constraints have been applied.
    ///
    /// Override to perform logic that depends on constraint results.
    open func didApplyConstraints() {
        // Override in subclasses
    }

    /// Called after all update processing is complete.
    ///
    /// Override for post-processing. This is the last chance to modify
    /// nodes before rendering.
    open func didFinishUpdate() {
        // Override in subclasses
    }

    /// Processes a single frame with the given delta time.
    ///
    /// This method is called by the game loop and handles the full frame cycle:
    /// 1. Skipping if paused
    /// 2. Incrementing currentTime
    /// 3. Calling update(dt:)
    /// 4. Evaluating actions on all nodes
    /// 5. Calling didEvaluateActions()
    /// 6. Physics simulation
    /// 7. Calling didSimulatePhysics()
    /// 8. Applying constraints
    /// 9. Calling didApplyConstraints()
    /// 10. Calling didFinishUpdate()
    ///
    /// If a delegate is set, delegate methods are called instead of scene methods.
    ///
    /// - Parameter dt: The delta time (typically the fixed timestep).
    public func processFrame(dt: Float) {
        guard !isPaused else { return }

        // Clear audio command buffer for this frame
        audioEngine.beginFrame()

        currentTime += dt

        // 1. User update
        if let delegate = delegate {
            delegate.update(dt, for: self)
        } else {
            update(dt: dt)
        }

        // 2. Evaluate actions on all nodes
        evaluateActions(dt: dt)

        // 3. Post-actions callback
        if let delegate = delegate {
            delegate.didEvaluateActions(for: self)
        } else {
            didEvaluateActions()
        }

        // 4. Physics simulation
        physicsWorld.simulate(dt: dt)

        // 5. Post-physics callback
        if let delegate = delegate {
            delegate.didSimulatePhysics(for: self)
        } else {
            didSimulatePhysics()
        }

        // 6. Apply constraints
        applyConstraints()

        // 7. Post-constraints callback
        if let delegate = delegate {
            delegate.didApplyConstraints(for: self)
        } else {
            didApplyConstraints()
        }

        // 8. Final update callback
        if let delegate = delegate {
            delegate.didFinishUpdate(for: self)
        } else {
            didFinishUpdate()
        }
    }

    /// Applies constraints to all nodes in the scene.
    private func applyConstraints() {
        applyConstraintsRecursive(on: self)
    }

    private func applyConstraintsRecursive(on node: SNNode) {
        // Apply constraints on this node
        if let constraints = node.constraints {
            for constraint in constraints where constraint.isEnabled {
                constraint.apply(to: node)
            }
        }

        // Recurse into children
        for child in node.children {
            applyConstraintsRecursive(on: child)
        }
    }

    /// Recursively evaluates actions on all nodes.
    private func evaluateActions(dt: Float) {
        evaluateActionsRecursive(on: self, dt: dt)
    }

    private func evaluateActionsRecursive(on node: SNNode, dt: Float) {
        // Evaluate actions on this node
        var completedKeys: [String] = []
        for (key, action) in node.actions {
            if action.evaluate(on: node, dt: dt) {
                completedKeys.append(key)
            }
        }
        for key in completedKeys {
            node.actions.removeValue(forKey: key)
        }

        // Recurse into children
        for child in node.children {
            evaluateActionsRecursive(on: child, dt: dt)
        }
    }

    /// Resets the scene's time to zero.
    public func resetTime() {
        currentTime = 0
    }

    // MARK: - Draw Command Generation

    /// Generates draw commands for all visible nodes in the scene.
    ///
    /// This method traverses the scene graph, collects draw commands from
    /// all visible sprites, tile maps, and labels, and sorts them by z-position.
    ///
    /// - Returns: An array of draw commands sorted by z-position.
    internal func generateDrawCommands() -> [DrawCommand] {
        var commands: [DrawCommand] = []
        let viewport = calculateViewport()
        collectDrawCommands(from: self, into: &commands, viewport: viewport)
        commands.sort { $0.zPosition < $1.zPosition }
        return commands
    }

    /// Generates label draw commands for all visible labels.
    ///
    /// - Returns: An array of label draw commands sorted by z-position.
    public func generateLabelDrawCommands() -> [LabelDrawCommand] {
        var commands: [LabelDrawCommand] = []
        collectLabelDrawCommands(from: self, into: &commands)
        commands.sort { $0.zPosition < $1.zPosition }
        return commands
    }

    /// Recursively collects draw commands from a node and its descendants.
    private func collectDrawCommands(from node: SNNode, into commands: inout [DrawCommand], viewport: Rect) {
        // Skip hidden nodes
        guard !node.isHidden else { return }

        // Generate command for sprites
        if let sprite = node as? SNSpriteNode, sprite.alpha > 0 {
            commands.append(sprite.makeDrawCommand())
        }

        // Generate commands for tile maps
        if let tileMap = node as? SNTileMap, tileMap.alpha > 0 {
            // Transform viewport to tile map's local coordinate space
            let localViewport = Rect(
                x: viewport.origin.x - tileMap.position.x,
                y: viewport.origin.y - tileMap.position.y,
                width: viewport.size.width,
                height: viewport.size.height
            )
            commands.append(contentsOf: tileMap.generateDrawCommands(visibleRect: localViewport))
        }

        // Recurse into children
        for child in node.children {
            collectDrawCommands(from: child, into: &commands, viewport: viewport)
        }
    }

    /// Recursively collects label draw commands from a node and its descendants.
    private func collectLabelDrawCommands(from node: SNNode, into commands: inout [LabelDrawCommand]) {
        // Skip hidden nodes
        guard !node.isHidden else { return }

        // Generate command for labels
        if let label = node as? SNLabelNode, label.alpha > 0 {
            commands.append(label.makeDrawCommand())
        }

        // Recurse into children
        for child in node.children {
            collectLabelDrawCommands(from: child, into: &commands)
        }
    }

    // MARK: - Viewport Calculation

    /// Calculates the viewport rectangle in scene coordinates.
    ///
    /// If a camera is assigned, uses the camera's position and scale.
    /// Otherwise, uses the scene's anchor point.
    ///
    /// - Returns: The visible area in scene coordinates.
    public func calculateViewport() -> Rect {
        if let camera = camera {
            return camera.viewport(for: size)
        } else {
            // Use anchor point to determine viewport
            return Rect(
                x: -size.width * anchorPoint.x,
                y: -size.height * anchorPoint.y,
                width: size.width,
                height: size.height
            )
        }
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// - Parameters:
    ///   - point: The point in view coordinates.
    ///   - viewSize: The size of the view.
    /// - Returns: The point in scene coordinates.
    public func convertPoint(fromView point: Point, viewSize: Size) -> Point {
        // Calculate scale based on scale mode
        let scaleX: Float
        let scaleY: Float

        switch scaleMode {
        case .fill:
            scaleX = size.width / viewSize.width
            scaleY = size.height / viewSize.height
        case .aspectFit:
            let scale = min(viewSize.width / size.width, viewSize.height / size.height)
            scaleX = 1 / scale
            scaleY = 1 / scale
        case .aspectFill:
            let scale = max(viewSize.width / size.width, viewSize.height / size.height)
            scaleX = 1 / scale
            scaleY = 1 / scale
        case .resizeFill:
            scaleX = 1
            scaleY = 1
        }

        // Convert view point to scene point
        var scenePoint = Point(
            x: (point.x - viewSize.width / 2) * scaleX,
            y: (point.y - viewSize.height / 2) * scaleY
        )

        // Apply camera transform if present
        if let camera = camera {
            scenePoint.x = scenePoint.x / camera.scale.width + camera.position.x
            scenePoint.y = scenePoint.y / camera.scale.height + camera.position.y
        } else {
            scenePoint.x += size.width * anchorPoint.x
            scenePoint.y += size.height * anchorPoint.y
        }

        return scenePoint
    }

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// - Parameters:
    ///   - point: The point in scene coordinates.
    ///   - viewSize: The size of the view.
    /// - Returns: The point in view coordinates.
    public func convertPoint(toView point: Point, viewSize: Size) -> Point {
        var viewPoint = point

        // Apply camera transform if present
        if let camera = camera {
            viewPoint.x = (viewPoint.x - camera.position.x) * camera.scale.width
            viewPoint.y = (viewPoint.y - camera.position.y) * camera.scale.height
        } else {
            viewPoint.x -= size.width * anchorPoint.x
            viewPoint.y -= size.height * anchorPoint.y
        }

        // Calculate scale based on scale mode
        let scaleX: Float
        let scaleY: Float

        switch scaleMode {
        case .fill:
            scaleX = viewSize.width / size.width
            scaleY = viewSize.height / size.height
        case .aspectFit:
            let scale = min(viewSize.width / size.width, viewSize.height / size.height)
            scaleX = scale
            scaleY = scale
        case .aspectFill:
            let scale = max(viewSize.width / size.width, viewSize.height / size.height)
            scaleX = scale
            scaleY = scale
        case .resizeFill:
            scaleX = 1
            scaleY = 1
        }

        return Point(
            x: viewPoint.x * scaleX + viewSize.width / 2,
            y: viewPoint.y * scaleY + viewSize.height / 2
        )
    }

    // MARK: - Scene Graph Override

    /// Scenes set themselves as the scene reference for added children.
    public override func addChild(_ node: SNNode) {
        super.addChild(node)
        node.propagateScene(self)
    }

    public override func insertChild(_ node: SNNode, at index: Int) {
        super.insertChild(node, at: index)
        node.propagateScene(self)
    }

    // MARK: - CustomStringConvertible

    open override var description: String {
        let nameStr = name.map { "\"\($0)\"" } ?? "unnamed"
        return "SNScene(\(nameStr), size: \(size), children: \(children.count))"
    }
}
