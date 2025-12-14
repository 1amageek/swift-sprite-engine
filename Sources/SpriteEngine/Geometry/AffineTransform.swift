/// A structure that represents a 2D affine transformation matrix.
///
/// `AffineTransform` is the Wisp equivalent of CoreGraphics' `CGAffineTransform`.
/// It uses `Float` instead of `CGFloat` for WebAssembly compatibility.
///
/// The matrix is represented as:
/// ```
/// | a  b  0 |
/// | c  d  0 |
/// | tx ty 1 |
/// ```
///
/// A point (x, y) is transformed to (x', y') as:
/// ```
/// x' = a * x + c * y + tx
/// y' = b * x + d * y + ty
/// ```
public struct AffineTransform: Hashable, Sendable {
    /// The entry at position (1,1) in the matrix.
    public var a: Float

    /// The entry at position (1,2) in the matrix.
    public var b: Float

    /// The entry at position (2,1) in the matrix.
    public var c: Float

    /// The entry at position (2,2) in the matrix.
    public var d: Float

    /// The x translation component.
    public var tx: Float

    /// The y translation component.
    public var ty: Float

    /// Creates an affine transform with the specified matrix elements.
    @inlinable
    public init(a: Float, b: Float, c: Float, d: Float, tx: Float, ty: Float) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }

    /// The identity transform.
    public static let identity = AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
}

// MARK: - Factory Methods

extension AffineTransform {
    /// Creates a translation transform.
    @inlinable
    public static func translation(x: Float, y: Float) -> AffineTransform {
        AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: x, ty: y)
    }

    /// Creates a translation transform from a vector.
    @inlinable
    public static func translation(_ vector: Vector2) -> AffineTransform {
        translation(x: vector.dx, y: vector.dy)
    }

    /// Creates a scaling transform.
    @inlinable
    public static func scale(x: Float, y: Float) -> AffineTransform {
        AffineTransform(a: x, b: 0, c: 0, d: y, tx: 0, ty: 0)
    }

    /// Creates a uniform scaling transform.
    @inlinable
    public static func scale(_ scale: Float) -> AffineTransform {
        AffineTransform(a: scale, b: 0, c: 0, d: scale, tx: 0, ty: 0)
    }

    /// Creates a rotation transform.
    ///
    /// - Parameter angle: The rotation angle in radians, counter-clockwise.
    @inlinable
    public static func rotation(_ angle: Float) -> AffineTransform {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        return AffineTransform(a: cosAngle, b: sinAngle, c: -sinAngle, d: cosAngle, tx: 0, ty: 0)
    }

    /// Creates a rotation transform from an `Angle`.
    @inlinable
    public static func rotation(_ angle: Angle) -> AffineTransform {
        rotation(angle.radians)
    }

    /// Creates a shear (skew) transform.
    @inlinable
    public static func shear(x: Float, y: Float) -> AffineTransform {
        AffineTransform(a: 1, b: y, c: x, d: 1, tx: 0, ty: 0)
    }
}

// MARK: - Computed Properties

extension AffineTransform {
    /// Returns `true` if this is the identity transform.
    @inlinable
    public var isIdentity: Bool {
        a == 1 && b == 0 && c == 0 && d == 1 && tx == 0 && ty == 0
    }

    /// The determinant of the matrix.
    ///
    /// A non-zero determinant indicates the transform is invertible.
    @inlinable
    public var determinant: Float {
        a * d - b * c
    }

    /// Returns `true` if this transform is invertible.
    @inlinable
    public var isInvertible: Bool {
        determinant != 0
    }

    /// The translation component as a vector.
    @inlinable
    public var translation: Vector2 {
        get { Vector2(dx: tx, dy: ty) }
        set {
            tx = newValue.dx
            ty = newValue.dy
        }
    }
}

// MARK: - Transform Operations

extension AffineTransform {
    /// Returns a new transform with translation added.
    @inlinable
    public func translated(x: Float, y: Float) -> AffineTransform {
        AffineTransform(
            a: a, b: b,
            c: c, d: d,
            tx: tx + x,
            ty: ty + y
        )
    }

    /// Returns a new transform with translation added.
    @inlinable
    public func translated(by vector: Vector2) -> AffineTransform {
        translated(x: vector.dx, y: vector.dy)
    }

    /// Adds translation to this transform in place.
    @inlinable
    public mutating func translate(x: Float, y: Float) {
        tx += x
        ty += y
    }

    /// Returns a new transform with scaling applied.
    @inlinable
    public func scaled(x: Float, y: Float) -> AffineTransform {
        AffineTransform(
            a: a * x, b: b * x,
            c: c * y, d: d * y,
            tx: tx * x, ty: ty * y
        )
    }

    /// Returns a new transform with uniform scaling applied.
    @inlinable
    public func scaled(by scale: Float) -> AffineTransform {
        scaled(x: scale, y: scale)
    }

    /// Applies scaling to this transform in place.
    @inlinable
    public mutating func scale(x: Float, y: Float) {
        self = scaled(x: x, y: y)
    }

    /// Returns a new transform with rotation applied.
    ///
    /// - Parameter angle: The rotation angle in radians, counter-clockwise.
    @inlinable
    public func rotated(by angle: Float) -> AffineTransform {
        concatenated(with: .rotation(angle))
    }

    /// Returns a new transform with rotation applied.
    @inlinable
    public func rotated(by angle: Angle) -> AffineTransform {
        rotated(by: angle.radians)
    }

    /// Applies rotation to this transform in place.
    @inlinable
    public mutating func rotate(by angle: Float) {
        self = rotated(by: angle)
    }
}

// MARK: - Matrix Operations

extension AffineTransform {
    /// Returns the concatenation of this transform with another.
    ///
    /// The resulting transform applies `self` first, then `other`.
    @inlinable
    public func concatenated(with other: AffineTransform) -> AffineTransform {
        AffineTransform(
            a: a * other.a + b * other.c,
            b: a * other.b + b * other.d,
            c: c * other.a + d * other.c,
            d: c * other.b + d * other.d,
            tx: tx * other.a + ty * other.c + other.tx,
            ty: tx * other.b + ty * other.d + other.ty
        )
    }

    /// Concatenates another transform onto this transform.
    @inlinable
    public mutating func concatenate(with other: AffineTransform) {
        self = concatenated(with: other)
    }

    /// Returns the inverse of this transform.
    ///
    /// Returns `nil` if the transform is not invertible.
    @inlinable
    public func inverted() -> AffineTransform? {
        let det = determinant
        guard det != 0 else { return nil }

        let invDet = 1 / det
        return AffineTransform(
            a: d * invDet,
            b: -b * invDet,
            c: -c * invDet,
            d: a * invDet,
            tx: (c * ty - d * tx) * invDet,
            ty: (b * tx - a * ty) * invDet
        )
    }
}

// MARK: - Point Transformation

extension AffineTransform {
    /// Transforms a point using this affine transform.
    @inlinable
    public func transform(_ point: Point) -> Point {
        Point(
            x: a * point.x + c * point.y + tx,
            y: b * point.x + d * point.y + ty
        )
    }

    /// Transforms a size using this affine transform.
    ///
    /// Only the scaling and rotation components affect the size; translation is ignored.
    @inlinable
    public func transform(_ size: Size) -> Size {
        Size(
            width: a * size.width + c * size.height,
            height: b * size.width + d * size.height
        )
    }

    /// Transforms a vector using this affine transform.
    ///
    /// Only the scaling and rotation components affect the vector; translation is ignored.
    @inlinable
    public func transform(_ vector: Vector2) -> Vector2 {
        Vector2(
            dx: a * vector.dx + c * vector.dy,
            dy: b * vector.dx + d * vector.dy
        )
    }

    /// Transforms a rectangle using this affine transform.
    ///
    /// Returns the axis-aligned bounding box of the transformed rectangle.
    @inlinable
    public func transform(_ rect: Rect) -> Rect {
        let p1 = transform(rect.bottomLeft)
        let p2 = transform(rect.bottomRight)
        let p3 = transform(rect.topLeft)
        let p4 = transform(rect.topRight)

        let minX = min(p1.x, min(p2.x, min(p3.x, p4.x)))
        let maxX = max(p1.x, max(p2.x, max(p3.x, p4.x)))
        let minY = min(p1.y, min(p2.y, min(p3.y, p4.y)))
        let maxY = max(p1.y, max(p2.y, max(p3.y, p4.y)))

        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Operators

extension AffineTransform {
    /// Concatenates two transforms.
    @inlinable
    public static func * (lhs: AffineTransform, rhs: AffineTransform) -> AffineTransform {
        lhs.concatenated(with: rhs)
    }

    /// Concatenates another transform onto this one.
    @inlinable
    public static func *= (lhs: inout AffineTransform, rhs: AffineTransform) {
        lhs.concatenate(with: rhs)
    }
}

// MARK: - CustomStringConvertible

extension AffineTransform: CustomStringConvertible {
    public var description: String {
        "[a: \(a), b: \(b), c: \(c), d: \(d), tx: \(tx), ty: \(ty)]"
    }
}

// MARK: - Codable

extension AffineTransform: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        a = try container.decode(Float.self)
        b = try container.decode(Float.self)
        c = try container.decode(Float.self)
        d = try container.decode(Float.self)
        tx = try container.decode(Float.self)
        ty = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(a)
        try container.encode(b)
        try container.encode(c)
        try container.encode(d)
        try container.encode(tx)
        try container.encode(ty)
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension AffineTransform {
    /// Creates an `AffineTransform` from a `CGAffineTransform`.
    @inlinable
    public init(_ cgTransform: CGAffineTransform) {
        self.a = Float(cgTransform.a)
        self.b = Float(cgTransform.b)
        self.c = Float(cgTransform.c)
        self.d = Float(cgTransform.d)
        self.tx = Float(cgTransform.tx)
        self.ty = Float(cgTransform.ty)
    }

    /// Returns this transform as a `CGAffineTransform`.
    @inlinable
    public var cgAffineTransform: CGAffineTransform {
        CGAffineTransform(
            a: CGFloat(a),
            b: CGFloat(b),
            c: CGFloat(c),
            d: CGFloat(d),
            tx: CGFloat(tx),
            ty: CGFloat(ty)
        )
    }
}

extension CGAffineTransform {
    /// Creates a `CGAffineTransform` from an `AffineTransform`.
    @inlinable
    public init(_ transform: AffineTransform) {
        self.init(
            a: CGFloat(transform.a),
            b: CGFloat(transform.b),
            c: CGFloat(transform.c),
            d: CGFloat(transform.d),
            tx: CGFloat(transform.tx),
            ty: CGFloat(transform.ty)
        )
    }
}
#endif
