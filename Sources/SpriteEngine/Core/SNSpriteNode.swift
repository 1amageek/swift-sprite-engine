/// A node that displays a textured image or solid color.
///
/// `SNSpriteNode` is the primary way to render visual content in SpriteEngine.
/// It inherits from `SNNode`, gaining all spatial and hierarchy properties.
///
/// ## Platform Mapping
/// ```
/// SpriteKit              SpriteEngine
/// ─────────────────────  ─────────────────────
/// SKSpriteNode           SNSpriteNode
/// ```
///
/// ## Creating Sprites
/// ```swift
/// // From image name (recommended, SpriteKit-style)
/// let player = SNSpriteNode(imageNamed: "player.png")
/// player.position = CGPoint(x: 400, y: 300)
///
/// // From texture object
/// let texture = SNTexture(imageNamed: "enemy.png")
/// let enemy = SNSpriteNode(texture: texture)
///
/// // Solid color rectangle
/// let healthBar = SNSpriteNode(color: .red, size: CGSize(width: 100, height: 10))
///
/// // Empty sprite (configure later)
/// let sprite = SNSpriteNode()
/// sprite.size = CGSize(width: 50, height: 50)
/// sprite.color = .blue
/// ```
///
/// ## Anchor Point
/// The anchor point determines which part of the sprite is at the position:
/// - `(0, 0)`: Bottom-left corner
/// - `(0.5, 0.5)`: Center (default)
/// - `(1, 1)`: Top-right corner
///
/// ## Shaders
/// Custom shaders can be applied for visual effects:
/// ```swift
/// sprite.shader = Shader.grayscale()
/// ```
///
/// ## Warp Geometry
/// Sprites can be deformed using warp geometry:
/// ```swift
/// let warp = SNSNWarpGeometryGrid.wave(columns: 8, rows: 8, amplitude: 0.1, frequency: 2)
/// sprite.warpGeometry = warp
/// sprite.subdivisionLevels = 2
/// ```
open class SNSpriteNode: SNNode, SNWarpable {
    // MARK: - Texture

    /// The texture used to draw the sprite.
    /// When `nil`, the sprite draws as a solid color rectangle.
    public var texture: SNTexture?

    /// Internal texture ID for rendering pipeline.
    internal var textureID: TextureID {
        texture?.textureID ?? .none
    }

    // MARK: - Size and Anchor

    /// The dimensions of the sprite in points.
    public var size: CGSize = .zero

    /// The point within the sprite that corresponds to its position.
    /// Range: (0, 0) to (1, 1). Default: (0.5, 0.5) for center.
    public var anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)

    // MARK: - Color and Blending

    /// The sprite's tint color.
    /// When no texture is set, this is the solid fill color.
    /// When textured, this blends with the texture based on `colorBlendFactor`.
    public var color: Color = .white

    /// How much the color blends with the texture.
    /// Range: 0 (texture only) to 1 (color only).
    /// At 0.5, texture and color are equally blended.
    public var colorBlendFactor: CGFloat = 0

    /// The blend mode used to draw the sprite into the framebuffer.
    ///
    /// The blend mode determines how the sprite's colors combine with the
    /// colors already in the framebuffer.
    ///
    /// ## Example
    /// ```swift
    /// sprite.blendMode = .add  // Additive blending for glow effects
    /// ```
    public var blendMode: SNBlendMode = .alpha

    // MARK: - Nine-Part Scaling

    /// The center rectangle for 9-part stretching of the sprite's texture.
    ///
    /// When this property is set to a value other than the default `(0, 0, 1, 1)`,
    /// the texture is split into a 3x3 grid. The corners maintain their original size,
    /// while the edges and center are stretched to fill the sprite's size.
    ///
    /// The rectangle is specified in unit coordinates where:
    /// - `(0, 0)` is the bottom-left corner of the texture
    /// - `(1, 1)` is the top-right corner of the texture
    ///
    /// ## Example
    /// ```swift
    /// // Create a button that stretches in the middle
    /// let button = SNSpriteNode(imageNamed: "button.png")
    /// button.centerRect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    /// button.size = CGSize(width: 200, height: 50)  // Corners won't stretch
    /// ```
    public var centerRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    // MARK: - Shader

    /// The custom shader applied to this sprite.
    /// When set, the shader's fragment function is used for rendering.
    public var shader: SNShader?

    /// Per-node attribute values for the shader.
    /// Keys are attribute names from the shader's attribute definitions.
    public var attributeValues: [String: SNAttributeValue] = [:]

    // MARK: - Warp Geometry (SNWarpable)

    /// The warp geometry applied to this sprite.
    /// When set, the sprite's mesh is deformed according to the warp.
    public var warpGeometry: SNWarpGeometry?

    /// The number of subdivision levels for warp smoothing.
    /// Higher values create smoother deformations. Default: 0.
    public var subdivisionLevels: Int = 0

    // MARK: - Lighting

    /// A mask defining which light categories affect this sprite.
    /// Compare with `LightNode.categoryBitMask`.
    public var lightingBitMask: UInt32 = 0

    /// A mask defining whether this sprite casts shadows.
    public var shadowCastBitMask: UInt32 = 0

    /// A mask defining whether this sprite receives shadows.
    public var shadowedBitMask: UInt32 = 0

    /// The normal map texture for per-pixel lighting.
    public var normalTexture: SNTexture?

    // MARK: - Initialization

    /// Creates an empty sprite with no texture and zero size.
    public override init() {
        super.init()
    }

    /// Creates a sprite from an image file.
    ///
    /// This is the recommended way to create sprites, similar to SpriteKit's
    /// `SKSpriteNode(imageNamed:)`. The size is automatically set to the
    /// texture's size when the texture is loaded.
    ///
    /// ```swift
    /// let player = SNSpriteNode(imageNamed: "player.png")
    /// ```
    ///
    /// - Parameter imageNamed: The name of the image file in the resource bundle.
    public convenience init(imageNamed: String) {
        let texture = SNTexture(imageNamed: imageNamed)
        self.init(texture: texture)
    }

    /// Creates a sprite from an image file with optional normal mapping.
    ///
    /// When `normalMapped` is `true`, a normal map is automatically generated
    /// from the texture to simulate 3D lighting effects.
    ///
    /// ```swift
    /// let rock = SNSpriteNode(imageNamed: "rock.png", normalMapped: true)
    /// ```
    ///
    /// - Parameters:
    ///   - imageNamed: The name of the image file in the resource bundle.
    ///   - normalMapped: If `true`, generates a normal map from the texture.
    public convenience init(imageNamed: String, normalMapped: Bool) {
        let texture = SNTexture(imageNamed: imageNamed)
        self.init(texture: texture)
        if normalMapped {
            self.normalTexture = texture.generatingNormalMap()
        }
    }

    /// Creates a sprite with the specified texture.
    ///
    /// The sprite's size is automatically set to the texture's size.
    ///
    /// - Parameter texture: The texture to display.
    public init(texture: SNTexture) {
        super.init()
        self.texture = texture
        self.size = texture.size
    }

    /// Creates a sprite with the specified texture and explicit size.
    ///
    /// Use this initializer when you want to display a texture at a different
    /// size than its natural dimensions.
    ///
    /// - Parameters:
    ///   - texture: The texture to display.
    ///   - size: The size of the sprite in points.
    public init(texture: SNTexture, size: CGSize) {
        super.init()
        self.texture = texture
        self.size = size
    }

    /// Creates a sprite with the specified texture, color, and size.
    ///
    /// This initializer allows you to create a textured sprite with a tint color
    /// applied from the start. The `colorBlendFactor` is automatically set to
    /// blend the color with the texture.
    ///
    /// - Parameters:
    ///   - texture: The texture to display, or `nil` for a solid color sprite.
    ///   - color: The tint color to apply.
    ///   - size: The size of the sprite in points.
    public init(texture: SNTexture?, color: Color, size: CGSize) {
        super.init()
        self.texture = texture
        self.color = color
        self.size = size
        if texture == nil {
            self.colorBlendFactor = 1.0
        }
    }

    /// Creates a sprite with the specified texture and normal map.
    ///
    /// Use this initializer when you have a pre-made normal map texture
    /// for lighting effects.
    ///
    /// - Parameters:
    ///   - texture: The texture to display.
    ///   - normalMap: The normal map texture for lighting calculations.
    public convenience init(texture: SNTexture, normalMap: SNTexture?) {
        self.init(texture: texture)
        self.normalTexture = normalMap
    }

    /// Creates a solid-color sprite with the specified size.
    ///
    /// - Parameters:
    ///   - color: The fill color.
    ///   - size: The dimensions of the sprite.
    public init(color: Color, size: CGSize) {
        super.init()
        self.color = color
        self.size = size
        self.colorBlendFactor = 1.0  // Full color, no texture
    }

    // MARK: - Frame

    /// Returns the bounding rectangle in parent coordinates.
    open override var frame: CGRect {
        let offsetX = size.width * anchorPoint.x
        let offsetY = size.height * anchorPoint.y
        return CGRect(
            x: position.x - offsetX,
            y: position.y - offsetY,
            width: size.width,
            height: size.height
        )
    }

    // MARK: - Draw Command Generation

    /// Generates a draw command for this sprite.
    ///
    /// This method is called during the render phase to collect all visible sprites.
    internal func makeDrawCommand() -> DrawCommand {
        DrawCommand(
            worldPosition: worldPosition,
            worldRotation: worldRotation,
            worldScale: worldScale,
            size: size,
            anchorPoint: anchorPoint,
            textureID: textureID,
            textureRect: texture?.textureRect() ?? Rect(x: 0, y: 0, width: 1, height: 1),
            filteringMode: texture?.filteringMode ?? .linear,
            usesMipmaps: texture?.usesMipmaps ?? false,
            color: effectiveColor,
            alpha: worldAlpha,
            zPosition: zPosition,
            blendMode: blendMode,
            centerRect: centerRect
        )
    }

    /// The color to use for rendering, taking into account color blend factor.
    private var effectiveColor: Color {
        if colorBlendFactor >= 1.0 || texture == nil {
            return color
        } else if colorBlendFactor <= 0.0 {
            return .white
        } else {
            // Blend between white (texture color) and tint color
            return Color.lerp(from: .white, to: color, t: colorBlendFactor)
        }
    }

    // MARK: - CustomStringConvertible

    open override var description: String {
        let nameStr = name.map { "\"\($0)\"" } ?? "unnamed"
        let textureStr = texture?.name ?? "none"
        return "SNSpriteNode(\(nameStr), size: \(size), texture: \(textureStr))"
    }
}

// MARK: - Convenience Methods

extension SNSpriteNode {
    /// Sets the size to match a square with the given side length.
    @inlinable
    public func setSize(square side: CGFloat) {
        size = CGSize(width: side, height: side)
    }

    /// Scales the sprite to the specified size.
    ///
    /// This method adjusts the sprite's `xScale` and `yScale` properties
    /// to make the sprite render at the specified size, based on its
    /// current `size` property.
    ///
    /// - Parameter targetSize: The target size for the sprite.
    public func scale(to targetSize: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        scale = CGSize(
            width: targetSize.width / size.width,
            height: targetSize.height / size.height
        )
    }

    /// Centers the anchor point (0.5, 0.5).
    @inlinable
    public func centerAnchor() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
    }

    /// Sets the anchor point to the bottom-left (0, 0).
    @inlinable
    public func anchorBottomLeft() {
        anchorPoint = CGPoint(x: 0, y: 0)
    }

    /// Sets the anchor point to the bottom-center (0.5, 0).
    @inlinable
    public func anchorBottomCenter() {
        anchorPoint = CGPoint(x: 0.5, y: 0)
    }

    /// Sets the anchor point to the top-left (0, 1).
    @inlinable
    public func anchorTopLeft() {
        anchorPoint = CGPoint(x: 0, y: 1)
    }
}

// MARK: - Shader Attribute Methods

extension SNSpriteNode {
    /// Sets a shader attribute value.
    ///
    /// - Parameters:
    ///   - value: The attribute value.
    ///   - name: The attribute name as defined in the shader.
    public func setValue(_ value: SNAttributeValue, forAttribute name: String) {
        attributeValues[name] = value
    }

    /// Returns the shader attribute value for the given name.
    ///
    /// - Parameter name: The attribute name.
    /// - Returns: The attribute value, or nil if not set.
    public func value(forAttribute name: String) -> SNAttributeValue? {
        attributeValues[name]
    }

    /// Removes a shader attribute value.
    ///
    /// - Parameter name: The attribute name to remove.
    public func removeValue(forAttribute name: String) {
        attributeValues.removeValue(forKey: name)
    }

    /// Removes all shader attribute values.
    public func removeAllAttributeValues() {
        attributeValues.removeAll()
    }
}

