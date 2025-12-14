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
            .focusable()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        controller.handlePointerMove(at: value.location, in: geometry.size)
                        if !controller.view.gameLoop.input.pointerDown {
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

    private func render(context: inout GraphicsContext, size: CGSize) {
        guard let scene = controller.view.scene else { return }

        let viewSize = Size(width: Float(size.width), height: Float(size.height))

        // Render sprites and tile maps (including transitions)
        let commands = controller.view.generateDrawCommands()
        for command in commands {
            renderCommand(command, context: &context, scene: scene, viewSize: viewSize)
        }

        // Render shape nodes
        renderShapeNodes(from: scene, context: &context, scene: scene, viewSize: viewSize)

        // Render labels
        let labelCommands = scene.generateLabelDrawCommands()
        for command in labelCommands {
            renderLabelCommand(command, context: &context, scene: scene, viewSize: viewSize)
        }

        // Render debug overlays
        renderDebugOverlays(context: &context, size: size)

        // Render audio indicator
        if scene.audio.hasCommands {
            renderAudioIndicator(context: &context, size: size)
        }
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

    private func renderCommand(_ command: DrawCommand, context: inout GraphicsContext, scene: SNScene, viewSize: Size) {
        guard command.alpha > 0 else { return }

        let screenPos = scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)

        // Calculate scene-to-view scale factor
        let sceneToViewScale: CGFloat
        switch scene.scaleMode {
        case .fill:
            sceneToViewScale = CGFloat((viewSize.width / scene.size.width + viewSize.height / scene.size.height) / 2)
        case .aspectFit:
            sceneToViewScale = CGFloat(min(viewSize.width / scene.size.width, viewSize.height / scene.size.height))
        case .aspectFill:
            sceneToViewScale = CGFloat(max(viewSize.width / scene.size.width, viewSize.height / scene.size.height))
        case .resizeFill:
            sceneToViewScale = 1
        }

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(
                x: CGFloat(command.worldScale.width) * sceneToViewScale,
                y: CGFloat(command.worldScale.height) * sceneToViewScale
            )

            let rect = CGRect(
                x: CGFloat(-command.size.width * command.anchorPoint.x),
                y: CGFloat(-command.size.height * (1 - command.anchorPoint.y)),
                width: CGFloat(command.size.width),
                height: CGFloat(command.size.height)
            )

            ctx.opacity = Double(command.alpha)

            // Draw textured or solid color sprite
            if command.textureID != .none {
                if let cgImage = SNTexture.cachedImage(for: command.textureID) {
                    let image = Image(cgImage, scale: 1.0, label: Text("texture"))
                    ctx.draw(image, in: rect)
                } else {
                    // Texture not loaded - draw placeholder
                    ctx.fill(SwiftUI.Path(rect), with: .color(command.color.swiftUIColor.opacity(0.8)))
                    ctx.stroke(SwiftUI.Path(rect), with: .color(.white.opacity(0.5)), lineWidth: 1)
                }
            } else {
                ctx.fill(SwiftUI.Path(rect), with: .color(command.color.swiftUIColor))
            }
        }
    }

    private func renderLabelCommand(_ command: LabelDrawCommand, context: inout GraphicsContext, scene: SNScene, viewSize: Size) {
        guard command.alpha > 0 else { return }

        let screenPos = scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(x: CGFloat(command.worldScale.width), y: CGFloat(command.worldScale.height))

            ctx.opacity = Double(command.alpha)

            var text = Text(command.text)
                .font(.system(size: CGFloat(command.fontSize)))
                .foregroundColor(command.fontColor.swiftUIColor)

            if let fontName = command.fontName {
                text = Text(command.text)
                    .font(.custom(fontName, size: CGFloat(command.fontSize)))
                    .foregroundColor(command.fontColor.swiftUIColor)
            }

            let resolved = ctx.resolve(text)
            let textSize = resolved.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))

            var offsetX: CGFloat = 0
            var offsetY: CGFloat = 0

            switch command.horizontalAlignment {
            case .left: offsetX = 0
            case .center: offsetX = -textSize.width / 2
            case .right: offsetX = -textSize.width
            }

            switch command.verticalAlignment {
            case .top: offsetY = 0
            case .center: offsetY = -textSize.height / 2
            case .bottom: offsetY = -textSize.height
            }

            ctx.draw(resolved, at: CGPoint(x: offsetX + textSize.width / 2, y: offsetY + textSize.height / 2))
        }
    }

    private func renderShapeNodes(from node: SNNode, context: inout GraphicsContext, scene: SNScene, viewSize: Size) {
        guard !node.isHidden else { return }

        if let shapeNode = node as? SNShapeNode, shapeNode.alpha > 0, let path = shapeNode.path {
            renderShapeNode(shapeNode, path: path, context: &context, scene: scene, viewSize: viewSize)
        }

        for child in node.children {
            renderShapeNodes(from: child, context: &context, scene: scene, viewSize: viewSize)
        }
    }

    private func renderShapeNode(_ node: SNShapeNode, path: ShapePath, context: inout GraphicsContext, scene: SNScene, viewSize: Size) {
        let screenPos = scene.convertPoint(toView: node.worldPosition, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-node.worldRotation)))
            ctx.scaleBy(x: CGFloat(node.worldScale.width), y: CGFloat(node.worldScale.height))

            ctx.opacity = Double(node.alpha)

            let swiftPath = path.toSwiftUIPath()

            if let fillColor = node.fillColor, fillColor.alpha > 0 {
                ctx.fill(swiftPath, with: .color(fillColor.swiftUIColor))
            }

            if let strokeColor = node.strokeColor, strokeColor.alpha > 0, node.lineWidth > 0 {
                let style = StrokeStyle(
                    lineWidth: CGFloat(node.lineWidth),
                    lineCap: node.lineCap.cgLineCap,
                    lineJoin: node.lineJoin.cgLineJoin,
                    miterLimit: CGFloat(node.miterLimit)
                )
                ctx.stroke(swiftPath, with: .color(strokeColor.swiftUIColor), style: style)
            }
        }
    }

    private func renderAudioIndicator(context: inout GraphicsContext, size: CGSize) {
        let iconSize: CGFloat = 20
        let padding: CGFloat = 10
        let rect = CGRect(x: size.width - iconSize - padding, y: padding, width: iconSize, height: iconSize)

        context.drawLayer { ctx in
            ctx.opacity = 0.7

            var speakerPath = SwiftUI.Path()
            speakerPath.move(to: CGPoint(x: rect.minX + 4, y: rect.midY - 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 8, y: rect.midY - 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 14, y: rect.midY - 8))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 14, y: rect.midY + 8))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 8, y: rect.midY + 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY + 4))
            speakerPath.closeSubpath()
            ctx.fill(speakerPath, with: .color(.white))

            var wave1 = SwiftUI.Path()
            wave1.addArc(center: CGPoint(x: rect.minX + 14, y: rect.midY), radius: 4,
                         startAngle: SwiftUI.Angle(degrees: -45), endAngle: SwiftUI.Angle(degrees: 45), clockwise: false)
            ctx.stroke(wave1, with: .color(.white), lineWidth: 1.5)

            var wave2 = SwiftUI.Path()
            wave2.addArc(center: CGPoint(x: rect.minX + 14, y: rect.midY), radius: 7,
                         startAngle: SwiftUI.Angle(degrees: -45), endAngle: SwiftUI.Angle(degrees: 45), clockwise: false)
            ctx.stroke(wave2, with: .color(.white), lineWidth: 1.5)
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
    private var keysDown: Set<InputKey> = []

    enum InputKey {
        case up, down, left, right, action, action2, pause
    }

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
        view.viewSize = Size(width: Float(viewSize.width), height: Float(viewSize.height))

        // Calculate delta time
        let dt: Float
        if let last = lastUpdate {
            dt = Float(date.timeIntervalSince(last))
        } else {
            dt = 0
        }
        lastUpdate = date

        // Build input state from keyboard
        var input = view.gameLoop.input
        input.up = keysDown.contains(.up)
        input.down = keysDown.contains(.down)
        input.left = keysDown.contains(.left)
        input.right = keysDown.contains(.right)
        input.action = keysDown.contains(.action)
        input.action2 = keysDown.contains(.action2)
        input.pause = keysDown.contains(.pause)

        // Update view
        view.gameLoop.input = input
        if dt > 0 && dt < 0.25 {
            view.update(deltaTime: dt)
        }
    }

    // MARK: - Input Handling

    func handleKeyDown(_ key: InputKey) {
        keysDown.insert(key)
    }

    func handleKeyUp(_ key: InputKey) {
        keysDown.remove(key)
    }

    func handlePointerMove(at location: CGPoint, in size: CGSize) {
        view.gameLoop.input.pointerPosition = Point(
            x: Float(location.x),
            y: Float(size.height - location.y)  // Flip Y for game coordinates
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
