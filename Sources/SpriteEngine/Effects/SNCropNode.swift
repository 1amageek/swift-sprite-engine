/// A node that masks its children so only some pixels are visible.
///
/// `SNCropNode` uses a mask node to determine which pixels of its children
/// are visible. Only pixels that correspond to non-transparent pixels in
/// the mask are rendered.
///
/// ## Usage
/// ```swift
/// // Create a circular viewport
/// let cropNode = SNCropNode()
/// let mask = SNSpriteNode(color: .white, size: Size(width: 200, height: 200))
/// // Use a circular texture for the mask
/// cropNode.maskNode = mask
///
/// // Add content to be cropped
/// cropNode.addChild(gameContent)
/// scene.addChild(cropNode)
/// ```
///
/// ## Mask Types
/// - **SNSpriteNode**: Use a textured sprite for per-pixel masking
/// - **Solid Color SNSpriteNode**: Creates a rectangular mask
/// - **Multiple Nodes**: Combine nodes to create complex mask shapes
public final class SNCropNode: SNEffectNode {
    // MARK: - Mask

    /// The node used to determine the crop mask.
    ///
    /// Pixels in the mask where alpha > 0 will allow child content to show.
    /// The mask node is not rendered directly; only its alpha values are used.
    public var maskNode: SNNode?

    // MARK: - Mask Inversion

    /// Whether to invert the mask.
    /// When `true`, transparent pixels in the mask show content,
    /// and opaque pixels hide content.
    public var invertsMask: Bool = false

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    /// Creates a crop node with a mask.
    ///
    /// - Parameter maskNode: The node to use as a mask.
    public init(maskNode: SNNode) {
        super.init()
        self.maskNode = maskNode
    }

    // MARK: - Mask Helpers

    /// Creates a rectangular mask.
    ///
    /// - Parameter size: The size of the rectangular mask.
    /// - Returns: A sprite suitable for use as a rectangular mask.
    public static func rectangularMask(size: Size) -> SNSpriteNode {
        SNSpriteNode(color: .white, size: size)
    }

    /// Creates a mask from children bounding box.
    /// The mask will be a rectangle covering all children.
    public func createBoundingMask() -> SNSpriteNode? {
        guard !children.isEmpty else { return nil }

        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        for child in children {
            let frame = child.frame
            minX = min(minX, frame.minX)
            minY = min(minY, frame.minY)
            maxX = max(maxX, frame.maxX)
            maxY = max(maxY, frame.maxY)
        }

        let size = CGSize(width: maxX - minX, height: maxY - minY)
        let mask = SNSpriteNode(color: .white, size: size)
        mask.position = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        return mask
    }

    // MARK: - Frame

    /// The bounding frame of this crop node.
    /// Returns the mask frame if available, otherwise the children's bounding box.
    public override var frame: Rect {
        if let mask = maskNode {
            return mask.frame
        }
        return calculateAccumulatedFrame()
    }
}
