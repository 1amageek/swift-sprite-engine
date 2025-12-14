/// A view that renders SpriteKit-like content.
///
/// `SNView` is the equivalent of `SKView` in SpriteKit. It manages scene presentation,
/// the update cycle, and provides configuration for rendering and debugging.
///
/// ## Usage
/// ```swift
/// let view = SNView()
/// view.presentScene(myScene)
///
/// // With transition
/// let transition = SNTransition.crossFade(duration: 1.0)
/// view.presentScene(newScene, transition: transition)
/// ```
///
/// ## Frame Cycle
/// Each frame, the view:
/// 1. Calls delegate's `view(_:shouldRenderAtTime:)` if set
/// 2. Updates the scene if not paused
/// 3. Renders the scene
///
/// ## Debug Options
/// ```swift
/// view.showsFPS = true
/// view.showsNodeCount = true
/// view.showsPhysics = true
/// ```
public final class SNView: @unchecked Sendable {
    // MARK: - Scene Display

    /// The scene currently presented by this view.
    public private(set) var scene: SNScene?

    /// Presents a scene.
    ///
    /// When a new scene is presented, the view:
    /// 1. Calls `willMove(from:)` on the old scene
    /// 2. Updates the scene reference
    /// 3. Calls `sceneDidLoad()` on the new scene
    /// 4. Calls `didMove(to:)` on the new scene
    ///
    /// - Parameter scene: The scene to present, or `nil` to remove the current scene.
    public func presentScene(_ scene: SNScene?) {
        if let scene = scene {
            presentScene(scene, transition: nil)
        } else {
            // Remove current scene
            self.scene?.willMove(from: self)
            self.scene?.view = nil
            self.scene = nil
            outgoingScene = nil
            incomingScene = nil
            activeTransition = nil
        }
    }

    /// Transitions from the current scene to a new scene.
    ///
    /// The transition animates the change from the old scene to the new scene.
    /// During the transition:
    /// - Both scenes may be rendered (depending on transition type)
    /// - Scene updates continue unless paused by the transition
    ///
    /// - Parameters:
    ///   - scene: The new scene to present.
    ///   - transition: The transition to use, or `nil` for immediate switch.
    public func presentScene(_ scene: SNScene, transition: SNTransition?) {
        if let transition = transition, self.scene != nil {
            // Start transition
            outgoingScene = self.scene
            incomingScene = scene
            activeTransition = transition
            transitionProgress = 0
            transitionAccumulator = 0

            // Setup incoming scene
            scene.view = self
            scene.sceneDidLoad()

            // Apply pause settings
            if transition.pausesIncomingScene {
                scene.isPaused = true
            }
            if transition.pausesOutgoingScene, let outgoing = outgoingScene {
                outgoing.isPaused = true
            }
        } else {
            // Immediate scene change
            self.scene?.willMove(from: self)
            self.scene?.view = nil

            self.scene = scene
            scene.view = self

            // Synchronize with GameLoop
            gameLoop.scene = scene
            gameLoop.accumulator = 0

            scene.sceneDidLoad()
            scene.didMove(to: self)

            // Clear any transition state
            outgoingScene = nil
            incomingScene = nil
            activeTransition = nil
        }
    }

    // MARK: - Transition State

    /// The scene being transitioned from.
    private var outgoingScene: SNScene?

    /// The scene being transitioned to.
    private var incomingScene: SNScene?

    /// The active transition, if any.
    private var activeTransition: SNTransition?

    /// Progress of the current transition (0 to 1).
    private var transitionProgress: Float = 0

    /// Time accumulator for fixed timestep updates during transitions.
    private var transitionAccumulator: Float = 0

    /// Whether a transition is currently in progress.
    public var isTransitioning: Bool {
        activeTransition != nil
    }

    // MARK: - Timing Control

    /// A Boolean value that indicates whether the view's scene animations are paused.
    ///
    /// When `true`, the scene's `update(_:)` method is not called and
    /// actions are not evaluated. Rendering continues.
    public var isPaused: Bool {
        get { scene?.isPaused ?? false }
        set { scene?.isPaused = newValue }
    }

    /// The preferred frame rate for the view.
    ///
    /// The view attempts to render at this rate. The actual rate may be lower
    /// if the device cannot maintain the requested rate.
    ///
    /// Default: 60
    public var preferredFramesPerSecond: Int = 60

    /// The fixed timestep used for game updates.
    ///
    /// Default: 1/60 second
    public var fixedTimestep: Float {
        get { gameLoop.fixedTimestep }
        set { gameLoop.fixedTimestep = newValue }
    }

    /// A delegate that allows dynamic control of the view's render rate.
    public weak var delegate: SNViewDelegate?

    // MARK: - Performance Configuration

    /// A Boolean value that indicates whether sibling order affects rendering order.
    ///
    /// When `true`, nodes at the same `zPosition` are rendered in an undefined order.
    /// When `false`, nodes are rendered in the order they appear in the `children` array.
    ///
    /// Setting this to `true` may improve rendering performance.
    ///
    /// Default: false
    public var ignoresSiblingOrder: Bool = false

    /// A Boolean value that indicates whether non-visible nodes are culled.
    ///
    /// When `true`, nodes outside the visible area are not rendered.
    ///
    /// Default: true
    public var shouldCullNonVisibleNodes: Bool = true

    /// A Boolean value that indicates whether the view allows transparency.
    ///
    /// When `true`, the view's background can be transparent.
    ///
    /// Default: false
    public var allowsTransparency: Bool = false

    /// A Boolean value that indicates whether content is rendered asynchronously.
    ///
    /// Default: true
    public var isAsynchronous: Bool = true

    // MARK: - Debug Options

    /// A Boolean value that indicates whether the view displays a frame rate indicator.
    public var showsFPS: Bool = false

    /// A Boolean value that indicates whether the view displays a node count.
    public var showsNodeCount: Bool = false

    /// A Boolean value that indicates whether the view displays the draw count.
    public var showsDrawCount: Bool = false

    /// A Boolean value that indicates whether the view displays the quad count.
    public var showsQuadCount: Bool = false

    /// A Boolean value that indicates whether the view displays physics bodies.
    public var showsPhysics: Bool = false

    /// A Boolean value that indicates whether the view displays physics fields.
    public var showsFields: Bool = false

    /// A Boolean value that controls whether the depth stencil buffer is disabled.
    ///
    /// Set this to `true` when your scene doesn't use depth testing or stencil operations.
    /// This can improve rendering performance.
    ///
    /// Default: false
    public var disableDepthStencilBuffer: Bool = false

    // MARK: - Statistics

    /// The current frames per second.
    public private(set) var currentFPS: Float = 0

    /// The number of nodes in the current scene.
    public var nodeCount: Int {
        guard let scene = scene else { return 0 }
        return countNodes(in: scene)
    }

    /// The number of draw calls in the last frame.
    public private(set) var drawCount: Int = 0

    private func countNodes(in node: SNNode) -> Int {
        var count = 1
        for child in node.children {
            count += countNodes(in: child)
        }
        return count
    }

    // MARK: - Internal

    /// The game loop managing updates.
    internal let gameLoop: GameLoop

    /// Last update time for FPS calculation.
    private var lastUpdateTime: Float = 0

    /// Frame count for FPS calculation.
    private var frameCount: Int = 0

    /// Time accumulator for FPS calculation.
    private var fpsAccumulator: Float = 0

    // MARK: - Initialization

    /// Creates a new view.
    public init() {
        self.gameLoop = GameLoop()
    }

    // MARK: - Update Cycle

    /// Updates the view with the elapsed time.
    ///
    /// This method should be called each frame by the platform-specific rendering loop.
    ///
    /// - Parameter deltaTime: The time elapsed since the last update.
    public func update(deltaTime: Float) {
        // Check delegate for render permission
        let currentTime = gameLoop.totalTime + deltaTime
        if let delegate = delegate {
            guard delegate.view(self, shouldRenderAtTime: currentTime) else {
                return
            }
        }

        // Update FPS
        updateFPS(deltaTime: deltaTime)

        // Handle transition
        if let transition = activeTransition {
            updateTransition(deltaTime: deltaTime, transition: transition)
        } else if let scene = scene, !scene.isPaused {
            // Normal update
            gameLoop.tick(realDeltaTime: deltaTime, input: gameLoop.input)
        }
    }

    private func updateFPS(deltaTime: Float) {
        frameCount += 1
        fpsAccumulator += deltaTime

        if fpsAccumulator >= 1.0 {
            currentFPS = Float(frameCount) / fpsAccumulator
            frameCount = 0
            fpsAccumulator = 0
        }
    }

    private func updateTransition(deltaTime: Float, transition: SNTransition) {
        // Update transition progress (visual only, uses real time)
        transitionProgress += deltaTime / transition.duration

        // Update scenes using fixed timestep for deterministic game logic
        let fixedDt = gameLoop.fixedTimestep

        // Accumulate time and process fixed timesteps
        transitionAccumulator += deltaTime
        while transitionAccumulator >= fixedDt {
            // Propagate input to scenes during transition
            let currentInput = gameLoop.input

            if let outgoing = outgoingScene, !transition.pausesOutgoingScene {
                outgoing.input = currentInput
                outgoing.processFrame(dt: fixedDt)
            }
            if let incoming = incomingScene, !transition.pausesIncomingScene {
                incoming.input = currentInput
                incoming.processFrame(dt: fixedDt)
            }

            // Clear edge flags after processing
            gameLoop.input.clearEdgeFlags()

            transitionAccumulator -= fixedDt
        }

        // Check if transition is complete
        if transitionProgress >= 1.0 {
            completeTransition()
        }
    }

    private func completeTransition() {
        guard let incoming = incomingScene else { return }

        // Finalize transition
        outgoingScene?.willMove(from: self)
        outgoingScene?.view = nil
        outgoingScene?.isPaused = false

        scene = incoming
        incoming.isPaused = false

        // Synchronize with GameLoop
        gameLoop.scene = incoming
        gameLoop.accumulator = 0

        incoming.didMove(to: self)

        // Clear transition state
        outgoingScene = nil
        incomingScene = nil
        activeTransition = nil
        transitionProgress = 0
        transitionAccumulator = 0
    }

    // MARK: - Rendering

    /// Generates draw commands for the current state.
    ///
    /// This includes handling transitions and debug overlays.
    ///
    /// - Returns: Array of draw commands.
    internal func generateDrawCommands() -> [DrawCommand] {
        if let transition = activeTransition {
            return generateTransitionDrawCommands(transition: transition)
        } else {
            return scene?.generateDrawCommands() ?? []
        }
    }

    private func generateTransitionDrawCommands(transition: SNTransition) -> [DrawCommand] {
        var commands: [DrawCommand] = []

        // Generate commands based on transition type
        switch transition.type {
        case .crossFade:
            // Render outgoing at decreasing alpha, incoming at increasing alpha
            if let outgoing = outgoingScene {
                let outCommands = outgoing.generateDrawCommands()
                for var cmd in outCommands {
                    cmd.alpha *= (1 - transitionProgress)
                    commands.append(cmd)
                }
            }
            if let incoming = incomingScene {
                let inCommands = incoming.generateDrawCommands()
                for var cmd in inCommands {
                    cmd.alpha *= transitionProgress
                    commands.append(cmd)
                }
            }

        case .fade(let color):
            let fadeProgress = transitionProgress

            if fadeProgress < 0.5 {
                // First half: fade out to color
                if let outgoing = outgoingScene {
                    let outCommands = outgoing.generateDrawCommands()
                    let alpha = 1 - (fadeProgress * 2)
                    for var cmd in outCommands {
                        cmd.alpha *= alpha
                        commands.append(cmd)
                    }
                }
            } else {
                // Second half: fade in from color
                if let incoming = incomingScene {
                    let inCommands = incoming.generateDrawCommands()
                    let alpha = (fadeProgress - 0.5) * 2
                    for var cmd in inCommands {
                        cmd.alpha *= alpha
                        commands.append(cmd)
                    }
                }
            }
            // Note: Fade overlay color is handled by renderer

        case .fadeWithBlack:
            let fadeProgress = transitionProgress

            if fadeProgress < 0.5 {
                // First half: fade out to black
                if let outgoing = outgoingScene {
                    let outCommands = outgoing.generateDrawCommands()
                    let alpha = 1 - (fadeProgress * 2)
                    for var cmd in outCommands {
                        cmd.alpha *= alpha
                        commands.append(cmd)
                    }
                }
            } else {
                // Second half: fade in from black
                if let incoming = incomingScene {
                    let inCommands = incoming.generateDrawCommands()
                    let alpha = (fadeProgress - 0.5) * 2
                    for var cmd in inCommands {
                        cmd.alpha *= alpha
                        commands.append(cmd)
                    }
                }
            }

        case .push(let direction):
            // Calculate offsets based on direction and progress
            let (outOffset, inOffset) = calculatePushOffsets(direction: direction)

            if let outgoing = outgoingScene {
                let outCommands = outgoing.generateDrawCommands()
                for var cmd in outCommands {
                    cmd.worldPosition.x += outOffset.x * transitionProgress
                    cmd.worldPosition.y += outOffset.y * transitionProgress
                    commands.append(cmd)
                }
            }
            if let incoming = incomingScene {
                let inCommands = incoming.generateDrawCommands()
                for var cmd in inCommands {
                    cmd.worldPosition.x += inOffset.x * (1 - transitionProgress)
                    cmd.worldPosition.y += inOffset.y * (1 - transitionProgress)
                    commands.append(cmd)
                }
            }

        case .moveIn(let direction):
            // Outgoing stays, incoming moves in
            if let outgoing = outgoingScene {
                commands.append(contentsOf: outgoing.generateDrawCommands())
            }
            if let incoming = incomingScene {
                let (_, inOffset) = calculatePushOffsets(direction: direction)
                let inCommands = incoming.generateDrawCommands()
                for var cmd in inCommands {
                    cmd.worldPosition.x += inOffset.x * (1 - transitionProgress)
                    cmd.worldPosition.y += inOffset.y * (1 - transitionProgress)
                    commands.append(cmd)
                }
            }

        case .reveal(let direction):
            // Incoming underneath, outgoing moves out
            if let incoming = incomingScene {
                commands.append(contentsOf: incoming.generateDrawCommands())
            }
            if let outgoing = outgoingScene {
                let (outOffset, _) = calculatePushOffsets(direction: direction)
                let outCommands = outgoing.generateDrawCommands()
                for var cmd in outCommands {
                    cmd.worldPosition.x += outOffset.x * transitionProgress
                    cmd.worldPosition.y += outOffset.y * transitionProgress
                    commands.append(cmd)
                }
            }

        default:
            // For other transitions, just show incoming
            if let incoming = incomingScene {
                commands.append(contentsOf: incoming.generateDrawCommands())
            }
        }

        commands.sort { $0.zPosition < $1.zPosition }
        return commands
    }

    private func calculatePushOffsets(direction: TransitionDirection) -> (out: Point, in: Point) {
        let sceneSize = scene?.size ?? incomingScene?.size ?? Size(width: 800, height: 600)

        switch direction {
        case .up:
            return (Point(x: 0, y: sceneSize.height), Point(x: 0, y: -sceneSize.height))
        case .down:
            return (Point(x: 0, y: -sceneSize.height), Point(x: 0, y: sceneSize.height))
        case .left:
            return (Point(x: -sceneSize.width, y: 0), Point(x: sceneSize.width, y: 0))
        case .right:
            return (Point(x: sceneSize.width, y: 0), Point(x: -sceneSize.width, y: 0))
        }
    }

    // MARK: - Coordinate Conversion

    /// The current view size (set by the platform-specific rendering layer).
    ///
    /// This property is updated by the platform's view implementation (GameView, etc.)
    /// during each frame update.
    internal var viewSize: Size = Size(width: 800, height: 600)

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// This is the SKView-compatible API. Use this when you have access to the scene.
    ///
    /// - Parameters:
    ///   - point: The point in scene coordinates.
    ///   - scene: The scene to convert from.
    /// - Returns: The point in view coordinates.
    public func convert(_ point: Point, from scene: SNScene) -> Point {
        return scene.convertPoint(toView: point, viewSize: viewSize)
    }

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// This is the SKView-compatible API. Use this when you have access to the scene.
    ///
    /// - Parameters:
    ///   - point: The point in view coordinates.
    ///   - scene: The scene to convert to.
    /// - Returns: The point in scene coordinates.
    public func convert(_ point: Point, to scene: SNScene) -> Point {
        return scene.convertPoint(fromView: point, viewSize: viewSize)
    }

    /// Converts a point from view coordinates to scene coordinates.
    ///
    /// - Parameters:
    ///   - point: The point in view coordinates.
    ///   - viewSize: The size of the view.
    /// - Returns: The point in scene coordinates.
    public func convert(_ point: Point, toSceneIn viewSize: Size) -> Point {
        guard let scene = scene else { return point }
        return scene.convertPoint(fromView: point, viewSize: viewSize)
    }

    /// Converts a point from scene coordinates to view coordinates.
    ///
    /// - Parameters:
    ///   - point: The point in scene coordinates.
    ///   - viewSize: The size of the view.
    /// - Returns: The point in view coordinates.
    public func convert(_ point: Point, fromSceneIn viewSize: Size) -> Point {
        guard let scene = scene else { return point }
        return scene.convertPoint(toView: point, viewSize: viewSize)
    }

    // MARK: - Texture Creation

    /// Renders a node's contents and returns the result as a texture.
    ///
    /// - Parameter node: The node to render.
    /// - Returns: A texture containing the rendered content, or `nil` if rendering fails.
    public func texture(from node: SNNode) -> SNTexture? {
        // This would require platform-specific implementation
        // Placeholder for future implementation
        return nil
    }

    /// Renders a portion of a node's contents and returns the result as a texture.
    ///
    /// - Parameters:
    ///   - node: The node to render.
    ///   - crop: The rectangle to render, in the node's coordinate system.
    /// - Returns: A texture containing the rendered content, or `nil` if rendering fails.
    public func texture(from node: SNNode, crop: Rect) -> SNTexture? {
        // This would require platform-specific implementation
        // Placeholder for future implementation
        return nil
    }
}

// MARK: - SNViewDelegate

/// Methods to take custom control over the view's render rate.
///
/// By implementing this protocol, you can precisely control when frames are rendered.
public protocol SNViewDelegate: AnyObject {
    /// Specifies whether the view should render at the given time.
    ///
    /// - Parameters:
    ///   - view: The view requesting permission to render.
    ///   - time: The current time.
    /// - Returns: `true` if the view should render, `false` to skip this frame.
    func view(_ view: SNView, shouldRenderAtTime time: Float) -> Bool
}

// MARK: - Default Implementation

public extension SNViewDelegate {
    func view(_ view: SNView, shouldRenderAtTime time: Float) -> Bool {
        return true
    }
}
