#if canImport(SwiftUI)
import SwiftUI

// Type aliases to avoid conflict with SpriteEngine.Color
private typealias SpriteEngineColor = SpriteEngine.Color

/// A SwiftUI renderer for previewing SpriteEngine scenes during development.
///
/// `PreviewRenderer` provides a SwiftUI Canvas-based renderer that allows
/// testing game scenes in Xcode's #Preview without needing a browser.
///
/// ## Usage
/// ```swift
/// #Preview {
///     PreviewRenderer(scene: GameScene(size: Size(width: 800, height: 600)))
/// }
/// ```
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct PreviewRenderer: SwiftUI.View {
    /// The scene to render.
    @ObservedObject private var controller: SNSceneController

    /// Creates a preview renderer for the specified scene.
    public init(scene: SNScene) {
        self.controller = SNSceneController(scene: scene)
    }

    public var body: some SwiftUI.View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                controller.update(date: timeline.date)
                render(context: &context, size: size)
            }
        }
        .background(controller.scene.backgroundColor.swiftUIColor)
        .onAppear {
            controller.scene.sceneDidLoad()
        }
    }

    private func render(context: inout GraphicsContext, size: CGSize) {
        let viewSize = Size(width: Float(size.width), height: Float(size.height))

        // Render sprites and tile maps
        let commands = controller.scene.generateDrawCommands()
        for command in commands {
            renderCommand(command, context: &context, viewSize: viewSize)
        }

        // Render shape nodes
        renderShapeNodes(from: controller.scene, context: &context, viewSize: viewSize)

        // Render labels
        let labelCommands = controller.scene.generateLabelDrawCommands()
        for command in labelCommands {
            renderLabelCommand(command, context: &context, viewSize: viewSize)
        }

        // Render audio indicator
        if controller.scene.audio.hasCommands {
            renderAudioIndicator(context: &context, size: size)
        }
    }

    private func renderLabelCommand(_ command: LabelDrawCommand, context: inout GraphicsContext, viewSize: Size) {
        guard command.alpha > 0 else { return }

        let screenPos = worldToScreen(command.worldPosition, scene: controller.scene, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(x: CGFloat(command.worldScale.width), y: CGFloat(command.worldScale.height))

            ctx.opacity = Double(command.alpha)

            // Create text
            var text = Text(command.text)
                .font(.system(size: CGFloat(command.fontSize)))
                .foregroundColor(command.fontColor.swiftUIColor)

            if let fontName = command.fontName {
                text = Text(command.text)
                    .font(.custom(fontName, size: CGFloat(command.fontSize)))
                    .foregroundColor(command.fontColor.swiftUIColor)
            }

            // Resolve and draw
            let resolved = ctx.resolve(text)
            let textSize = resolved.measure(in: CGSize(width: CGFloat.infinity, height: CGFloat.infinity))

            // Calculate offset based on alignment
            var offsetX: CGFloat = 0
            var offsetY: CGFloat = 0

            switch command.horizontalAlignment {
            case .left:
                offsetX = 0
            case .center:
                offsetX = -textSize.width / 2
            case .right:
                offsetX = -textSize.width
            }

            switch command.verticalAlignment {
            case .top:
                offsetY = 0
            case .center:
                offsetY = -textSize.height / 2
            case .bottom:
                offsetY = -textSize.height
            }

            ctx.draw(resolved, at: CGPoint(x: offsetX + textSize.width / 2, y: offsetY + textSize.height / 2))
        }
    }

    private func renderShapeNodes(from node: SNNode, context: inout GraphicsContext, viewSize: Size) {
        guard !node.isHidden else { return }

        if let shapeNode = node as? SNShapeNode, shapeNode.alpha > 0, let path = shapeNode.path {
            renderShapeNode(shapeNode, path: path, context: &context, viewSize: viewSize)
        }

        for child in node.children {
            renderShapeNodes(from: child, context: &context, viewSize: viewSize)
        }
    }

    private func renderShapeNode(_ node: SNShapeNode, path: ShapePath, context: inout GraphicsContext, viewSize: Size) {
        let screenPos = worldToScreen(node.worldPosition, scene: controller.scene, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-node.worldRotation)))
            ctx.scaleBy(x: CGFloat(node.worldScale.width), y: CGFloat(node.worldScale.height))

            ctx.opacity = Double(node.alpha)

            let swiftPath = path.toSwiftUIPath()

            // Fill
            if let fillColor = node.fillColor, fillColor.alpha > 0 {
                ctx.fill(swiftPath, with: .color(fillColor.swiftUIColor))
            }

            // Stroke
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
        // Draw a small speaker icon in the corner when audio is playing
        let iconSize: CGFloat = 20
        let padding: CGFloat = 10
        let rect = CGRect(
            x: size.width - iconSize - padding,
            y: padding,
            width: iconSize,
            height: iconSize
        )

        context.drawLayer { ctx in
            ctx.opacity = 0.7

            // Speaker body
            var speakerPath = SwiftUI.Path()
            speakerPath.move(to: CGPoint(x: rect.minX + 4, y: rect.midY - 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 8, y: rect.midY - 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 14, y: rect.midY - 8))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 14, y: rect.midY + 8))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 8, y: rect.midY + 4))
            speakerPath.addLine(to: CGPoint(x: rect.minX + 4, y: rect.midY + 4))
            speakerPath.closeSubpath()

            ctx.fill(speakerPath, with: .color(.white))

            // Sound waves
            var wave1 = SwiftUI.Path()
            wave1.addArc(
                center: CGPoint(x: rect.minX + 14, y: rect.midY),
                radius: 4,
                startAngle: SwiftUI.Angle(degrees: -45),
                endAngle: SwiftUI.Angle(degrees: 45),
                clockwise: false
            )
            ctx.stroke(wave1, with: .color(.white), lineWidth: 1.5)

            var wave2 = SwiftUI.Path()
            wave2.addArc(
                center: CGPoint(x: rect.minX + 14, y: rect.midY),
                radius: 7,
                startAngle: SwiftUI.Angle(degrees: -45),
                endAngle: SwiftUI.Angle(degrees: 45),
                clockwise: false
            )
            ctx.stroke(wave2, with: .color(.white), lineWidth: 1.5)
        }
    }

    private func renderCommand(_ command: DrawCommand, context: inout GraphicsContext, viewSize: Size) {
        // Skip invisible commands
        guard command.alpha > 0 else { return }

        // Calculate screen position
        let screenPos = worldToScreen(
            command.worldPosition,
            scene: controller.scene,
            viewSize: viewSize
        )

        // Save context state
        context.drawLayer { ctx in
            // Apply transforms
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(x: CGFloat(command.worldScale.width), y: CGFloat(command.worldScale.height))

            // Calculate sprite rect (accounting for anchor point)
            let rect = CGRect(
                x: CGFloat(-command.size.width * command.anchorPoint.x),
                y: CGFloat(-command.size.height * (1 - command.anchorPoint.y)),
                width: CGFloat(command.size.width),
                height: CGFloat(command.size.height)
            )

            // Apply opacity
            ctx.opacity = Double(command.alpha)

            // Draw the sprite
            if command.textureID != .none {
                // Try to load texture image from registry
                if let cgImage = SNTexture.cachedImage(for: command.textureID) {
                    // Draw the actual texture
                    let image = Image(cgImage, scale: 1.0, label: Text("texture"))
                    ctx.draw(image, in: rect)

                    // Apply color tinting if needed (colorBlendFactor > 0)
                    // For now, just draw the texture as-is
                } else {
                    // Texture not loaded yet - draw placeholder
                    ctx.fill(
                        SwiftUI.Path(rect),
                        with: .color(command.color.swiftUIColor.opacity(0.8))
                    )
                    // Draw texture indicator
                    ctx.stroke(
                        SwiftUI.Path(rect),
                        with: .color(.white.opacity(0.5)),
                        lineWidth: 1
                    )
                }
            } else {
                // Solid color sprite
                ctx.fill(
                    SwiftUI.Path(rect),
                    with: .color(command.color.swiftUIColor)
                )
            }
        }
    }

    private func worldToScreen(_ worldPos: Point, scene: SNScene, viewSize: Size) -> Point {
        scene.convertPoint(toView: worldPos, viewSize: viewSize)
    }
}

/// Controller for managing scene updates in preview.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public class SNSceneController: ObservableObject {
    public let scene: SNScene
    private var lastUpdate: Date?

    public init(scene: SNScene) {
        self.scene = scene
    }

    func update(date: Date) {
        guard let last = lastUpdate else {
            lastUpdate = date
            return
        }

        let dt = Float(date.timeIntervalSince(last))
        lastUpdate = date

        // Use fixed timestep
        if dt > 0 && dt < 0.1 {
            scene.processFrame(dt: scene.fixedTimestep)
        }
    }
}

// MARK: - Interactive Preview

/// A preview wrapper that adds basic input controls.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct InteractivePreview: SwiftUI.View {
    @ObservedObject private var controller: SNInteractiveSceneController

    public init(scene: SNScene) {
        self.controller = SNInteractiveSceneController(scene: scene)
    }

    public var body: some SwiftUI.View {
        VStack(spacing: 0) {
            // Scene view
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    controller.update(date: timeline.date)
                    renderScene(context: &context, size: size)
                }
                .gesture(dragGesture)
                .gesture(tapGesture)
            }
            .background(controller.scene.backgroundColor.swiftUIColor)

            // Control panel
            controlPanel
        }
        .onAppear {
            controller.scene.sceneDidLoad()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                controller.input.pointerPosition = Point(
                    x: Float(value.location.x),
                    y: Float(value.location.y)
                )
                if !controller.input.pointerDown {
                    controller.input.pointerDown = true
                    controller.input.pointerJustPressed = true
                }
            }
            .onEnded { _ in
                controller.input.pointerDown = false
                controller.input.pointerJustReleased = true
            }
    }

    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded {
                controller.input.action = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    controller.input.action = false
                }
            }
    }

    private var controlPanel: some SwiftUI.View {
        HStack(spacing: 20) {
            // Direction buttons
            VStack {
                Button("↑") { controller.input.up = true }
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        controller.input.up = pressing
                    }, perform: {})

                HStack {
                    Button("←") { controller.input.left = true }
                        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                            controller.input.left = pressing
                        }, perform: {})

                    Button("→") { controller.input.right = true }
                        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                            controller.input.right = pressing
                        }, perform: {})
                }

                Button("↓") { controller.input.down = true }
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        controller.input.down = pressing
                    }, perform: {})
            }

            Spacer()

            // Action buttons
            VStack {
                Button("Action") { controller.input.action = true }
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        controller.input.action = pressing
                    }, perform: {})

                Button("Action2") { controller.input.action2 = true }
                    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                        controller.input.action2 = pressing
                    }, perform: {})
            }

            // Pause
            Button(controller.scene.isPaused ? "▶" : "⏸") {
                controller.scene.isPaused.toggle()
            }
        }
        .padding()
        .background(SwiftUI.Color.black.opacity(0.1))
    }

    private func renderScene(context: inout GraphicsContext, size: CGSize) {
        let viewSize = Size(width: Float(size.width), height: Float(size.height))

        // Render sprites and tile maps
        let commands = controller.scene.generateDrawCommands()
        for command in commands {
            renderCommand(command, context: &context, viewSize: viewSize)
        }

        // Render shape nodes
        renderShapeNodes(from: controller.scene, context: &context, viewSize: viewSize)

        // Render labels
        let labelCommands = controller.scene.generateLabelDrawCommands()
        for command in labelCommands {
            renderLabelCommand(command, context: &context, viewSize: viewSize)
        }

        // Render audio indicator
        if controller.scene.audio.hasCommands {
            renderAudioIndicator(context: &context, size: size)
        }
    }

    private func renderCommand(_ command: DrawCommand, context: inout GraphicsContext, viewSize: Size) {
        guard command.alpha > 0 else { return }

        let screenPos = controller.scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(x: CGFloat(command.worldScale.width), y: CGFloat(command.worldScale.height))

            let rect = CGRect(
                x: CGFloat(-command.size.width * command.anchorPoint.x),
                y: CGFloat(-command.size.height * (1 - command.anchorPoint.y)),
                width: CGFloat(command.size.width),
                height: CGFloat(command.size.height)
            )

            ctx.opacity = Double(command.alpha)
            ctx.fill(SwiftUI.Path(rect), with: .color(command.color.swiftUIColor))
        }
    }

    private func renderLabelCommand(_ command: LabelDrawCommand, context: inout GraphicsContext, viewSize: Size) {
        guard command.alpha > 0 else { return }

        let screenPos = controller.scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)

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

    private func renderShapeNodes(from node: SNNode, context: inout GraphicsContext, viewSize: Size) {
        guard !node.isHidden else { return }

        if let shapeNode = node as? SNShapeNode, shapeNode.alpha > 0, let path = shapeNode.path {
            renderShapeNode(shapeNode, path: path, context: &context, viewSize: viewSize)
        }

        for child in node.children {
            renderShapeNodes(from: child, context: &context, viewSize: viewSize)
        }
    }

    private func renderShapeNode(_ node: SNShapeNode, path: ShapePath, context: inout GraphicsContext, viewSize: Size) {
        let screenPos = controller.scene.convertPoint(toView: node.worldPosition, viewSize: viewSize)

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

/// Controller for interactive preview with input handling.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public class SNInteractiveSceneController: ObservableObject {
    public let scene: SNScene
    @Published public var input: InputState = InputState()
    private var lastUpdate: Date?

    public init(scene: SNScene) {
        self.scene = scene
    }

    func update(date: Date) {
        guard let last = lastUpdate else {
            lastUpdate = date
            return
        }

        let dt = Float(date.timeIntervalSince(last))
        lastUpdate = date

        if dt > 0 && dt < 0.1 {
            scene.input = input
            scene.processFrame(dt: scene.fixedTimestep)

            // Clear edge flags
            input.pointerJustPressed = false
            input.pointerJustReleased = false
        }
    }
}

// MARK: - ShapePath to SwiftUI.Path Conversion

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension ShapePath {
    /// Converts this ShapePath to a SwiftUI Path.
    func toSwiftUIPath() -> SwiftUI.Path {
        var path = SwiftUI.Path()

        for element in elements {
            switch element {
            case .moveTo(let point):
                path.move(to: CGPoint(x: CGFloat(point.x), y: CGFloat(point.y)))
            case .lineTo(let point):
                path.addLine(to: CGPoint(x: CGFloat(point.x), y: CGFloat(point.y)))
            case .quadCurveTo(let control, let end):
                path.addQuadCurve(
                    to: CGPoint(x: CGFloat(end.x), y: CGFloat(end.y)),
                    control: CGPoint(x: CGFloat(control.x), y: CGFloat(control.y))
                )
            case .curveTo(let control1, let control2, let end):
                path.addCurve(
                    to: CGPoint(x: CGFloat(end.x), y: CGFloat(end.y)),
                    control1: CGPoint(x: CGFloat(control1.x), y: CGFloat(control1.y)),
                    control2: CGPoint(x: CGFloat(control2.x), y: CGFloat(control2.y))
                )
            case .closeSubpath:
                path.closeSubpath()
            }
        }

        return path
    }
}

// MARK: - LineCap and LineJoin Conversions

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension LineCap {
    /// Converts to CGLineCap for use with SwiftUI/CoreGraphics.
    var cgLineCap: CGLineCap {
        switch self {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension LineJoin {
    /// Converts to CGLineJoin for use with SwiftUI/CoreGraphics.
    var cgLineJoin: CGLineJoin {
        switch self {
        case .miter: return .miter
        case .round: return .round
        case .bevel: return .bevel
        }
    }
}

#endif
