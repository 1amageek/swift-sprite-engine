#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

/// A structure that represents an angular value.
///
/// `Angle` provides a type-safe way to work with angles, supporting both
/// radians and degrees. Internally, angles are stored in radians.
public struct Angle: Hashable, Sendable {
    /// The angle value in radians.
    public var radians: Float

    /// Creates an angle with the specified value in radians.
    @inlinable
    public init(radians: Float) {
        self.radians = radians
    }

    /// Creates an angle with the specified value in degrees.
    @inlinable
    public init(degrees: Float) {
        self.radians = degrees * Float.pi / 180
    }

    /// A zero angle.
    public static let zero = Angle(radians: 0)

    /// A full rotation (360 degrees or 2π radians).
    public static let fullRotation = Angle(radians: 2 * .pi)

    /// A half rotation (180 degrees or π radians).
    public static let halfRotation = Angle(radians: .pi)

    /// A quarter rotation (90 degrees or π/2 radians).
    public static let quarterRotation = Angle(radians: .pi / 2)
}

// MARK: - Factory Methods

extension Angle {
    /// Creates an angle from radians.
    @inlinable
    public static func radians(_ value: Float) -> Angle {
        Angle(radians: value)
    }

    /// Creates an angle from degrees.
    @inlinable
    public static func degrees(_ value: Float) -> Angle {
        Angle(degrees: value)
    }
}

// MARK: - Conversions

extension Angle {
    /// The angle value in degrees.
    @inlinable
    public var degrees: Float {
        get { radians * 180 / Float.pi }
        set { radians = newValue * Float.pi / 180 }
    }

    /// The angle value in rotations (1 rotation = 360 degrees).
    @inlinable
    public var rotations: Float {
        get { radians / (2 * .pi) }
        set { radians = newValue * 2 * .pi }
    }
}

// MARK: - Normalization

extension Angle {
    /// Returns the angle normalized to the range [0, 2π).
    @inlinable
    public var normalized: Angle {
        var r = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if r < 0 {
            r += 2 * .pi
        }
        return Angle(radians: r)
    }

    /// Returns the angle normalized to the range [-π, π).
    @inlinable
    public var normalizedSigned: Angle {
        var r = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if r >= .pi {
            r -= 2 * .pi
        } else if r < -.pi {
            r += 2 * .pi
        }
        return Angle(radians: r)
    }

    /// Normalizes this angle to the range [0, 2π) in place.
    @inlinable
    public mutating func normalize() {
        self = normalized
    }

    /// Normalizes this angle to the range [-π, π) in place.
    @inlinable
    public mutating func normalizeSigned() {
        self = normalizedSigned
    }
}

// MARK: - Trigonometric Functions

extension Angle {
    /// The sine of this angle.
    @inlinable
    public var sin: Float {
        SpriteEngine.sin(radians)
    }

    /// The cosine of this angle.
    @inlinable
    public var cos: Float {
        SpriteEngine.cos(radians)
    }

    /// The tangent of this angle.
    @inlinable
    public var tan: Float {
        SpriteEngine.tan(radians)
    }

    /// Creates an angle from an arc sine value.
    @inlinable
    public static func asin(_ value: Float) -> Angle {
        Angle(radians: SpriteEngine.asin(value))
    }

    /// Creates an angle from an arc cosine value.
    @inlinable
    public static func acos(_ value: Float) -> Angle {
        Angle(radians: SpriteEngine.acos(value))
    }

    /// Creates an angle from an arc tangent value.
    @inlinable
    public static func atan(_ value: Float) -> Angle {
        Angle(radians: SpriteEngine.atan(value))
    }

    /// Creates an angle from the arc tangent of y/x, using signs to determine quadrant.
    @inlinable
    public static func atan2(y: Float, x: Float) -> Angle {
        Angle(radians: SpriteEngine.atan2(y, x))
    }
}

// MARK: - Arithmetic Operations

extension Angle {
    /// Returns the negation of an angle.
    @inlinable
    public static prefix func - (angle: Angle) -> Angle {
        Angle(radians: -angle.radians)
    }

    /// Returns the sum of two angles.
    @inlinable
    public static func + (lhs: Angle, rhs: Angle) -> Angle {
        Angle(radians: lhs.radians + rhs.radians)
    }

    /// Returns the difference of two angles.
    @inlinable
    public static func - (lhs: Angle, rhs: Angle) -> Angle {
        Angle(radians: lhs.radians - rhs.radians)
    }

    /// Adds an angle and stores the result.
    @inlinable
    public static func += (lhs: inout Angle, rhs: Angle) {
        lhs.radians += rhs.radians
    }

    /// Subtracts an angle and stores the result.
    @inlinable
    public static func -= (lhs: inout Angle, rhs: Angle) {
        lhs.radians -= rhs.radians
    }

    /// Returns an angle multiplied by a scalar.
    @inlinable
    public static func * (angle: Angle, scalar: Float) -> Angle {
        Angle(radians: angle.radians * scalar)
    }

    /// Returns an angle multiplied by a scalar.
    @inlinable
    public static func * (scalar: Float, angle: Angle) -> Angle {
        Angle(radians: angle.radians * scalar)
    }

    /// Returns an angle divided by a scalar.
    @inlinable
    public static func / (angle: Angle, scalar: Float) -> Angle {
        Angle(radians: angle.radians / scalar)
    }

    /// Multiplies by a scalar and stores the result.
    @inlinable
    public static func *= (angle: inout Angle, scalar: Float) {
        angle.radians *= scalar
    }

    /// Divides by a scalar and stores the result.
    @inlinable
    public static func /= (angle: inout Angle, scalar: Float) {
        angle.radians /= scalar
    }
}

// MARK: - Comparison

extension Angle: Comparable {
    @inlinable
    public static func < (lhs: Angle, rhs: Angle) -> Bool {
        lhs.radians < rhs.radians
    }
}

// MARK: - Interpolation

extension Angle {
    /// Returns an angle interpolated between two angles.
    @inlinable
    public static func lerp(from start: Angle, to end: Angle, t: Float) -> Angle {
        Angle(radians: start.radians + (end.radians - start.radians) * t)
    }

    /// Returns an angle interpolated between two angles, taking the shortest path.
    ///
    /// This method handles wrapping around the circle to find the shortest
    /// rotation between the two angles.
    @inlinable
    public static func lerpShortest(from start: Angle, to end: Angle, t: Float) -> Angle {
        var delta = (end.radians - start.radians).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi {
            delta -= 2 * .pi
        } else if delta < -.pi {
            delta += 2 * .pi
        }
        return Angle(radians: start.radians + delta * t)
    }
}

// MARK: - CustomStringConvertible

extension Angle: CustomStringConvertible {
    public var description: String {
        "\(degrees)°"
    }
}

// MARK: - Codable

extension Angle: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        radians = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(radians)
    }
}

// MARK: - Standard Library Math Functions

@inlinable
internal func tan(_ x: Float) -> Float {
    #if canImport(Darwin)
    return Darwin.tan(x)
    #elseif canImport(Glibc)
    return Glibc.tan(x)
    #elseif canImport(WASILibc)
    return WASILibc.tan(x)
    #else
    return _tan(x)
    #endif
}

@inlinable
internal func asin(_ x: Float) -> Float {
    #if canImport(Darwin)
    return Darwin.asin(x)
    #elseif canImport(Glibc)
    return Glibc.asin(x)
    #elseif canImport(WASILibc)
    return WASILibc.asin(x)
    #else
    return _asin(x)
    #endif
}

@inlinable
internal func atan(_ x: Float) -> Float {
    #if canImport(Darwin)
    return Darwin.atan(x)
    #elseif canImport(Glibc)
    return Glibc.atan(x)
    #elseif canImport(WASILibc)
    return WASILibc.atan(x)
    #else
    return _atan(x)
    #endif
}
