/// A node that displays text.
///
/// `SNLabelNode` renders text at a specified position. The actual rendering
/// is platform-dependent and handled by the renderer.
///
/// ## Usage
/// ```swift
/// let scoreLabel = SNLabelNode(text: "Score: 0")
/// scoreLabel.fontSize = 24
/// scoreLabel.fontColor = .white
/// scoreLabel.position = CGPoint(x: 100, y: 500)
/// scene.addChild(scoreLabel)
///
/// // Update text later
/// scoreLabel.text = "Score: 100"
/// ```
public final class SNLabelNode: SNNode {
    /// The text to display.
    public var text: String {
        didSet {
            updateSize()
        }
    }

    /// The font size in points.
    public var fontSize: CGFloat = 16 {
        didSet {
            updateSize()
        }
    }

    /// The font name (platform-dependent).
    public var fontName: String?

    /// The color of the text.
    public var fontColor: Color = .white

    /// The horizontal alignment of the text.
    public var horizontalAlignment: HorizontalAlignment = .center

    /// The vertical alignment of the text.
    public var verticalAlignment: VerticalAlignment = .center

    /// The calculated size of the label.
    private var _size: CGSize = .zero

    /// The size of the label (computed from text).
    public var size: CGSize {
        _size
    }

    /// Creates a label with the specified text.
    ///
    /// - Parameter text: The text to display.
    public init(text: String) {
        self.text = text
        super.init()
        updateSize()
    }

    /// Creates an empty label.
    public override init() {
        self.text = ""
        super.init()
    }

    /// Updates the size based on text and font.
    private func updateSize() {
        // Approximate size calculation
        // The actual size should be computed by the renderer
        let charWidth = fontSize * 0.6
        let lineHeight = fontSize * 1.2
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let maxLineLength = lines.map { $0.count }.max() ?? 0

        _size = CGSize(
            width: CGFloat(maxLineLength) * charWidth,
            height: CGFloat(lines.count) * lineHeight
        )
    }

    /// The bounding frame of this label.
    public override var frame: CGRect {
        let anchorOffset = anchorOffset(for: _size)
        return CGRect(
            x: position.x - anchorOffset.x,
            y: position.y - anchorOffset.y,
            width: _size.width,
            height: _size.height
        )
    }

    /// Calculates anchor offset based on alignment.
    private func anchorOffset(for size: CGSize) -> CGPoint {
        let x: CGFloat
        switch horizontalAlignment {
        case .left:
            x = 0
        case .center:
            x = size.width / 2
        case .right:
            x = size.width
        }

        let y: CGFloat
        switch verticalAlignment {
        case .top:
            y = size.height
        case .center:
            y = size.height / 2
        case .bottom:
            y = 0
        }

        return CGPoint(x: x, y: y)
    }

    /// Creates a draw command for this label.
    public func makeDrawCommand() -> LabelDrawCommand {
        LabelDrawCommand(
            text: text,
            worldPosition: worldPosition,
            worldRotation: worldRotation,
            worldScale: worldScale,
            fontSize: fontSize,
            fontName: fontName,
            fontColor: fontColor,
            alpha: worldAlpha,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            zPosition: zPosition
        )
    }

    public override var description: String {
        let textPreview = text.count > 20 ? String(text.prefix(20)) + "..." : text
        return "SNLabelNode(\"\(textPreview)\", pos: \(position))"
    }
}

// MARK: - Alignment Types

/// Horizontal text alignment.
public enum HorizontalAlignment: Sendable {
    case left
    case center
    case right
}

/// Vertical text alignment.
public enum VerticalAlignment: Sendable {
    case top
    case center
    case bottom
}

// MARK: - Label Draw Command

/// A draw command specifically for labels.
public struct LabelDrawCommand: Sendable {
    /// The text to render.
    public let text: String

    /// The position in world coordinates.
    public let worldPosition: CGPoint

    /// The rotation in world coordinates.
    public let worldRotation: CGFloat

    /// The scale in world coordinates.
    public let worldScale: CGSize

    /// The font size.
    public let fontSize: CGFloat

    /// The font name (optional).
    public let fontName: String?

    /// The text color.
    public let fontColor: Color

    /// The alpha transparency.
    public let alpha: CGFloat

    /// Horizontal alignment.
    public let horizontalAlignment: HorizontalAlignment

    /// Vertical alignment.
    public let verticalAlignment: VerticalAlignment

    /// The z-position for sorting.
    public let zPosition: CGFloat
}
