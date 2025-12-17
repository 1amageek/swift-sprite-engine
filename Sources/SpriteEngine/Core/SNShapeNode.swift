/// A node that renders a shape defined by a path.
///
/// `SNShapeNode` draws vector graphics using a path that can be stroked, filled, or both.
/// It's useful for drawing lines, rectangles, circles, and custom shapes.
///
/// ## Usage
/// ```swift
/// // Create a rectangle
/// let rect = SNShapeNode.rectangle(size: Size(width: 100, height: 50))
/// rect.fillColor = .blue
/// rect.strokeColor = .white
/// rect.lineWidth = 2
/// scene.addChild(rect)
///
/// // Create a circle
/// let circle = SNShapeNode.circle(radius: 30)
/// circle.fillColor = .red
/// scene.addChild(circle)
///
/// // Create a custom path
/// var path = ShapePath()
/// path.move(to: Point(x: 0, y: 0))
/// path.addLine(to: Point(x: 50, y: 100))
/// path.addLine(to: Point(x: 100, y: 0))
/// path.close()
/// let triangle = SNShapeNode(path: path)
/// triangle.fillColor = .green
/// ```
public final class SNShapeNode: SNNode {
    // MARK: - Path

    /// The path that defines the shape.
    public var path: ShapePath? {
        didSet {
            invalidateBounds()
        }
    }

    // MARK: - Fill Properties

    /// The color used to fill the shape's interior.
    /// Set to `nil` or `.clear` for no fill.
    public var fillColor: Color? = .white

    /// The texture used to fill the shape.
    public var fillTexture: SNTexture?

    // MARK: - Stroke Properties

    /// The color used to stroke the shape's outline.
    /// Set to `nil` or `.clear` for no stroke.
    public var strokeColor: Color? = .white

    /// The texture used to stroke the shape.
    public var strokeTexture: SNTexture?

    /// The width of the stroke in points.
    public var lineWidth: CGFloat = 1.0

    /// Whether the path is antialiased when rendered.
    public var isAntialiased: Bool = true

    // MARK: - Glow Effect

    /// The radius of the glow effect around the shape.
    /// Set to 0 for no glow.
    public var glowWidth: CGFloat = 0

    // MARK: - Line Cap and Join

    /// The style for line endpoints.
    public var lineCap: LineCap = .butt

    /// The style for line connections.
    public var lineJoin: LineJoin = .miter

    /// The limit for miter joins before they become bevel joins.
    public var miterLimit: CGFloat = 10

    // MARK: - Blending

    /// The blend mode used when rendering the shape.
    public var blendMode: SNBlendMode = .alpha

    // MARK: - Cached Bounds

    private var cachedBounds: Rect?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    /// Creates a shape node with the specified path.
    ///
    /// - Parameter path: The path defining the shape.
    public init(path: ShapePath) {
        super.init()
        self.path = path
    }

    // MARK: - Frame

    /// The bounding rectangle of the shape in parent coordinates.
    public override var frame: Rect {
        guard let bounds = pathBounds else {
            return Rect(origin: position, size: .zero)
        }

        let strokeOffset = lineWidth / 2
        return Rect(
            x: position.x + bounds.minX - strokeOffset,
            y: position.y + bounds.minY - strokeOffset,
            width: bounds.width + lineWidth,
            height: bounds.height + lineWidth
        )
    }

    /// The bounds of the path without stroke.
    private var pathBounds: Rect? {
        if let cached = cachedBounds {
            return cached
        }

        guard let path = path else { return nil }
        cachedBounds = path.boundingRect
        return cachedBounds
    }

    private func invalidateBounds() {
        cachedBounds = nil
    }
}

// MARK: - Line Cap Style

/// The style for line endpoints.
public enum LineCap: Int, Sendable {
    /// Squared-off endpoints.
    case butt = 0
    /// Rounded endpoints.
    case round = 1
    /// Squared endpoints that extend beyond the line.
    case square = 2
}

// MARK: - Line Join Style

/// The style for line connections.
public enum LineJoin: Int, Sendable {
    /// Sharp corners with a pointed join.
    case miter = 0
    /// Rounded corners.
    case round = 1
    /// Flat corners with a beveled join.
    case bevel = 2
}

// MARK: - Factory Methods

extension SNShapeNode {
    /// Creates a rectangular shape.
    ///
    /// - Parameter size: The size of the rectangle.
    /// - Returns: A shape node configured as a rectangle.
    public static func rectangle(size: Size) -> SNShapeNode {
        var path = ShapePath()
        path.addRect(Rect(origin: Point(x: -size.width / 2, y: -size.height / 2), size: size))
        let shape = SNShapeNode(path: path)
        return shape
    }

    /// Creates a rectangular shape with rounded corners.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle.
    ///   - cornerRadius: The radius of the corners.
    /// - Returns: A shape node configured as a rounded rectangle.
    public static func rectangle(size: Size, cornerRadius: CGFloat) -> SNShapeNode {
        var path = ShapePath()
        path.addRoundedRect(
            Rect(origin: Point(x: -size.width / 2, y: -size.height / 2), size: size),
            cornerRadius: cornerRadius
        )
        let shape = SNShapeNode(path: path)
        return shape
    }

    /// Creates a circular shape.
    ///
    /// - Parameter radius: The radius of the circle.
    /// - Returns: A shape node configured as a circle.
    public static func circle(radius: CGFloat) -> SNShapeNode {
        var path = ShapePath()
        path.addEllipse(in: Rect(
            x: -radius,
            y: -radius,
            width: radius * 2,
            height: radius * 2
        ))
        let shape = SNShapeNode(path: path)
        return shape
    }

    /// Creates an elliptical shape.
    ///
    /// - Parameter size: The size of the ellipse's bounding box.
    /// - Returns: A shape node configured as an ellipse.
    public static func ellipse(size: Size) -> SNShapeNode {
        var path = ShapePath()
        path.addEllipse(in: Rect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        ))
        let shape = SNShapeNode(path: path)
        return shape
    }

    /// Creates a line between two points.
    ///
    /// - Parameters:
    ///   - from: The starting point.
    ///   - to: The ending point.
    /// - Returns: A shape node configured as a line.
    public static func line(from: Point, to: Point) -> SNShapeNode {
        var path = ShapePath()
        path.move(to: from)
        path.addLine(to: to)
        let shape = SNShapeNode(path: path)
        shape.fillColor = nil
        return shape
    }

    /// Creates a polygon with the specified points.
    ///
    /// - Parameter points: The vertices of the polygon.
    /// - Returns: A shape node configured as a polygon.
    public static func polygon(points: [Point]) -> SNShapeNode {
        guard points.count >= 3 else {
            return SNShapeNode()
        }

        var path = ShapePath()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.close()

        let shape = SNShapeNode(path: path)
        return shape
    }

    /// Creates a regular polygon with the specified number of sides.
    ///
    /// - Parameters:
    ///   - sides: The number of sides (minimum 3).
    ///   - radius: The radius of the circumscribed circle.
    /// - Returns: A shape node configured as a regular polygon.
    public static func regularPolygon(sides: Int, radius: CGFloat) -> SNShapeNode {
        let n = max(3, sides)
        var points: [Point] = []

        for i in 0..<n {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(n) - .pi / 2
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            points.append(Point(x: x, y: y))
        }

        return polygon(points: points)
    }

    /// Creates a star shape.
    ///
    /// - Parameters:
    ///   - points: The number of points on the star.
    ///   - outerRadius: The radius to the outer points.
    ///   - innerRadius: The radius to the inner points.
    /// - Returns: A shape node configured as a star.
    public static func star(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> SNShapeNode {
        let n = max(3, points)
        var pathPoints: [Point] = []

        for i in 0..<(n * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(n) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            pathPoints.append(Point(x: x, y: y))
        }

        return polygon(points: pathPoints)
    }
}
