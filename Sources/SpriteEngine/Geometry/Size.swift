/// A structure that contains width and height values.
///
/// `Size` is the Wisp equivalent of CoreGraphics' `CGSize`.
/// It uses `Float` instead of `CGFloat` for WebAssembly compatibility.
public struct Size: Hashable, Sendable {
    /// The width value.
    public var width: Float

    /// The height value.
    public var height: Float

    /// Creates a size with dimensions specified as floating-point values.
    @inlinable
    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    /// A size with zero width and height.
    public static let zero = Size(width: 0, height: 0)
}

// MARK: - Convenience Initializers

extension Size {
    /// Creates a square size with equal width and height.
    @inlinable
    public init(square: Float) {
        self.width = square
        self.height = square
    }
}

// MARK: - Computed Properties

extension Size {
    /// Returns the area (width × height).
    @inlinable
    public var area: Float {
        width * height
    }

    /// Returns the aspect ratio (width / height).
    ///
    /// Returns `Float.infinity` if height is zero.
    @inlinable
    public var aspectRatio: Float {
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
    public var diagonal: Float {
        (width * width + height * height).squareRoot()
    }
}

// MARK: - Arithmetic Operations

extension Size {
    /// Returns a size with each dimension multiplied by a scalar.
    @inlinable
    public static func * (size: Size, scalar: Float) -> Size {
        Size(width: size.width * scalar, height: size.height * scalar)
    }

    /// Returns a size with each dimension multiplied by a scalar.
    @inlinable
    public static func * (scalar: Float, size: Size) -> Size {
        Size(width: size.width * scalar, height: size.height * scalar)
    }

    /// Returns a size with each dimension divided by a scalar.
    @inlinable
    public static func / (size: Size, scalar: Float) -> Size {
        Size(width: size.width / scalar, height: size.height / scalar)
    }

    /// Multiplies each dimension by a scalar and stores the result.
    @inlinable
    public static func *= (size: inout Size, scalar: Float) {
        size.width *= scalar
        size.height *= scalar
    }

    /// Divides each dimension by a scalar and stores the result.
    @inlinable
    public static func /= (size: inout Size, scalar: Float) {
        size.width /= scalar
        size.height /= scalar
    }

    /// Returns a size with each dimension added.
    @inlinable
    public static func + (lhs: Size, rhs: Size) -> Size {
        Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    /// Returns a size with each dimension subtracted.
    @inlinable
    public static func - (lhs: Size, rhs: Size) -> Size {
        Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}

// MARK: - Fitting and Filling

extension Size {
    /// Returns a size that fits within the target size while maintaining aspect ratio.
    ///
    /// The returned size will be as large as possible while still fitting entirely
    /// within the target size.
    @inlinable
    public func aspectFit(in target: Size) -> Size {
        guard width > 0 && height > 0 else { return .zero }

        let widthRatio = target.width / width
        let heightRatio = target.height / height
        let scale = min(widthRatio, heightRatio)

        return Size(width: width * scale, height: height * scale)
    }

    /// Returns a size that fills the target size while maintaining aspect ratio.
    ///
    /// The returned size will be as small as possible while still completely
    /// covering the target size.
    @inlinable
    public func aspectFill(in target: Size) -> Size {
        guard width > 0 && height > 0 else { return target }

        let widthRatio = target.width / width
        let heightRatio = target.height / height
        let scale = max(widthRatio, heightRatio)

        return Size(width: width * scale, height: height * scale)
    }
}

// MARK: - Interpolation

extension Size {
    /// Returns a size interpolated between two sizes.
    @inlinable
    public static func lerp(from start: Size, to end: Size, t: Float) -> Size {
        Size(
            width: start.width + (end.width - start.width) * t,
            height: start.height + (end.height - start.height) * t
        )
    }
}

// MARK: - CustomStringConvertible

extension Size: CustomStringConvertible {
    public var description: String {
        "(\(width) × \(height))"
    }
}

// MARK: - Codable

extension Size: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        width = try container.decode(Float.self)
        height = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension Size {
    /// Creates a `Size` from a `CGSize`.
    @inlinable
    public init(_ cgSize: CGSize) {
        self.width = Float(cgSize.width)
        self.height = Float(cgSize.height)
    }

    /// Returns this size as a `CGSize`.
    @inlinable
    public var cgSize: CGSize {
        CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

extension CGSize {
    /// Creates a `CGSize` from a `Size`.
    @inlinable
    public init(_ size: Size) {
        self.init(width: CGFloat(size.width), height: CGFloat(size.height))
    }
}
#endif
