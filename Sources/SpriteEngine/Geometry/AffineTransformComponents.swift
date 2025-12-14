/// A structure containing the decomposed components of an affine transform.
///
/// `AffineTransformComponents` breaks down a transform into its constituent parts:
/// scale, horizontal shear, rotation, and translation.
///
/// ## Usage
/// ```swift
/// let transform = AffineTransform.rotation(.pi / 4)
///     .scaled(x: 2, y: 2)
///     .translated(x: 100, y: 50)
///
/// let components = transform.decomposed()
/// print(components.rotation)     // Approximately π/4
/// print(components.scale)        // (2, 2)
/// print(components.translation)  // (100, 50)
/// ```
public struct AffineTransformComponents: Hashable, Sendable {
    /// The scale component.
    public var scale: Size

    /// The horizontal shear (skew) component.
    public var horizontalShear: Float

    /// The rotation angle in radians.
    public var rotation: Float

    /// The translation component.
    public var translation: Vector2

    /// Creates transform components with the specified values.
    ///
    /// - Parameters:
    ///   - scale: The scale factor.
    ///   - horizontalShear: The horizontal shear factor.
    ///   - rotation: The rotation angle in radians.
    ///   - translation: The translation vector.
    public init(
        scale: Size = Size(width: 1, height: 1),
        horizontalShear: Float = 0,
        rotation: Float = 0,
        translation: Vector2 = .zero
    ) {
        self.scale = scale
        self.horizontalShear = horizontalShear
        self.rotation = rotation
        self.translation = translation
    }
}

// MARK: - AffineTransform Extension

extension AffineTransform {
    /// Creates an affine transform from components.
    ///
    /// - Parameter components: The transform components.
    public init(_ components: AffineTransformComponents) {
        // Build transform: T * R * Sh * S
        // Translation
        var transform = AffineTransform.translation(components.translation)

        // Rotation
        transform = transform.concatenated(with: .rotation(components.rotation))

        // Shear
        if components.horizontalShear != 0 {
            transform = transform.concatenated(with: .shear(x: components.horizontalShear, y: 0))
        }

        // Scale
        transform = transform.concatenated(with: .scale(
            x: components.scale.width,
            y: components.scale.height
        ))

        self = transform
    }

    /// Decomposes this transform into its component parts.
    ///
    /// The decomposition follows the order: Translation * Rotation * Shear * Scale
    ///
    /// - Returns: The decomposed components.
    public func decomposed() -> AffineTransformComponents {
        // Extract translation
        let translation = Vector2(dx: tx, dy: ty)

        // Extract scale and rotation from the 2x2 matrix part
        // The 2x2 part is:
        // | a  b |
        // | c  d |

        // Calculate the scale of the first column vector (a, b)
        let scaleX = sqrt(a * a + b * b)

        // Normalize first column to get rotation
        var cosR: Float = 1
        var sinR: Float = 0
        if scaleX != 0 {
            cosR = a / scaleX
            sinR = b / scaleX
        }

        // Calculate rotation angle
        let rotation = atan2(sinR, cosR)

        // Apply inverse rotation to get the sheared and scaled matrix
        // Unrotated matrix = R^-1 * M
        // R^-1 = | cos  sin |
        //        | -sin cos |
        _ = cosR * a + sinR * b  // ua - not needed
        _ = -sinR * a + cosR * b  // ub - not needed
        let uc = cosR * c + sinR * d
        let ud = -sinR * c + cosR * d

        // Now the matrix should be:
        // | sx   0   |
        // | shear*sy sy |
        // or with horizontal shear:
        // | sx  shear*sx |
        // | 0   sy       |

        // Extract scale Y from the second column
        let scaleY = ud

        // Extract horizontal shear
        var horizontalShear: Float = 0
        if scaleX != 0 {
            horizontalShear = uc / scaleX
        }

        return AffineTransformComponents(
            scale: Size(width: scaleX, height: scaleY),
            horizontalShear: horizontalShear,
            rotation: rotation,
            translation: translation
        )
    }
}

// MARK: - CustomStringConvertible

extension AffineTransformComponents: CustomStringConvertible {
    public var description: String {
        "Components(scale: \(scale), shear: \(horizontalShear), rotation: \(rotation), translation: \(translation))"
    }
}

// MARK: - Codable

extension AffineTransformComponents: Codable {
    private enum CodingKeys: String, CodingKey {
        case scaleWidth, scaleHeight, horizontalShear, rotation, tx, ty
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let scaleWidth = try container.decode(Float.self, forKey: .scaleWidth)
        let scaleHeight = try container.decode(Float.self, forKey: .scaleHeight)
        scale = Size(width: scaleWidth, height: scaleHeight)
        horizontalShear = try container.decode(Float.self, forKey: .horizontalShear)
        rotation = try container.decode(Float.self, forKey: .rotation)
        let tx = try container.decode(Float.self, forKey: .tx)
        let ty = try container.decode(Float.self, forKey: .ty)
        translation = Vector2(dx: tx, dy: ty)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scale.width, forKey: .scaleWidth)
        try container.encode(scale.height, forKey: .scaleHeight)
        try container.encode(horizontalShear, forKey: .horizontalShear)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(translation.dx, forKey: .tx)
        try container.encode(translation.dy, forKey: .ty)
    }
}
