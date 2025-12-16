#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI Canvas-based renderer for SpriteEngine scenes.
///
/// `CanvasRenderer` provides the core rendering logic for displaying scenes
/// using SwiftUI's Canvas. It handles:
/// - Sprite rendering with textures and solid colors
/// - 9-slice (NinePatch) texture scaling
/// - Shape node rendering (fill and stroke)
/// - Label rendering with alignment
/// - Scene-to-view coordinate conversion
/// - Audio indicator overlay
///
/// This class is used internally by `SpriteView`.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
internal final class CanvasRenderer {

    // MARK: - Initialization

    init() {}

    // MARK: - Main Render Method

    /// Renders a complete scene frame.
    ///
    /// - Parameters:
    ///   - scene: The scene being rendered (for coordinate conversion and settings).
    ///   - commands: Draw commands for sprites and tile maps.
    ///   - labelCommands: Draw commands for labels.
    ///   - context: The SwiftUI graphics context to render into.
    ///   - size: The view size in points.
    ///   - showAudioIndicator: Whether to show audio indicator when audio is playing.
    func render(
        scene: SNScene,
        commands: [DrawCommand],
        labelCommands: [LabelDrawCommand],
        in context: inout GraphicsContext,
        size: CGSize,
        showAudioIndicator: Bool = true
    ) {
        let viewSize = Size(width: Float(size.width), height: Float(size.height))

        // Render sprites and tile maps
        for command in commands {
            renderCommand(command, context: &context, scene: scene, viewSize: viewSize)
        }

        // Render shape nodes
        renderShapeNodes(from: scene, context: &context, scene: scene, viewSize: viewSize)

        // Render labels
        for command in labelCommands {
            renderLabelCommand(command, context: &context, scene: scene, viewSize: viewSize)
        }

        // Render audio indicator
        if showAudioIndicator && scene.audio.hasCommands {
            renderAudioIndicator(context: &context, size: size)
        }
    }

    // MARK: - Sprite Rendering

    /// Renders a single draw command (sprite or tile).
    ///
    /// - Parameters:
    ///   - command: The draw command to render.
    ///   - context: The graphics context.
    ///   - scene: The scene for coordinate conversion.
    ///   - viewSize: The view size.
    func renderCommand(
        _ command: DrawCommand,
        context: inout GraphicsContext,
        scene: SNScene,
        viewSize: Size
    ) {
        guard command.alpha > 0 else { return }

        let screenPos = scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)
        let sceneToViewScale = calculateSceneToViewScale(scene: scene, viewSize: viewSize)

        context.drawLayer { ctx in
            // Apply transforms
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(
                x: CGFloat(command.worldScale.width) * sceneToViewScale,
                y: CGFloat(command.worldScale.height) * sceneToViewScale
            )

            // Calculate sprite rect (accounting for anchor point)
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
                    // Check if 9-slice rendering is needed
                    let cr = command.centerRect
                    let isNineSlice = cr.x > 0 || cr.y > 0 || cr.width < 1 || cr.height < 1

                    if isNineSlice {
                        renderNineSlice(cgImage: cgImage, centerRect: cr, destRect: rect, context: &ctx)
                    } else {
                        let image = Image(cgImage, scale: 1.0, label: Text("texture"))
                        ctx.draw(image, in: rect)
                    }
                } else {
                    // Texture not loaded - draw placeholder
                    ctx.fill(SwiftUI.Path(rect), with: .color(command.color.swiftUIColor.opacity(0.8)))
                    ctx.stroke(SwiftUI.Path(rect), with: .color(.white.opacity(0.5)), lineWidth: 1)
                }
            } else {
                // Solid color sprite
                ctx.fill(SwiftUI.Path(rect), with: .color(command.color.swiftUIColor))
            }
        }
    }

    // MARK: - 9-Slice Rendering

    /// Renders a texture using 9-slice (NinePatch) scaling.
    ///
    /// The centerRect defines the stretchable region in normalized coordinates [0, 1].
    /// Input centerRect uses SpriteKit coordinates (Y=0 at bottom).
    /// This method converts to CGImage coordinates (Y=0 at top) internally.
    ///
    /// - Parameters:
    ///   - cgImage: The source texture image.
    ///   - centerRect: The center stretchable region in SpriteKit coordinates.
    ///   - destRect: The destination rectangle to render into.
    ///   - context: The graphics context.
    func renderNineSlice(
        cgImage: CGImage,
        centerRect: Rect,
        destRect: CGRect,
        context: inout GraphicsContext
    ) {
        let texW = CGFloat(cgImage.width)
        let texH = CGFloat(cgImage.height)

        // Convert SpriteKit centerRect (Y=0 at bottom) to CGImage coordinates (Y=0 at top)
        // Formula: cgY = 1 - spriteKitY - spriteKitHeight
        let cgCenterRectX = CGFloat(centerRect.x)
        let cgCenterRectY = 1.0 - CGFloat(centerRect.y) - CGFloat(centerRect.height)
        let cgCenterRectW = CGFloat(centerRect.width)
        let cgCenterRectH = CGFloat(centerRect.height)

        // Calculate pixel boundaries in CGImage coordinates
        let leftWidth = cgCenterRectX * texW
        let centerX = leftWidth
        let centerWidth = cgCenterRectW * texW
        let rightWidth = texW - leftWidth - centerWidth

        let topHeight = cgCenterRectY * texH
        let centerY = topHeight
        let centerHeight = cgCenterRectH * texH
        let bottomHeight = texH - topHeight - centerHeight

        // Destination sizes - fixed regions maintain original pixel size, center stretches
        let dstLeftWidth = leftWidth
        let dstRightWidth = rightWidth
        let dstTopHeight = topHeight
        let dstBottomHeight = bottomHeight
        let dstCenterWidth = destRect.width - dstLeftWidth - dstRightWidth
        let dstCenterHeight = destRect.height - dstTopHeight - dstBottomHeight

        // Source rectangles in CGImage coordinates (Y=0 at top)
        // Layout: TL, Top, TR, Left, Center, Right, BL, Bottom, BR
        let srcRects: [CGRect] = [
            CGRect(x: 0, y: 0, width: leftWidth, height: topHeight),
            CGRect(x: centerX, y: 0, width: centerWidth, height: topHeight),
            CGRect(x: centerX + centerWidth, y: 0, width: rightWidth, height: topHeight),
            CGRect(x: 0, y: centerY, width: leftWidth, height: centerHeight),
            CGRect(x: centerX, y: centerY, width: centerWidth, height: centerHeight),
            CGRect(x: centerX + centerWidth, y: centerY, width: rightWidth, height: centerHeight),
            CGRect(x: 0, y: centerY + centerHeight, width: leftWidth, height: bottomHeight),
            CGRect(x: centerX, y: centerY + centerHeight, width: centerWidth, height: bottomHeight),
            CGRect(x: centerX + centerWidth, y: centerY + centerHeight, width: rightWidth, height: bottomHeight)
        ]

        // Destination rectangles in Canvas coordinates
        let baseX = destRect.minX
        let baseY = destRect.minY

        let dstRects: [CGRect] = [
            CGRect(x: baseX, y: baseY, width: dstLeftWidth, height: dstTopHeight),
            CGRect(x: baseX + dstLeftWidth, y: baseY, width: dstCenterWidth, height: dstTopHeight),
            CGRect(x: baseX + dstLeftWidth + dstCenterWidth, y: baseY, width: dstRightWidth, height: dstTopHeight),
            CGRect(x: baseX, y: baseY + dstTopHeight, width: dstLeftWidth, height: dstCenterHeight),
            CGRect(x: baseX + dstLeftWidth, y: baseY + dstTopHeight, width: dstCenterWidth, height: dstCenterHeight),
            CGRect(x: baseX + dstLeftWidth + dstCenterWidth, y: baseY + dstTopHeight, width: dstRightWidth, height: dstCenterHeight),
            CGRect(x: baseX, y: baseY + dstTopHeight + dstCenterHeight, width: dstLeftWidth, height: dstBottomHeight),
            CGRect(x: baseX + dstLeftWidth, y: baseY + dstTopHeight + dstCenterHeight, width: dstCenterWidth, height: dstBottomHeight),
            CGRect(x: baseX + dstLeftWidth + dstCenterWidth, y: baseY + dstTopHeight + dstCenterHeight, width: dstRightWidth, height: dstBottomHeight)
        ]

        // Draw each of the 9 slices
        for i in 0..<9 {
            let src = srcRects[i]
            let dst = dstRects[i]

            // Skip if source or destination has zero size
            guard src.width > 0 && src.height > 0 && dst.width > 0 && dst.height > 0 else { continue }

            // Crop the source region from the original image
            if let croppedCGImage = cgImage.cropping(to: src) {
                let sliceImage = Image(croppedCGImage, scale: 1.0, label: Text("slice"))
                context.draw(sliceImage, in: dst)
            }
        }
    }

    // MARK: - Label Rendering

    /// Renders a label draw command.
    ///
    /// - Parameters:
    ///   - command: The label draw command.
    ///   - context: The graphics context.
    ///   - scene: The scene for coordinate conversion.
    ///   - viewSize: The view size.
    func renderLabelCommand(
        _ command: LabelDrawCommand,
        context: inout GraphicsContext,
        scene: SNScene,
        viewSize: Size
    ) {
        guard command.alpha > 0 else { return }

        let screenPos = scene.convertPoint(toView: command.worldPosition, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-command.worldRotation)))
            ctx.scaleBy(x: CGFloat(command.worldScale.width), y: CGFloat(command.worldScale.height))

            ctx.opacity = Double(command.alpha)

            // Create text with appropriate font
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

            // Calculate offset based on alignment
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

    // MARK: - Shape Node Rendering

    /// Recursively renders shape nodes from a node tree.
    ///
    /// - Parameters:
    ///   - node: The root node to traverse.
    ///   - context: The graphics context.
    ///   - scene: The scene for coordinate conversion.
    ///   - viewSize: The view size.
    func renderShapeNodes(
        from node: SNNode,
        context: inout GraphicsContext,
        scene: SNScene,
        viewSize: Size
    ) {
        guard !node.isHidden else { return }

        if let shapeNode = node as? SNShapeNode, shapeNode.alpha > 0, let path = shapeNode.path {
            renderShapeNode(shapeNode, path: path, context: &context, scene: scene, viewSize: viewSize)
        }

        for child in node.children {
            renderShapeNodes(from: child, context: &context, scene: scene, viewSize: viewSize)
        }
    }

    /// Renders a single shape node.
    ///
    /// - Parameters:
    ///   - node: The shape node to render.
    ///   - path: The shape's path.
    ///   - context: The graphics context.
    ///   - scene: The scene for coordinate conversion.
    ///   - viewSize: The view size.
    func renderShapeNode(
        _ node: SNShapeNode,
        path: ShapePath,
        context: inout GraphicsContext,
        scene: SNScene,
        viewSize: Size
    ) {
        let screenPos = scene.convertPoint(toView: node.worldPosition, viewSize: viewSize)
        let sceneToViewScale = calculateSceneToViewScale(scene: scene, viewSize: viewSize)

        context.drawLayer { ctx in
            ctx.translateBy(x: CGFloat(screenPos.x), y: CGFloat(viewSize.height - screenPos.y))
            ctx.rotate(by: SwiftUI.Angle(radians: Double(-node.worldRotation)))
            ctx.scaleBy(
                x: CGFloat(node.worldScale.width) * sceneToViewScale,
                y: CGFloat(node.worldScale.height) * sceneToViewScale
            )

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

    // MARK: - Audio Indicator

    /// Renders an audio indicator icon when audio is playing.
    ///
    /// - Parameters:
    ///   - context: The graphics context.
    ///   - size: The view size.
    func renderAudioIndicator(context: inout GraphicsContext, size: CGSize) {
        let iconSize: CGFloat = 20
        let padding: CGFloat = 10
        let rect = CGRect(x: size.width - iconSize - padding, y: padding, width: iconSize, height: iconSize)

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

    // MARK: - Helper Methods

    /// Calculates the scale factor for converting scene coordinates to view coordinates.
    ///
    /// - Parameters:
    ///   - scene: The scene with scale mode settings.
    ///   - viewSize: The view size.
    /// - Returns: The scale factor as a CGFloat.
    private func calculateSceneToViewScale(scene: SNScene, viewSize: Size) -> CGFloat {
        switch scene.scaleMode {
        case .fill:
            return CGFloat((viewSize.width / scene.size.width + viewSize.height / scene.size.height) / 2)
        case .aspectFit:
            return CGFloat(min(viewSize.width / scene.size.width, viewSize.height / scene.size.height))
        case .aspectFill:
            return CGFloat(max(viewSize.width / scene.size.width, viewSize.height / scene.size.height))
        case .resizeFill:
            return 1
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
