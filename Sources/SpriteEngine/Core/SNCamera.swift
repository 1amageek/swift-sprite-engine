/// A node that determines which portion of the scene is visible in the view.
///
/// `SNCamera` inherits from `SNNode`. Its position, rotation, and scale properties
/// directly control the viewport:
/// - **Position**: The center of the viewport in scene coordinates
/// - **Rotation**: Rotates the entire view
/// - **Scale**: Zooms in (>1) or out (<1)
///
/// ## Setup
/// ```swift
/// let camera = SNCamera()
/// scene.addChild(camera)  // Must be added to scene
/// scene.camera = camera    // Assign as active camera
/// ```
///
/// ## Following a Target
/// ```swift
/// override func update(dt: Float) {
///     camera?.position = player.position
/// }
/// ```
///
/// ## HUD Elements
/// Nodes added as children of the camera move with the viewport,
/// creating a HUD effect:
/// ```swift
/// let scoreLabel = SNLabelNode(text: "Score: 0")
/// scoreLabel.position = Point(x: -350, y: 250)  // Relative to camera
/// camera.addChild(scoreLabel)
/// ```
open class SNCamera: SNNode {
    // MARK: - Initialization

    /// Creates a camera node.
    public override init() {
        super.init()
    }

    // MARK: - Viewport Calculation

    /// Returns the viewport rectangle in scene coordinates.
    ///
    /// The viewport is centered at the camera's position and sized
    /// according to the scene's size and the camera's scale.
    ///
    /// - Parameter sceneSize: The scene's logical size.
    /// - Returns: The visible area in scene coordinates.
    public func viewport(for sceneSize: Size) -> Rect {
        let scaledWidth = sceneSize.width / scale.width
        let scaledHeight = sceneSize.height / scale.height

        return Rect(
            x: position.x - scaledWidth / 2,
            y: position.y - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )
    }

    // MARK: - Visibility Testing

    /// Returns `true` if the specified node is visible in the camera's viewport.
    ///
    /// - Parameters:
    ///   - node: The node to test.
    ///   - sceneSize: The scene's logical size.
    /// - Returns: `true` if any part of the node is visible.
    public func contains(_ node: SNNode, sceneSize: Size) -> Bool {
        let viewportRect = viewport(for: sceneSize)
        let nodeFrame = node.calculateAccumulatedFrame()

        // Transform node frame to world coordinates
        let worldFrame = Rect(
            origin: node.worldPosition,
            size: nodeFrame.size
        )

        return viewportRect.intersects(worldFrame)
    }

    /// Returns a set of all nodes from the scene that are visible in the viewport.
    ///
    /// This method finds all nodes that fall within the camera's viewport.
    /// Nodes that are children of the camera (HUD elements) are excluded from
    /// this check as they are always visible by definition.
    ///
    /// - Returns: A set of visible nodes.
    public func containedNodeSet() -> Set<SNNode> {
        guard let scene = scene else { return [] }

        var visibleNodes: [SNNode] = []
        collectVisibleNodes(from: scene, viewport: viewport(for: scene.size), into: &visibleNodes)
        return Set(visibleNodes)
    }

    /// Recursively collects visible nodes.
    private func collectVisibleNodes(from node: SNNode, viewport: Rect, into result: inout [SNNode]) {
        // Skip hidden nodes
        guard !node.isHidden else { return }

        // Check if this node is visible
        if let sprite = node as? SNSpriteNode {
            let worldPos = sprite.worldPosition
            let size = sprite.size
            let anchor = sprite.anchorPoint

            let spriteBounds = Rect(
                x: worldPos.x - size.width * anchor.x,
                y: worldPos.y - size.height * anchor.y,
                width: size.width,
                height: size.height
            )

            if viewport.intersects(spriteBounds) {
                result.append(sprite)
            }
        }

        // Recurse into children (but not into this camera's children for visibility check)
        if node !== self {
            for child in node.children {
                collectVisibleNodes(from: child, viewport: viewport, into: &result)
            }
        }
    }

    // MARK: - View Transform

    /// Returns the view transform matrix.
    ///
    /// This transform converts from scene coordinates to view coordinates,
    /// accounting for the camera's position, rotation, and scale.
    public func viewTransform(sceneSize: Size, viewSize: Size) -> AffineTransform {
        // Start with identity
        var transform = AffineTransform.identity

        // Move origin to view center
        transform = transform.translated(x: viewSize.width / 2, y: viewSize.height / 2)

        // Apply camera scale (zoom)
        transform = transform.scaled(x: scale.width, y: scale.height)

        // Apply camera rotation (negated because we're transforming the world, not the camera)
        transform = transform.rotated(by: -rotation)

        // Translate by negated camera position
        transform = transform.translated(x: -position.x, y: -position.y)

        return transform
    }

    // MARK: - Convenience Properties

    /// Sets uniform zoom level.
    ///
    /// - Parameter zoom: The zoom factor. Values > 1 zoom in, < 1 zoom out.
    @inlinable
    public func setZoom(_ zoom: Float) {
        scale = Size(width: zoom, height: zoom)
    }

    /// Returns the current zoom level (assuming uniform scale).
    @inlinable
    public var zoom: Float {
        get { scale.width }
        set { scale = Size(width: newValue, height: newValue) }
    }

    /// Smoothly moves the camera toward a target position.
    ///
    /// - Parameters:
    ///   - target: The target position.
    ///   - smoothing: The smoothing factor (higher = faster).
    ///   - dt: The delta time.
    @inlinable
    public func smoothFollow(target: Point, smoothing: Float, dt: Float) {
        let factor = min(1.0, smoothing * dt)
        position = Point.lerp(from: position, to: target, t: factor)
    }

    /// Clamps the camera position within bounds.
    ///
    /// - Parameters:
    ///   - bounds: The allowable bounds for the camera position.
    ///   - sceneSize: The scene's logical size.
    @inlinable
    public func clampToBounds(_ bounds: Rect, sceneSize: Size) {
        let vp = viewport(for: sceneSize)
        let halfWidth = vp.width / 2
        let halfHeight = vp.height / 2

        position.x = max(bounds.minX + halfWidth, min(bounds.maxX - halfWidth, position.x))
        position.y = max(bounds.minY + halfHeight, min(bounds.maxY - halfHeight, position.y))
    }

    // MARK: - CustomStringConvertible

    open override var description: String {
        let nameStr = name.map { "\"\($0)\"" } ?? "unnamed"
        return "SNCamera(\(nameStr), pos: \(position), zoom: \(zoom))"
    }
}
