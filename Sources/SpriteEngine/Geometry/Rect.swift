/// A structure that contains the location and dimensions of a rectangle.
///
/// `Rect` is the Wisp equivalent of CoreGraphics' `CGRect`.
/// It uses `Float` instead of `CGFloat` for WebAssembly compatibility.
public struct Rect: Hashable, Sendable {
    /// The origin of the rectangle (bottom-left corner in a y-up coordinate system).
    public var origin: Point

    /// The size of the rectangle.
    public var size: Size

    /// Creates a rectangle with the specified origin and size.
    @inlinable
    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    /// A rectangle with zero origin and zero size.
    public static let zero = Rect(origin: .zero, size: .zero)

    /// A null rectangle, representing an invalid or undefined rectangle.
    public static let null = Rect(origin: Point(x: .infinity, y: .infinity), size: .zero)
}

// MARK: - Convenience Initializers

extension Rect {
    /// Creates a rectangle with coordinates and size specified as floating-point values.
    @inlinable
    public init(x: Float, y: Float, width: Float, height: Float) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }

    /// Creates a rectangle that contains two points.
    @inlinable
    public init(from point1: Point, to point2: Point) {
        let minX = min(point1.x, point2.x)
        let minY = min(point1.y, point2.y)
        let maxX = max(point1.x, point2.x)
        let maxY = max(point1.y, point2.y)
        self.origin = Point(x: minX, y: minY)
        self.size = Size(width: maxX - minX, height: maxY - minY)
    }

    /// Creates a rectangle centered at a point with the specified size.
    @inlinable
    public init(center: Point, size: Size) {
        self.origin = Point(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
        self.size = size
    }
}

// MARK: - Coordinate Accessors

extension Rect {
    /// The x-coordinate of the origin.
    @inlinable
    public var x: Float {
        get { origin.x }
        set { origin.x = newValue }
    }

    /// The y-coordinate of the origin.
    @inlinable
    public var y: Float {
        get { origin.y }
        set { origin.y = newValue }
    }

    /// The width of the rectangle.
    @inlinable
    public var width: Float {
        get { size.width }
        set { size.width = newValue }
    }

    /// The height of the rectangle.
    @inlinable
    public var height: Float {
        get { size.height }
        set { size.height = newValue }
    }
}

// MARK: - Edge Accessors

extension Rect {
    /// The minimum x-coordinate (left edge).
    @inlinable
    public var minX: Float { origin.x }

    /// The x-coordinate of the center.
    @inlinable
    public var midX: Float { origin.x + size.width / 2 }

    /// The maximum x-coordinate (right edge).
    @inlinable
    public var maxX: Float { origin.x + size.width }

    /// The minimum y-coordinate (bottom edge).
    @inlinable
    public var minY: Float { origin.y }

    /// The y-coordinate of the center.
    @inlinable
    public var midY: Float { origin.y + size.height / 2 }

    /// The maximum y-coordinate (top edge).
    @inlinable
    public var maxY: Float { origin.y + size.height }

    /// The center point of the rectangle.
    @inlinable
    public var center: Point {
        get { Point(x: midX, y: midY) }
        set {
            origin.x = newValue.x - size.width / 2
            origin.y = newValue.y - size.height / 2
        }
    }
}

// MARK: - Corner Points

extension Rect {
    /// The bottom-left corner of the rectangle.
    @inlinable
    public var bottomLeft: Point { origin }

    /// The bottom-right corner of the rectangle.
    @inlinable
    public var bottomRight: Point { Point(x: maxX, y: minY) }

    /// The top-left corner of the rectangle.
    @inlinable
    public var topLeft: Point { Point(x: minX, y: maxY) }

    /// The top-right corner of the rectangle.
    @inlinable
    public var topRight: Point { Point(x: maxX, y: maxY) }
}

// MARK: - Predicates

extension Rect {
    /// Returns `true` if the rectangle has zero width and height.
    @inlinable
    public var isEmpty: Bool {
        size.width == 0 && size.height == 0
    }

    /// Returns `true` if this is a null rectangle.
    @inlinable
    public var isNull: Bool {
        origin.x == .infinity || origin.y == .infinity
    }

    /// Returns `true` if the width or height is zero or negative.
    @inlinable
    public var hasZeroArea: Bool {
        size.width <= 0 || size.height <= 0
    }

    /// Returns the area of the rectangle.
    @inlinable
    public var area: Float {
        size.width * size.height
    }
}

// MARK: - Point Containment

extension Rect {
    /// Returns `true` if the rectangle contains the specified point.
    @inlinable
    public func contains(_ point: Point) -> Bool {
        point.x >= minX && point.x < maxX &&
        point.y >= minY && point.y < maxY
    }

    /// Returns `true` if this rectangle completely contains another rectangle.
    @inlinable
    public func contains(_ rect: Rect) -> Bool {
        rect.minX >= minX && rect.maxX <= maxX &&
        rect.minY >= minY && rect.maxY <= maxY
    }
}

// MARK: - Intersection

extension Rect {
    /// Returns `true` if this rectangle intersects another rectangle.
    @inlinable
    public func intersects(_ other: Rect) -> Bool {
        minX < other.maxX && maxX > other.minX &&
        minY < other.maxY && maxY > other.minY
    }

    /// Returns the intersection of this rectangle and another rectangle.
    ///
    /// Returns `Rect.null` if the rectangles do not intersect.
    @inlinable
    public func intersection(_ other: Rect) -> Rect {
        let x1 = max(minX, other.minX)
        let y1 = max(minY, other.minY)
        let x2 = min(maxX, other.maxX)
        let y2 = min(maxY, other.maxY)

        if x2 <= x1 || y2 <= y1 {
            return .null
        }

        return Rect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }
}

// MARK: - Union

extension Rect {
    /// Returns the smallest rectangle that contains both this rectangle and another rectangle.
    @inlinable
    public func union(_ other: Rect) -> Rect {
        if isNull { return other }
        if other.isNull { return self }

        let x1 = min(minX, other.minX)
        let y1 = min(minY, other.minY)
        let x2 = max(maxX, other.maxX)
        let y2 = max(maxY, other.maxY)

        return Rect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }

    /// Returns the smallest rectangle that contains this rectangle and a point.
    @inlinable
    public func union(_ point: Point) -> Rect {
        if isNull {
            return Rect(origin: point, size: .zero)
        }

        let x1 = min(minX, point.x)
        let y1 = min(minY, point.y)
        let x2 = max(maxX, point.x)
        let y2 = max(maxY, point.y)

        return Rect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }
}

// MARK: - Transformations

extension Rect {
    /// Returns a rectangle with the origin offset by the specified amounts.
    @inlinable
    public func offsetBy(dx: Float, dy: Float) -> Rect {
        Rect(origin: Point(x: origin.x + dx, y: origin.y + dy), size: size)
    }

    /// Returns a rectangle inset by the specified amounts.
    ///
    /// Positive values shrink the rectangle; negative values expand it.
    @inlinable
    public func insetBy(dx: Float, dy: Float) -> Rect {
        Rect(
            x: origin.x + dx,
            y: origin.y + dy,
            width: size.width - dx * 2,
            height: size.height - dy * 2
        )
    }

    /// Returns a rectangle expanded by the specified amount on all sides.
    @inlinable
    public func expanded(by amount: Float) -> Rect {
        insetBy(dx: -amount, dy: -amount)
    }

    /// Returns a rectangle contracted by the specified amount on all sides.
    @inlinable
    public func contracted(by amount: Float) -> Rect {
        insetBy(dx: amount, dy: amount)
    }
}

// MARK: - Standardization

extension Rect {
    /// Returns a rectangle with positive width and height.
    ///
    /// If the width or height is negative, the origin is adjusted and the
    /// dimension is made positive.
    @inlinable
    public var standardized: Rect {
        var result = self
        if result.size.width < 0 {
            result.origin.x += result.size.width
            result.size.width = -result.size.width
        }
        if result.size.height < 0 {
            result.origin.y += result.size.height
            result.size.height = -result.size.height
        }
        return result
    }
}

// MARK: - CustomStringConvertible

extension Rect: CustomStringConvertible {
    public var description: String {
        "(x: \(origin.x), y: \(origin.y), width: \(size.width), height: \(size.height))"
    }
}

// MARK: - Codable

extension Rect: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Float.self)
        let y = try container.decode(Float.self)
        let width = try container.decode(Float.self)
        let height = try container.decode(Float.self)
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(origin.x)
        try container.encode(origin.y)
        try container.encode(size.width)
        try container.encode(size.height)
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension Rect {
    /// Creates a `Rect` from a `CGRect`.
    @inlinable
    public init(_ cgRect: CGRect) {
        self.origin = Point(cgRect.origin)
        self.size = Size(cgRect.size)
    }

    /// Returns this rectangle as a `CGRect`.
    @inlinable
    public var cgRect: CGRect {
        CGRect(origin: origin.cgPoint, size: size.cgSize)
    }
}

extension CGRect {
    /// Creates a `CGRect` from a `Rect`.
    @inlinable
    public init(_ rect: Rect) {
        self.init(origin: rect.origin.cgPoint, size: rect.size.cgSize)
    }
}
#endif
