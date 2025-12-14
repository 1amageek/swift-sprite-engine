/// Manages the fixed timestep game loop.
///
/// `GameLoop` implements a fixed timestep update cycle that ensures
/// deterministic game behavior regardless of actual frame rate.
///
/// ## Usage (JavaScript side calls these)
/// ```swift
/// let loop = GameLoop(scene: gameScene, fixedTimestep: 1.0/60.0)
///
/// // Called from requestAnimationFrame
/// loop.tick(realDeltaTime: frameTime, input: currentInput)
/// let commands = loop.generateDrawCommands()
/// ```
///
/// ## Fixed Timestep
/// The game always updates in fixed increments (e.g., 1/60 second).
/// If real time runs faster, multiple updates occur per frame.
/// If real time runs slower, updates are skipped.
public final class GameLoop: @unchecked Sendable {
    // MARK: - Configuration

    /// The fixed timestep for each update (default: 1/60 second).
    public var fixedTimestep: Float

    /// Maximum time to process per frame to prevent spiral of death.
    public var maxFrameTime: Float = 0.25

    // MARK: - State

    /// The scene being updated.
    public internal(set) var scene: SNScene?

    /// Accumulated time waiting to be processed.
    internal var accumulator: Float = 0

    /// Total elapsed simulation time.
    public private(set) var totalTime: Float = 0

    /// Current input state.
    public var input: InputState = InputState()

    /// Previous frame's pointer down state for edge detection.
    private var previousPointerDown: Bool = false

    // MARK: - Statistics

    /// Number of updates performed in the last tick.
    public private(set) var updatesThisTick: Int = 0

    /// Current update rate (updates per second).
    public var updatesPerSecond: Float {
        1.0 / fixedTimestep
    }

    // MARK: - Initialization

    /// Creates a game loop with the specified timestep.
    ///
    /// - Parameter fixedTimestep: The fixed time between updates (default: 1/60).
    public init(fixedTimestep: Float = 1.0 / 60.0) {
        self.fixedTimestep = fixedTimestep
    }

    /// Creates a game loop with a scene.
    ///
    /// - Parameters:
    ///   - scene: The scene to update and render.
    ///   - fixedTimestep: The fixed time between updates.
    public init(scene: SNScene, fixedTimestep: Float = 1.0 / 60.0) {
        self.scene = scene
        self.fixedTimestep = fixedTimestep
    }

    // MARK: - Scene Management

    /// Presents a scene in this game loop.
    ///
    /// - Parameter scene: The scene to present.
    ///
    /// - Note: When using `View` (the SKView equivalent), prefer using
    ///   `View.presentScene(_:)` instead, which properly handles lifecycle
    ///   callbacks (`sceneDidLoad`, `didMove`, `willMove`).
    ///
    ///   This method is for internal use or for cases where `View` is not used.
    public func present(_ scene: SNScene) {
        self.scene = scene
        accumulator = 0
    }

    /// Removes the current scene.
    ///
    /// - Note: When using `View`, prefer using `View.presentScene(nil)` instead.
    public func removeScene() {
        scene = nil
    }

    // MARK: - Game Loop

    /// Processes a frame with the given real elapsed time.
    ///
    /// This method should be called once per browser frame from
    /// `requestAnimationFrame`. It handles:
    /// 1. Accumulating real time
    /// 2. Running fixed timestep updates
    /// 3. Updating edge detection flags
    ///
    /// - Parameters:
    ///   - realDeltaTime: Actual elapsed time since last tick (in seconds).
    ///   - input: Current input state from JavaScript.
    public func tick(realDeltaTime: Float, input: InputState) {
        guard let scene = scene, !scene.isPaused else {
            updatesThisTick = 0
            return
        }

        // Update input with edge detection
        self.input = input
        self.input.updateEdgeDetection(previousPointerDown: previousPointerDown)
        previousPointerDown = input.pointerDown

        // Clamp to prevent spiral of death
        let frameTime = min(realDeltaTime, maxFrameTime)
        accumulator += frameTime

        // Fixed timestep updates
        updatesThisTick = 0
        while accumulator >= fixedTimestep {
            scene.input = self.input
            scene.processFrame(dt: fixedTimestep)
            accumulator -= fixedTimestep
            totalTime += fixedTimestep
            updatesThisTick += 1

            // Clear edge flags after first update
            self.input.clearEdgeFlags()
        }
    }

    /// Processes a single fixed timestep update.
    ///
    /// Use this for deterministic replay or networking.
    ///
    /// - Parameter input: The input state for this update.
    public func step(input: InputState) {
        guard let scene = scene, !scene.isPaused else { return }

        self.input = input
        self.input.updateEdgeDetection(previousPointerDown: previousPointerDown)
        previousPointerDown = input.pointerDown

        scene.input = self.input
        scene.processFrame(dt: fixedTimestep)
        totalTime += fixedTimestep

        self.input.clearEdgeFlags()
    }

    // MARK: - Rendering

    /// Generates draw commands for the current scene state.
    ///
    /// - Returns: Array of draw commands sorted by z-position.
    internal func generateDrawCommands() -> [DrawCommand] {
        scene?.generateDrawCommands() ?? []
    }

    /// Returns the interpolation alpha for smooth rendering.
    ///
    /// This value (0-1) represents how far we are between the last
    /// update and the next. Use for interpolating render positions.
    public var interpolationAlpha: Float {
        accumulator / fixedTimestep
    }

    // MARK: - Reset

    /// Resets the game loop state.
    public func reset() {
        accumulator = 0
        totalTime = 0
        input = InputState()
        previousPointerDown = false
        updatesThisTick = 0
    }
}
