/// CoreGraphics Compatibility Layer
///
/// This file provides unified access to CoreGraphics types across all platforms.
/// - On Apple platforms: Uses native CoreGraphics
/// - On WASM: Uses OpenCoreGraphics (API-compatible implementation)
///
/// Usage:
/// ```swift
/// // These types are available everywhere:
/// let point = CGPoint(x: 100, y: 200)
/// let size = CGSize(width: 400, height: 300)
/// let rect = CGRect(origin: point, size: size)
/// ```

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#else
@_exported import OpenCoreGraphics
#endif

// MARK: - CGVector Extensions for Game Development

extension CGVector {
    /// A unit vector pointing in the positive x direction (1, 0).
    @inlinable
    public static var unitX: CGVector {
        CGVector(dx: 1, dy: 0)
    }

    /// A unit vector pointing in the positive y direction (0, 1).
    @inlinable
    public static var unitY: CGVector {
        CGVector(dx: 0, dy: 1)
    }

    /// Creates a vector from a point (treating the point as a position vector from origin).
    @inlinable
    public init(_ point: CGPoint) {
        self.init(dx: point.x, dy: point.y)
    }

    /// Creates a vector from an angle and magnitude.
    ///
    /// - Parameters:
    ///   - angle: The angle in radians, measured counter-clockwise from the positive x-axis.
    ///   - magnitude: The length of the vector.
    @inlinable
    public init(angle: CGFloat, magnitude: CGFloat = 1) {
        self.init(dx: cos(angle) * magnitude, dy: sin(angle) * magnitude)
    }

    /// Creates a unit vector from an angle.
    ///
    /// - Parameter angle: The angle in radians, measured counter-clockwise from the positive x-axis.
    @inlinable
    public static func unit(angle: CGFloat) -> CGVector {
        CGVector(angle: angle, magnitude: 1)
    }

    /// The length (magnitude) of the vector.
    @inlinable
    public var magnitude: CGFloat {
        (dx * dx + dy * dy).squareRoot()
    }

    /// The squared length of the vector.
    ///
    /// This is faster than `magnitude` when you only need to compare lengths.
    @inlinable
    public var magnitudeSquared: CGFloat {
        dx * dx + dy * dy
    }

    /// The angle of the vector in radians, measured counter-clockwise from the positive x-axis.
    ///
    /// Returns a value in the range [-π, π].
    @inlinable
    public var angle: CGFloat {
        atan2(dy, dx)
    }

    /// Returns a unit vector with the same direction as this vector.
    ///
    /// If this vector has zero length, returns the zero vector.
    @inlinable
    public var normalized: CGVector {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return CGVector(dx: dx / mag, dy: dy / mag)
    }

    /// Normalizes this vector in place.
    @inlinable
    public mutating func normalize() {
        self = normalized
    }

    /// Returns `true` if this vector has zero length.
    @inlinable
    public var isZero: Bool {
        dx == 0 && dy == 0
    }

    /// Returns the dot product of two vectors.
    @inlinable
    public func dot(_ other: CGVector) -> CGFloat {
        dx * other.dx + dy * other.dy
    }

    /// Returns the 2D cross product (perpendicular dot product).
    @inlinable
    public func cross(_ other: CGVector) -> CGFloat {
        dx * other.dy - dy * other.dx
    }

    /// Returns this vector rotated by the specified angle.
    ///
    /// - Parameter angle: The angle in radians to rotate counter-clockwise.
    @inlinable
    public func rotated(by angle: CGFloat) -> CGVector {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return CGVector(
            dx: dx * cosAngle - dy * sinAngle,
            dy: dx * sinAngle + dy * cosAngle
        )
    }

    /// Rotates this vector in place.
    @inlinable
    public mutating func rotate(by angle: CGFloat) {
        self = rotated(by: angle)
    }

    /// Returns a vector perpendicular to this one (rotated 90° counter-clockwise).
    @inlinable
    public var perpendicular: CGVector {
        CGVector(dx: -dy, dy: dx)
    }

    /// Returns the projection of this vector onto another vector.
    @inlinable
    public func projected(onto other: CGVector) -> CGVector {
        let dotProduct = dot(other)
        let otherMagSquared = other.magnitudeSquared
        guard otherMagSquared > 0 else { return .zero }
        let scale = dotProduct / otherMagSquared
        return CGVector(dx: other.dx * scale, dy: other.dy * scale)
    }

    /// Returns the reflection of this vector off a surface with the given normal.
    ///
    /// - Parameter normal: The surface normal (should be normalized).
    @inlinable
    public func reflected(normal: CGVector) -> CGVector {
        let dotProduct = dot(normal)
        return CGVector(
            dx: dx - 2 * dotProduct * normal.dx,
            dy: dy - 2 * dotProduct * normal.dy
        )
    }

    /// Returns a vector interpolated between two vectors.
    @inlinable
    public static func lerp(from start: CGVector, to end: CGVector, t: CGFloat) -> CGVector {
        CGVector(
            dx: start.dx + (end.dx - start.dx) * t,
            dy: start.dy + (end.dy - start.dy) * t
        )
    }

    /// Returns the angle between this vector and another vector.
    ///
    /// - Returns: The angle in radians, in the range [0, π].
    @inlinable
    public func angle(to other: CGVector) -> CGFloat {
        let dotProd = dot(other)
        let mags = magnitude * other.magnitude
        guard mags > 0 else { return 0 }
        let cosAngle = max(-1, min(1, dotProd / mags))
        return acos(cosAngle)
    }

    /// Returns the signed angle from this vector to another vector.
    ///
    /// - Returns: The angle in radians, in the range [-π, π].
    ///   Positive values indicate counter-clockwise rotation.
    @inlinable
    public func signedAngle(to other: CGVector) -> CGFloat {
        atan2(cross(other), dot(other))
    }
}

// MARK: - CGVector Arithmetic Operators

extension CGVector {
    /// Returns the negation of a vector.
    @inlinable
    public static prefix func - (vector: CGVector) -> CGVector {
        CGVector(dx: -vector.dx, dy: -vector.dy)
    }

    /// Returns the sum of two vectors.
    @inlinable
    public static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    /// Returns the difference of two vectors.
    @inlinable
    public static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    /// Adds a vector and stores the result.
    @inlinable
    public static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs.dx += rhs.dx
        lhs.dy += rhs.dy
    }

    /// Subtracts a vector and stores the result.
    @inlinable
    public static func -= (lhs: inout CGVector, rhs: CGVector) {
        lhs.dx -= rhs.dx
        lhs.dy -= rhs.dy
    }

    /// Returns a vector multiplied by a scalar.
    @inlinable
    public static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    /// Returns a vector multiplied by a scalar.
    @inlinable
    public static func * (scalar: CGFloat, vector: CGVector) -> CGVector {
        CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    /// Returns a vector divided by a scalar.
    @inlinable
    public static func / (vector: CGVector, scalar: CGFloat) -> CGVector {
        CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }

    /// Multiplies by a scalar and stores the result.
    @inlinable
    public static func *= (vector: inout CGVector, scalar: CGFloat) {
        vector.dx *= scalar
        vector.dy *= scalar
    }

    /// Divides by a scalar and stores the result.
    @inlinable
    public static func /= (vector: inout CGVector, scalar: CGFloat) {
        vector.dx /= scalar
        vector.dy /= scalar
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    /// Adds a vector to this point.
    @inlinable
    public static func + (point: CGPoint, vector: CGVector) -> CGPoint {
        CGPoint(x: point.x + vector.dx, y: point.y + vector.dy)
    }

    /// Subtracts a vector from this point.
    @inlinable
    public static func - (point: CGPoint, vector: CGVector) -> CGPoint {
        CGPoint(x: point.x - vector.dx, y: point.y - vector.dy)
    }

    /// Adds a vector to this point and stores the result.
    @inlinable
    public static func += (point: inout CGPoint, vector: CGVector) {
        point.x += vector.dx
        point.y += vector.dy
    }

    /// Subtracts a vector from this point and stores the result.
    @inlinable
    public static func -= (point: inout CGPoint, vector: CGVector) {
        point.x -= vector.dx
        point.y -= vector.dy
    }

    /// Returns the vector from this point to another point.
    @inlinable
    public func vector(to other: CGPoint) -> CGVector {
        CGVector(dx: other.x - x, dy: other.y - y)
    }

    /// Returns the distance from this point to another point.
    @inlinable
    public func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }

    /// Returns the squared distance from this point to another point.
    @inlinable
    public func distanceSquared(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return dx * dx + dy * dy
    }

    /// Returns a point interpolated between two points.
    @inlinable
    public static func lerp(from start: CGPoint, to end: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: start.y + (end.y - start.y) * t
        )
    }
}

// MARK: - CGPoint Arithmetic Operators

extension CGPoint {
    /// Returns a point with each coordinate negated.
    @inlinable
    public static prefix func - (point: CGPoint) -> CGPoint {
        CGPoint(x: -point.x, y: -point.y)
    }

    /// Returns the sum of two points.
    @inlinable
    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    /// Returns the difference of two points.
    @inlinable
    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    /// Adds two points and stores the result.
    @inlinable
    public static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    /// Subtracts two points and stores the result.
    @inlinable
    public static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    /// Returns a point with each coordinate multiplied by a scalar.
    @inlinable
    public static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    /// Returns a point with each coordinate multiplied by a scalar.
    @inlinable
    public static func * (scalar: CGFloat, point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    /// Returns a point with each coordinate divided by a scalar.
    @inlinable
    public static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x / scalar, y: point.y / scalar)
    }

    /// Multiplies each coordinate by a scalar and stores the result.
    @inlinable
    public static func *= (point: inout CGPoint, scalar: CGFloat) {
        point.x *= scalar
        point.y *= scalar
    }

    /// Divides each coordinate by a scalar and stores the result.
    @inlinable
    public static func /= (point: inout CGPoint, scalar: CGFloat) {
        point.x /= scalar
        point.y /= scalar
    }
}

// MARK: - CGSize Extensions

extension CGSize {
    /// Creates a square size with equal width and height.
    @inlinable
    public init(square: CGFloat) {
        self.init(width: square, height: square)
    }

    /// Returns the area (width × height).
    @inlinable
    public var area: CGFloat {
        width * height
    }

    /// Returns the aspect ratio (width / height).
    @inlinable
    public var aspectRatio: CGFloat {
        guard height != 0 else { return .infinity }
        return width / height
    }

    /// Returns `true` if both width and height are zero.
    @inlinable
    public var isEmpty: Bool {
        width == 0 && height == 0
    }

    /// Returns the diagonal length of the size.
    @inlinable
    public var diagonal: CGFloat {
        (width * width + height * height).squareRoot()
    }

    /// Returns a size that fits within the target size while maintaining aspect ratio.
    @inlinable
    public func aspectFit(in target: CGSize) -> CGSize {
        guard width > 0 && height > 0 else { return .zero }
        let widthRatio = target.width / width
        let heightRatio = target.height / height
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: width * scale, height: height * scale)
    }

    /// Returns a size that fills the target size while maintaining aspect ratio.
    @inlinable
    public func aspectFill(in target: CGSize) -> CGSize {
        guard width > 0 && height > 0 else { return target }
        let widthRatio = target.width / width
        let heightRatio = target.height / height
        let scale = max(widthRatio, heightRatio)
        return CGSize(width: width * scale, height: height * scale)
    }

    /// Returns a size interpolated between two sizes.
    @inlinable
    public static func lerp(from start: CGSize, to end: CGSize, t: CGFloat) -> CGSize {
        CGSize(
            width: start.width + (end.width - start.width) * t,
            height: start.height + (end.height - start.height) * t
        )
    }
}

// MARK: - CGSize Arithmetic Operators

extension CGSize {
    /// Returns a size with each dimension multiplied by a scalar.
    @inlinable
    public static func * (size: CGSize, scalar: CGFloat) -> CGSize {
        CGSize(width: size.width * scalar, height: size.height * scalar)
    }

    /// Returns a size with each dimension multiplied by a scalar.
    @inlinable
    public static func * (scalar: CGFloat, size: CGSize) -> CGSize {
        CGSize(width: size.width * scalar, height: size.height * scalar)
    }

    /// Returns a size with each dimension divided by a scalar.
    @inlinable
    public static func / (size: CGSize, scalar: CGFloat) -> CGSize {
        CGSize(width: size.width / scalar, height: size.height / scalar)
    }

    /// Multiplies each dimension by a scalar and stores the result.
    @inlinable
    public static func *= (size: inout CGSize, scalar: CGFloat) {
        size.width *= scalar
        size.height *= scalar
    }

    /// Divides each dimension by a scalar and stores the result.
    @inlinable
    public static func /= (size: inout CGSize, scalar: CGFloat) {
        size.width /= scalar
        size.height /= scalar
    }

    /// Returns a size with each dimension added.
    @inlinable
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    /// Returns a size with each dimension subtracted.
    @inlinable
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}

// MARK: - CGRect Extensions

extension CGRect {
    /// Creates a rectangle centered at a point with the specified size.
    @inlinable
    public init(center: CGPoint, size: CGSize) {
        self.init(
            origin: CGPoint(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2
            ),
            size: size
        )
    }

    /// Creates a rectangle that contains two points.
    @inlinable
    public init(from point1: CGPoint, to point2: CGPoint) {
        let minX = min(point1.x, point2.x)
        let minY = min(point1.y, point2.y)
        let maxX = max(point1.x, point2.x)
        let maxY = max(point1.y, point2.y)
        self.init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// The center point of the rectangle.
    @inlinable
    public var center: CGPoint {
        get { CGPoint(x: midX, y: midY) }
        set {
            origin.x = newValue.x - size.width / 2
            origin.y = newValue.y - size.height / 2
        }
    }

    /// The bottom-left corner of the rectangle.
    @inlinable
    public var bottomLeft: CGPoint { CGPoint(x: minX, y: minY) }

    /// The bottom-right corner of the rectangle.
    @inlinable
    public var bottomRight: CGPoint { CGPoint(x: maxX, y: minY) }

    /// The top-left corner of the rectangle.
    @inlinable
    public var topLeft: CGPoint { CGPoint(x: minX, y: maxY) }

    /// The top-right corner of the rectangle.
    @inlinable
    public var topRight: CGPoint { CGPoint(x: maxX, y: maxY) }

    /// Returns a rectangle expanded by the specified amount on all sides.
    @inlinable
    public func expanded(by amount: CGFloat) -> CGRect {
        insetBy(dx: -amount, dy: -amount)
    }

    /// Returns a rectangle contracted by the specified amount on all sides.
    @inlinable
    public func contracted(by amount: CGFloat) -> CGRect {
        insetBy(dx: amount, dy: amount)
    }

    /// Returns the area of the rectangle.
    @inlinable
    public var area: CGFloat {
        size.width * size.height
    }

    /// Returns `true` if the width or height is zero or negative.
    @inlinable
    public var hasZeroArea: Bool {
        size.width <= 0 || size.height <= 0
    }

    /// Returns the smallest rectangle that contains this rectangle and a point.
    @inlinable
    public func union(_ point: CGPoint) -> CGRect {
        if isNull {
            return CGRect(origin: point, size: .zero)
        }
        let x1 = min(minX, point.x)
        let y1 = min(minY, point.y)
        let x2 = max(maxX, point.x)
        let y2 = max(maxY, point.y)
        return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }
}

// MARK: - CGAffineTransform Extensions

extension CGAffineTransform {
    /// Creates a shear (skew) transform.
    @inlinable
    public static func shear(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(a: 1, b: y, c: x, d: 1, tx: 0, ty: 0)
    }

    /// The determinant of the matrix.
    @inlinable
    public var determinant: CGFloat {
        a * d - b * c
    }

    /// Returns `true` if this transform is invertible.
    @inlinable
    public var isInvertible: Bool {
        determinant != 0
    }

    /// The translation component as a vector.
    @inlinable
    public var translation: CGVector {
        get { CGVector(dx: tx, dy: ty) }
        set {
            tx = newValue.dx
            ty = newValue.dy
        }
    }

    /// Transforms a vector using this affine transform.
    @inlinable
    public func transform(_ vector: CGVector) -> CGVector {
        CGVector(
            dx: a * vector.dx + c * vector.dy,
            dy: b * vector.dx + d * vector.dy
        )
    }

    /// Transforms a size using this affine transform.
    @inlinable
    public func transform(_ size: CGSize) -> CGSize {
        CGSize(
            width: a * size.width + c * size.height,
            height: b * size.width + d * size.height
        )
    }

    /// Concatenates two transforms using the * operator.
    @inlinable
    public static func * (lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        lhs.concatenating(rhs)
    }

    /// Concatenates another transform onto this one.
    @inlinable
    public static func *= (lhs: inout CGAffineTransform, rhs: CGAffineTransform) {
        lhs = lhs.concatenating(rhs)
    }
}

// MARK: - Math Functions (Platform-agnostic)

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif arch(wasm32)
import WASILibc
#endif
