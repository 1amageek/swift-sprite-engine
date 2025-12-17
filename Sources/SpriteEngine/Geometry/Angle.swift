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
    public var radians: CGFloat

    /// Creates an angle with the specified value in radians.
    @inlinable
    public init(radians: CGFloat) {
        self.radians = radians
    }

    /// Creates an angle with the specified value in degrees.
    @inlinable
    public init(degrees: CGFloat) {
        self.radians = degrees * CGFloat.pi / 180
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
    public static func radians(_ value: CGFloat) -> Angle {
        Angle(radians: value)
    }

    /// Creates an angle from degrees.
    @inlinable
    public static func degrees(_ value: CGFloat) -> Angle {
        Angle(degrees: value)
    }
}

// MARK: - Conversions

extension Angle {
    /// The angle value in degrees.
    @inlinable
    public var degrees: CGFloat {
        get { radians * 180 / CGFloat.pi }
        set { radians = newValue * CGFloat.pi / 180 }
    }

    /// The angle value in rotations (1 rotation = 360 degrees).
    @inlinable
    public var rotations: CGFloat {
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
    public var sin: CGFloat {
        SpriteEngine.sin(radians)
    }

    /// The cosine of this angle.
    @inlinable
    public var cos: CGFloat {
        SpriteEngine.cos(radians)
    }

    /// The tangent of this angle.
    @inlinable
    public var tan: CGFloat {
        SpriteEngine.tan(radians)
    }

    /// Creates an angle from an arc sine value.
    @inlinable
    public static func asin(_ value: CGFloat) -> Angle {
        Angle(radians: SpriteEngine.asin(value))
    }

    /// Creates an angle from an arc cosine value.
    @inlinable
    public static func acos(_ value: CGFloat) -> Angle {
        Angle(radians: SpriteEngine.acos(value))
    }

    /// Creates an angle from an arc tangent value.
    @inlinable
    public static func atan(_ value: CGFloat) -> Angle {
        Angle(radians: SpriteEngine.atan(value))
    }

    /// Creates an angle from the arc tangent of y/x, using signs to determine quadrant.
    @inlinable
    public static func atan2(y: CGFloat, x: CGFloat) -> Angle {
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
    public static func * (angle: Angle, scalar: CGFloat) -> Angle {
        Angle(radians: angle.radians * scalar)
    }

    /// Returns an angle multiplied by a scalar.
    @inlinable
    public static func * (scalar: CGFloat, angle: Angle) -> Angle {
        Angle(radians: angle.radians * scalar)
    }

    /// Returns an angle divided by a scalar.
    @inlinable
    public static func / (angle: Angle, scalar: CGFloat) -> Angle {
        Angle(radians: angle.radians / scalar)
    }

    /// Multiplies by a scalar and stores the result.
    @inlinable
    public static func *= (angle: inout Angle, scalar: CGFloat) {
        angle.radians *= scalar
    }

    /// Divides by a scalar and stores the result.
    @inlinable
    public static func /= (angle: inout Angle, scalar: CGFloat) {
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
    public static func lerp(from start: Angle, to end: Angle, t: CGFloat) -> Angle {
        Angle(radians: start.radians + (end.radians - start.radians) * t)
    }

    /// Returns an angle interpolated between two angles, taking the shortest path.
    ///
    /// This method handles wrapping around the circle to find the shortest
    /// rotation between the two angles.
    @inlinable
    public static func lerpShortest(from start: Angle, to end: Angle, t: CGFloat) -> Angle {
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
        radians = try container.decode(CGFloat.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(radians)
    }
}

// MARK: - Standard Library Math Functions

@inlinable
internal func tan(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.tan(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.tan(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.tan(Double(x)))
    #else
    return CGFloat(_tan(Double(x)))
    #endif
}

@inlinable
internal func asin(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.asin(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.asin(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.asin(Double(x)))
    #else
    return CGFloat(_asin(Double(x)))
    #endif
}

@inlinable
internal func atan(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.atan(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.atan(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.atan(Double(x)))
    #else
    return CGFloat(_atan(Double(x)))
    #endif
}

@inlinable
internal func sin(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.sin(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.sin(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.sin(Double(x)))
    #else
    return CGFloat(_sin(Double(x)))
    #endif
}

@inlinable
internal func cos(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.cos(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.cos(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.cos(Double(x)))
    #else
    return CGFloat(_cos(Double(x)))
    #endif
}

@inlinable
internal func acos(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.acos(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.acos(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.acos(Double(x)))
    #else
    return CGFloat(_acos(Double(x)))
    #endif
}

@inlinable
internal func atan2(_ y: CGFloat, _ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.atan2(y, x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.atan2(Double(y), Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.atan2(Double(y), Double(x)))
    #else
    return CGFloat(_atan2(Double(y), Double(x)))
    #endif
}

@inlinable
internal func sqrt(_ x: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.sqrt(x)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.sqrt(Double(x)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.sqrt(Double(x)))
    #else
    return CGFloat(_sqrt(Double(x)))
    #endif
}

@inlinable
internal func pow(_ base: CGFloat, _ exponent: CGFloat) -> CGFloat {
    #if canImport(Darwin)
    return Darwin.pow(base, exponent)
    #elseif canImport(Glibc)
    return CGFloat(Glibc.pow(Double(base), Double(exponent)))
    #elseif canImport(WASILibc)
    return CGFloat(WASILibc.pow(Double(base), Double(exponent)))
    #else
    return CGFloat(_pow(Double(base), Double(exponent)))
    #endif
}
