#if canImport(SwiftUI)
import SwiftUI

// Type aliases to avoid conflict with SpriteEngine.Color
private typealias SpriteEngineColor = SpriteEngine.Color

/// A SwiftUI view that renders a SpriteEngine scene.
///
/// `SpriteView` is the SpriteEngine equivalent of SpriteKit's `SpriteView`.
/// It provides a SwiftUI-native way to display scenes with full support for
/// transitions, debug options, and performance tuning.
///
/// ## Basic Usage
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         SpriteView(scene: MyGameScene(size: Size(width: 800, height: 600)))
///     }
/// }
/// ```
///
/// ## With Options and Debug
/// ```swift
/// SpriteView(
///     scene: gameScene,
///     transition: .crossFade(duration: 1.0),
///     isPaused: false,
///     preferredFramesPerSecond: 60,
///     options: [.allowsTransparency],
///     debugOptions: [.showsFPS, .showsNodeCount]
/// )
/// ```
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct SpriteView: SwiftUI.View {

    // MARK: - Options

    /// Options for configuring the sprite view's rendering behavior.
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Allows the view to render with transparency.
        public static let allowsTransparency = Options(rawValue: 1 << 0)

        /// Ignores sibling order when rendering, which may improve performance.
        public static let ignoresSiblingOrder = Options(rawValue: 1 << 1)

        /// Automatically culls nodes that are not visible.
        public static let shouldCullNonVisibleNodes = Options(rawValue: 1 << 2)
    }

    /// Options for displaying debug information.
    public struct DebugOptions: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Displays the current frame rate.
        public static let showsFPS = DebugOptions(rawValue: 1 << 0)

        /// Displays the number of nodes in the scene.
        public static let showsNodeCount = DebugOptions(rawValue: 1 << 1)

        /// Displays the number of draw calls.
        public static let showsDrawCount = DebugOptions(rawValue: 1 << 2)

        /// Displays the number of quads rendered.
        public static let showsQuadCount = DebugOptions(rawValue: 1 << 3)

        /// Displays physics bodies.
        public static let showsPhysics = DebugOptions(rawValue: 1 << 4)

        /// Displays physics fields.
        public static let showsFields = DebugOptions(rawValue: 1 << 5)
    }

    // MARK: - Properties

    @StateObject private var controller: SpriteViewController

    private let transition: SNTransition?
    private let options: Options
    private let debugOptions: DebugOptions
    private let shouldRender: ((TimeInterval) -> Bool)?

    // MARK: - Initializers

    /// Creates a sprite view with the specified scene.
    ///
    /// - Parameters:
    ///   - scene: The scene to display.
    ///   - transition: An optional transition to use when presenting the scene.
    ///   - isPaused: Whether the scene should start paused. Default is `false`.
    ///   - preferredFramesPerSecond: The target frame rate. Default is `60`.
    public init(
        scene: SNScene,
        transition: SNTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60
    ) {
        self._controller = StateObject(wrappedValue: SpriteViewController(
            scene: scene,
            isPaused: isPaused,
            preferredFramesPerSecond: preferredFramesPerSecond
        ))
        self.transition = transition
        self.options = []
        self.debugOptions = []
        self.shouldRender = nil
    }

    /// Creates a sprite view with the specified scene and options.
    ///
    /// - Parameters:
    ///   - scene: The scene to display.
    ///   - transition: An optional transition to use when presenting the scene.
    ///   - isPaused: Whether the scene should start paused. Default is `false`.
    ///   - preferredFramesPerSecond: The target frame rate. Default is `60`.
    ///   - options: Configuration options for rendering.
    ///   - shouldRender: A closure that determines whether to render at a given time.
    public init(
        scene: SNScene,
        transition: SNTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60,
        options: Options,
        shouldRender: ((TimeInterval) -> Bool)? = nil
    ) {
        self._controller = StateObject(wrappedValue: SpriteViewController(
            scene: scene,
            isPaused: isPaused,
            preferredFramesPerSecond: preferredFramesPerSecond
        ))
        self.transition = transition
        self.options = options
        self.debugOptions = []
        self.shouldRender = shouldRender
    }

    /// Creates a sprite view with the specified scene, options, and debug options.
    ///
    /// - Parameters:
    ///   - scene: The scene to display.
    ///   - transition: An optional transition to use when presenting the scene.
    ///   - isPaused: Whether the scene should start paused. Default is `false`.
    ///   - preferredFramesPerSecond: The target frame rate. Default is `60`.
    ///   - options: Configuration options for rendering.
    ///   - debugOptions: Debug display options.
    ///   - shouldRender: A closure that determines whether to render at a given time.
    public init(
        scene: SNScene,
        transition: SNTransition? = nil,
        isPaused: Bool = false,
        preferredFramesPerSecond: Int = 60,
        options: Options,
        debugOptions: DebugOptions,
        shouldRender: ((TimeInterval) -> Bool)? = nil
    ) {
        self._controller = StateObject(wrappedValue: SpriteViewController(
            scene: scene,
            isPaused: isPaused,
            preferredFramesPerSecond: preferredFramesPerSecond
        ))
        self.transition = transition
        self.options = options
        self.debugOptions = debugOptions
        self.shouldRender = shouldRender
    }

    // MARK: - View Body

    public var body: some SwiftUI.View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    // Check shouldRender callback
                    if let shouldRender = shouldRender {
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        guard shouldRender(time) else { return }
                    }

                    controller.update(date: timeline.date, viewSize: size)
                    render(context: &context, size: size)
                }
            }
            .background(backgroundColor)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        controller.handlePointerMove(at: value.location, in: geometry.size)
                        if !controller.view.input.pointerDown {
                            controller.handlePointerDown()
                        }
                    }
                    .onEnded { _ in
                        controller.handlePointerUp()
                    }
            )
        }
        .onAppear {
            applyOptions()
            applyDebugOptions()
            controller.start()
        }
        .onDisappear {
            controller.stop()
        }
    }

    private var backgroundColor: SwiftUI.Color {
        if options.contains(.allowsTransparency) {
            return .clear
        }
        return controller.view.scene?.backgroundColor.swiftUIColor ?? .black
    }

    private func applyOptions() {
        controller.view.allowsTransparency = options.contains(.allowsTransparency)
        controller.view.ignoresSiblingOrder = options.contains(.ignoresSiblingOrder)
        controller.view.shouldCullNonVisibleNodes = options.contains(.shouldCullNonVisibleNodes)
    }

    private func applyDebugOptions() {
        controller.view.showsFPS = debugOptions.contains(.showsFPS)
        controller.view.showsNodeCount = debugOptions.contains(.showsNodeCount)
        controller.view.showsDrawCount = debugOptions.contains(.showsDrawCount)
        controller.view.showsQuadCount = debugOptions.contains(.showsQuadCount)
        controller.view.showsPhysics = debugOptions.contains(.showsPhysics)
        controller.view.showsFields = debugOptions.contains(.showsFields)
    }

    // MARK: - Rendering

    /// Shared canvas renderer instance.
    private static let canvasRenderer = CanvasRenderer()

    private func render(context: inout GraphicsContext, size: CGSize) {
        guard let scene = controller.view.scene else { return }

        // Use CanvasRenderer for all rendering
        let commands = controller.view.generateDrawCommands()
        let labelCommands = scene.generateLabelDrawCommands()

        Self.canvasRenderer.render(
            scene: scene,
            commands: commands,
            labelCommands: labelCommands,
            in: &context,
            size: size,
            showAudioIndicator: true
        )

        // Render debug overlays (SpriteView-specific)
        renderDebugOverlays(context: &context, size: size)
    }

    private func renderDebugOverlays(context: inout GraphicsContext, size: CGSize) {
        var yOffset: CGFloat = 10

        if debugOptions.contains(.showsFPS) {
            let fpsText = String(format: "%.1f FPS", controller.view.currentFPS)
            let text = Text(fpsText).font(.system(size: 12, weight: .medium)).foregroundColor(.green)
            let resolved = context.resolve(text)
            context.draw(resolved, at: CGPoint(x: 10, y: yOffset), anchor: .topLeading)
            yOffset += 16
        }

        if debugOptions.contains(.showsNodeCount) {
            let countText = "\(controller.view.nodeCount) nodes"
            let text = Text(countText).font(.system(size: 12, weight: .medium)).foregroundColor(.green)
            let resolved = context.resolve(text)
            context.draw(resolved, at: CGPoint(x: 10, y: yOffset), anchor: .topLeading)
            yOffset += 16
        }

        if debugOptions.contains(.showsDrawCount) {
            let drawText = "\(controller.view.drawCount) draws"
            let text = Text(drawText).font(.system(size: 12, weight: .medium)).foregroundColor(.green)
            let resolved = context.resolve(text)
            context.draw(resolved, at: CGPoint(x: 10, y: yOffset), anchor: .topLeading)
        }
    }
}

// MARK: - SpriteViewController (Internal)

/// Internal controller for managing the sprite view's update cycle.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
internal class SpriteViewController: ObservableObject {
    let view: SNView

    private var lastUpdate: Date?
    private var isRunning: Bool = false

    init(scene: SNScene, isPaused: Bool, preferredFramesPerSecond: Int) {
        self.view = SNView()
        self.view.preferredFramesPerSecond = preferredFramesPerSecond
        self.view.presentScene(scene)
        scene.isPaused = isPaused
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func update(date: Date, viewSize: CGSize) {
        guard isRunning else { return }

        // Update view size for coordinate conversion
        view.viewSize = Size(width: CGFloat(viewSize.width), height: CGFloat(viewSize.height))

        // Calculate delta time
        let dt: CGFloat
        if let last = lastUpdate {
            dt = CGFloat(date.timeIntervalSince(last))
        } else {
            dt = 0
        }
        lastUpdate = date

        // Update view (input is managed externally via scene.input)
        if dt > 0 && dt < 0.25 {
            view.update(deltaTime: dt)
        }
    }

    // MARK: - Pointer Input

    func handlePointerMove(at location: CGPoint, in size: CGSize) {
        view.gameLoop.input.pointerPosition = Point(
            x: CGFloat(location.x),
            y: CGFloat(size.height - location.y)  // Flip Y for game coordinates
        )
    }

    func handlePointerDown() {
        view.gameLoop.input.pointerDown = true
    }

    func handlePointerUp() {
        view.gameLoop.input.pointerDown = false
    }
}

// MARK: - Backward Compatibility

/// Controller for managing the game view in SwiftUI.
///
/// - Note: Consider using `SpriteView` directly instead.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
@available(*, deprecated, renamed: "SpriteView", message: "Use SpriteView instead")
public typealias GameView = SpriteView

#endif
