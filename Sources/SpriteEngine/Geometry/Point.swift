/// A structure that contains a point in a two-dimensional coordinate system.
///
/// `Point` is the Wisp equivalent of CoreGraphics' `CGPoint`.
/// It uses `Float` instead of `CGFloat` for WebAssembly compatibility.
public struct Point: Hashable, Sendable {
    /// The x-coordinate of the point.
    public var x: Float

    /// The y-coordinate of the point.
    public var y: Float

    /// Creates a point with coordinates specified as floating-point values.
    @inlinable
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    /// The point with location (0, 0).
    public static let zero = Point(x: 0, y: 0)
}

// MARK: - Arithmetic Operations

extension Point {
    /// Returns a point with each coordinate negated.
    @inlinable
    public static prefix func - (point: Point) -> Point {
        Point(x: -point.x, y: -point.y)
    }

    /// Returns the sum of two points.
    @inlinable
    public static func + (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    /// Returns the difference of two points.
    @inlinable
    public static func - (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// Adds two points and stores the result in the left-hand-side variable.
    @inlinable
    public static func += (lhs: inout Point, rhs: Point) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    /// Subtracts two points and stores the result in the left-hand-side variable.
    @inlinable
    public static func -= (lhs: inout Point, rhs: Point) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    /// Returns a point with each coordinate multiplied by a scalar.
    @inlinable
    public static func * (point: Point, scalar: Float) -> Point {
        Point(x: point.x * scalar, y: point.y * scalar)
    }

    /// Returns a point with each coordinate multiplied by a scalar.
    @inlinable
    public static func * (scalar: Float, point: Point) -> Point {
        Point(x: point.x * scalar, y: point.y * scalar)
    }

    /// Returns a point with each coordinate divided by a scalar.
    @inlinable
    public static func / (point: Point, scalar: Float) -> Point {
        Point(x: point.x / scalar, y: point.y / scalar)
    }

    /// Multiplies each coordinate by a scalar and stores the result.
    @inlinable
    public static func *= (point: inout Point, scalar: Float) {
        point.x *= scalar
        point.y *= scalar
    }

    /// Divides each coordinate by a scalar and stores the result.
    @inlinable
    public static func /= (point: inout Point, scalar: Float) {
        point.x /= scalar
        point.y /= scalar
    }
}

// MARK: - Vector Operations

extension Point {
    /// Adds a vector to this point.
    @inlinable
    public static func + (point: Point, vector: Vector2) -> Point {
        Point(x: point.x + vector.dx, y: point.y + vector.dy)
    }

    /// Subtracts a vector from this point.
    @inlinable
    public static func - (point: Point, vector: Vector2) -> Point {
        Point(x: point.x - vector.dx, y: point.y - vector.dy)
    }

    /// Adds a vector to this point and stores the result.
    @inlinable
    public static func += (point: inout Point, vector: Vector2) {
        point.x += vector.dx
        point.y += vector.dy
    }

    /// Subtracts a vector from this point and stores the result.
    @inlinable
    public static func -= (point: inout Point, vector: Vector2) {
        point.x -= vector.dx
        point.y -= vector.dy
    }

    /// Returns the vector from this point to another point.
    @inlinable
    public func vector(to other: Point) -> Vector2 {
        Vector2(dx: other.x - x, dy: other.y - y)
    }
}

// MARK: - Distance

extension Point {
    /// Returns the distance from this point to another point.
    @inlinable
    public func distance(to other: Point) -> Float {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Returns the squared distance from this point to another point.
    ///
    /// This is faster than `distance(to:)` when you only need to compare distances.
    @inlinable
    public func distanceSquared(to other: Point) -> Float {
        let dx = other.x - x
        let dy = other.y - y
        return dx * dx + dy * dy
    }
}

// MARK: - Interpolation

extension Point {
    /// Returns a point interpolated between two points.
    ///
    /// - Parameters:
    ///   - start: The starting point (t = 0).
    ///   - end: The ending point (t = 1).
    ///   - t: The interpolation factor, typically in the range [0, 1].
    /// - Returns: The interpolated point.
    @inlinable
    public static func lerp(from start: Point, to end: Point, t: Float) -> Point {
        Point(
            x: start.x + (end.x - start.x) * t,
            y: start.y + (end.y - start.y) * t
        )
    }
}

// MARK: - CustomStringConvertible

extension Point: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}

// MARK: - Codable

extension Point: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(Float.self)
        y = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension Point {
    /// Creates a `Point` from a `CGPoint`.
    @inlinable
    public init(_ cgPoint: CGPoint) {
        self.x = Float(cgPoint.x)
        self.y = Float(cgPoint.y)
    }

    /// Returns this point as a `CGPoint`.
    @inlinable
    public var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

extension CGPoint {
    /// Creates a `CGPoint` from a `Point`.
    @inlinable
    public init(_ point: Point) {
        self.init(x: CGFloat(point.x), y: CGFloat(point.y))
    }
}
#endif
