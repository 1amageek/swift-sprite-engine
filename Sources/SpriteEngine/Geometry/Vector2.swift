/// A structure that contains a two-dimensional vector.
///
/// `Vector2` is the Wisp equivalent of CoreGraphics' `CGVector`.
/// It represents a direction and magnitude in 2D space.
public struct Vector2: Hashable, Sendable {
    /// The x component of the vector.
    public var dx: Float

    /// The y component of the vector.
    public var dy: Float

    /// Creates a vector with the specified components.
    @inlinable
    public init(dx: Float, dy: Float) {
        self.dx = dx
        self.dy = dy
    }

    /// The zero vector (0, 0).
    public static let zero = Vector2(dx: 0, dy: 0)

    /// A unit vector pointing in the positive x direction (1, 0).
    public static let unitX = Vector2(dx: 1, dy: 0)

    /// A unit vector pointing in the positive y direction (0, 1).
    public static let unitY = Vector2(dx: 0, dy: 1)
}

// MARK: - Convenience Initializers

extension Vector2 {
    /// Creates a vector from a point (treating the point as a position vector from origin).
    @inlinable
    public init(_ point: Point) {
        self.dx = point.x
        self.dy = point.y
    }

    /// Creates a vector from an angle and magnitude.
    ///
    /// - Parameters:
    ///   - angle: The angle in radians, measured counter-clockwise from the positive x-axis.
    ///   - magnitude: The length of the vector.
    @inlinable
    public init(angle: Float, magnitude: Float = 1) {
        self.dx = cos(angle) * magnitude
        self.dy = sin(angle) * magnitude
    }

    /// Creates a unit vector from an angle.
    ///
    /// - Parameter angle: The angle in radians, measured counter-clockwise from the positive x-axis.
    @inlinable
    public static func unit(angle: Float) -> Vector2 {
        Vector2(angle: angle, magnitude: 1)
    }
}

// MARK: - Magnitude and Direction

extension Vector2 {
    /// The length (magnitude) of the vector.
    @inlinable
    public var magnitude: Float {
        (dx * dx + dy * dy).squareRoot()
    }

    /// The squared length of the vector.
    ///
    /// This is faster than `magnitude` when you only need to compare lengths.
    @inlinable
    public var magnitudeSquared: Float {
        dx * dx + dy * dy
    }

    /// The angle of the vector in radians, measured counter-clockwise from the positive x-axis.
    ///
    /// Returns a value in the range [-π, π].
    @inlinable
    public var angle: Float {
        atan2(dy, dx)
    }

    /// Returns a unit vector with the same direction as this vector.
    ///
    /// If this vector has zero length, returns the zero vector.
    @inlinable
    public var normalized: Vector2 {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return Vector2(dx: dx / mag, dy: dy / mag)
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
}

// MARK: - Arithmetic Operations

extension Vector2 {
    /// Returns the negation of a vector.
    @inlinable
    public static prefix func - (vector: Vector2) -> Vector2 {
        Vector2(dx: -vector.dx, dy: -vector.dy)
    }

    /// Returns the sum of two vectors.
    @inlinable
    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    /// Returns the difference of two vectors.
    @inlinable
    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    /// Adds a vector and stores the result.
    @inlinable
    public static func += (lhs: inout Vector2, rhs: Vector2) {
        lhs.dx += rhs.dx
        lhs.dy += rhs.dy
    }

    /// Subtracts a vector and stores the result.
    @inlinable
    public static func -= (lhs: inout Vector2, rhs: Vector2) {
        lhs.dx -= rhs.dx
        lhs.dy -= rhs.dy
    }

    /// Returns a vector multiplied by a scalar.
    @inlinable
    public static func * (vector: Vector2, scalar: Float) -> Vector2 {
        Vector2(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    /// Returns a vector multiplied by a scalar.
    @inlinable
    public static func * (scalar: Float, vector: Vector2) -> Vector2 {
        Vector2(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }

    /// Returns a vector divided by a scalar.
    @inlinable
    public static func / (vector: Vector2, scalar: Float) -> Vector2 {
        Vector2(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }

    /// Multiplies by a scalar and stores the result.
    @inlinable
    public static func *= (vector: inout Vector2, scalar: Float) {
        vector.dx *= scalar
        vector.dy *= scalar
    }

    /// Divides by a scalar and stores the result.
    @inlinable
    public static func /= (vector: inout Vector2, scalar: Float) {
        vector.dx /= scalar
        vector.dy /= scalar
    }
}

// MARK: - Vector Products

extension Vector2 {
    /// Returns the dot product of two vectors.
    ///
    /// The dot product is equal to `|a| * |b| * cos(θ)` where θ is the angle between the vectors.
    @inlinable
    public func dot(_ other: Vector2) -> Float {
        dx * other.dx + dy * other.dy
    }

    /// Returns the 2D cross product (perpendicular dot product).
    ///
    /// This returns a scalar representing the z-component of the 3D cross product
    /// if the vectors were extended to 3D with z=0.
    ///
    /// The sign indicates the relative orientation:
    /// - Positive: `other` is counter-clockwise from `self`
    /// - Negative: `other` is clockwise from `self`
    /// - Zero: vectors are parallel
    @inlinable
    public func cross(_ other: Vector2) -> Float {
        dx * other.dy - dy * other.dx
    }
}

// MARK: - Transformations

extension Vector2 {
    /// Returns this vector rotated by the specified angle.
    ///
    /// - Parameter angle: The angle in radians to rotate counter-clockwise.
    @inlinable
    public func rotated(by angle: Float) -> Vector2 {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return Vector2(
            dx: dx * cosAngle - dy * sinAngle,
            dy: dx * sinAngle + dy * cosAngle
        )
    }

    /// Rotates this vector in place.
    @inlinable
    public mutating func rotate(by angle: Float) {
        self = rotated(by: angle)
    }

    /// Returns a vector perpendicular to this one (rotated 90° counter-clockwise).
    @inlinable
    public var perpendicular: Vector2 {
        Vector2(dx: -dy, dy: dx)
    }

    /// Returns the projection of this vector onto another vector.
    @inlinable
    public func projected(onto other: Vector2) -> Vector2 {
        let dotProduct = dot(other)
        let otherMagSquared = other.magnitudeSquared
        guard otherMagSquared > 0 else { return .zero }
        return other * (dotProduct / otherMagSquared)
    }

    /// Returns the reflection of this vector off a surface with the given normal.
    ///
    /// - Parameter normal: The surface normal (should be normalized).
    @inlinable
    public func reflected(normal: Vector2) -> Vector2 {
        self - 2 * dot(normal) * normal
    }
}

// MARK: - Interpolation

extension Vector2 {
    /// Returns a vector interpolated between two vectors.
    @inlinable
    public static func lerp(from start: Vector2, to end: Vector2, t: Float) -> Vector2 {
        Vector2(
            dx: start.dx + (end.dx - start.dx) * t,
            dy: start.dy + (end.dy - start.dy) * t
        )
    }
}

// MARK: - Angle Between Vectors

extension Vector2 {
    /// Returns the angle between this vector and another vector.
    ///
    /// - Returns: The angle in radians, in the range [0, π].
    @inlinable
    public func angle(to other: Vector2) -> Float {
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
    public func signedAngle(to other: Vector2) -> Float {
        atan2(cross(other), dot(other))
    }
}

// MARK: - CustomStringConvertible

extension Vector2: CustomStringConvertible {
    public var description: String {
        "(dx: \(dx), dy: \(dy))"
    }
}

// MARK: - Codable

extension Vector2: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        dx = try container.decode(Float.self)
        dy = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(dx)
        try container.encode(dy)
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension Vector2 {
    /// Creates a `Vector2` from a `CGVector`.
    @inlinable
    public init(_ cgVector: CGVector) {
        self.dx = Float(cgVector.dx)
        self.dy = Float(cgVector.dy)
    }

    /// Returns this vector as a `CGVector`.
    @inlinable
    public var cgVector: CGVector {
        CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
    }
}

extension CGVector {
    /// Creates a `CGVector` from a `Vector2`.
    @inlinable
    public init(_ vector: Vector2) {
        self.init(dx: CGFloat(vector.dx), dy: CGFloat(vector.dy))
    }
}
#endif

// MARK: - Standard Library Math Functions

// Use platform-specific math libraries
#if canImport(Darwin)
import Darwin
@inlinable internal func _cos(_ x: Float) -> Float { Darwin.cos(x) }
@inlinable internal func _sin(_ x: Float) -> Float { Darwin.sin(x) }
@inlinable internal func _atan2(_ y: Float, _ x: Float) -> Float { Darwin.atan2(y, x) }
@inlinable internal func _acos(_ x: Float) -> Float { Darwin.acos(x) }
@inlinable internal func _sqrt(_ x: Float) -> Float { Darwin.sqrt(x) }
@inlinable internal func _pow(_ base: Float, _ exponent: Float) -> Float { Darwin.pow(base, exponent) }
#elseif canImport(Glibc)
import Glibc
@inlinable internal func _cos(_ x: Float) -> Float { Glibc.cos(x) }
@inlinable internal func _sin(_ x: Float) -> Float { Glibc.sin(x) }
@inlinable internal func _atan2(_ y: Float, _ x: Float) -> Float { Glibc.atan2(y, x) }
@inlinable internal func _acos(_ x: Float) -> Float { Glibc.acos(x) }
@inlinable internal func _sqrt(_ x: Float) -> Float { Glibc.sqrt(x) }
@inlinable internal func _pow(_ base: Float, _ exponent: Float) -> Float { Glibc.pow(base, exponent) }
#elseif arch(wasm32)
// WASM: Import from WASILibc
import WASILibc
@inlinable internal func _cos(_ x: Float) -> Float { WASILibc.cosf(x) }
@inlinable internal func _sin(_ x: Float) -> Float { WASILibc.sinf(x) }
@inlinable internal func _atan2(_ y: Float, _ x: Float) -> Float { WASILibc.atan2f(y, x) }
@inlinable internal func _acos(_ x: Float) -> Float { WASILibc.acosf(x) }
@inlinable internal func _sqrt(_ x: Float) -> Float { WASILibc.sqrtf(x) }
@inlinable internal func _pow(_ base: Float, _ exponent: Float) -> Float { WASILibc.powf(base, exponent) }
#else
#error("Unsupported platform for math functions")
#endif

@inlinable internal func cos(_ x: Float) -> Float { _cos(x) }
@inlinable internal func sin(_ x: Float) -> Float { _sin(x) }
@inlinable internal func atan2(_ y: Float, _ x: Float) -> Float { _atan2(y, x) }
@inlinable internal func acos(_ x: Float) -> Float { _acos(x) }
@inlinable internal func sqrt(_ x: Float) -> Float { _sqrt(x) }
@inlinable internal func pow(_ base: Float, _ exponent: Float) -> Float { _pow(base, exponent) }

