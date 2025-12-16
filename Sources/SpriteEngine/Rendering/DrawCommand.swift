/// The fundamental unit of rendering data.
///
/// `DrawCommand` is a platform-agnostic structure that describes how to render
/// a single sprite. The scene graph generates an array of draw commands each frame,
/// which is then consumed by the rendering backend (WebGPU or SwiftUI Canvas).
///
/// ## Memory Layout
/// This struct is designed as POD (Plain Old Data) for efficient transfer to WebGPU.
internal struct DrawCommand: Sendable {
    // MARK: - Transform (World Space)

    /// The position in world coordinates.
    var worldPosition: Point

    /// The rotation in radians.
    var worldRotation: Float

    /// The scale factors.
    var worldScale: Size

    // MARK: - Sprite Data

    /// The base size of the sprite in points.
    var size: Size

    /// The anchor point determining which part of the sprite is at the position.
    /// Range: (0, 0) to (1, 1). Default: (0.5, 0.5) for center.
    var anchorPoint: Point

    /// The texture identifier. `TextureID.none` (0) means solid color rendering.
    var textureID: TextureID

    /// The portion of the texture to sample from.
    /// Default: (0, 0, 1, 1) for the entire texture.
    var textureRect: Rect

    /// The texture filtering mode.
    var filteringMode: TextureFilteringMode

    /// Whether mipmaps should be used for this texture.
    var usesMipmaps: Bool

    // MARK: - Appearance

    /// The tint color of the sprite.
    var color: Color

    /// The combined alpha value (sprite alpha * parent hierarchy alpha).
    var alpha: Float

    /// The z-position for draw ordering. Higher values are drawn on top.
    var zPosition: Float

    /// The blend mode used to combine this sprite with the framebuffer.
    var blendMode: SNBlendMode

    /// The center rectangle for 9-part scaling.
    /// Default: (0, 0, 1, 1) means no 9-part scaling.
    var centerRect: Rect

    // MARK: - Initialization

    /// Creates a draw command with all properties specified.
    init(
        worldPosition: Point = .zero,
        worldRotation: Float = 0,
        worldScale: Size = Size(width: 1, height: 1),
        size: Size = .zero,
        anchorPoint: Point = Point(x: 0.5, y: 0.5),
        textureID: TextureID = .none,
        textureRect: Rect = Rect(x: 0, y: 0, width: 1, height: 1),
        filteringMode: TextureFilteringMode = .linear,
        usesMipmaps: Bool = false,
        color: Color = .white,
        alpha: Float = 1,
        zPosition: Float = 0,
        blendMode: SNBlendMode = .alpha,
        centerRect: Rect = Rect(x: 0, y: 0, width: 1, height: 1)
    ) {
        self.worldPosition = worldPosition
        self.worldRotation = worldRotation
        self.worldScale = worldScale
        self.size = size
        self.anchorPoint = anchorPoint
        self.textureID = textureID
        self.textureRect = textureRect
        self.filteringMode = filteringMode
        self.usesMipmaps = usesMipmaps
        self.color = color
        self.alpha = alpha
        self.zPosition = zPosition
        self.blendMode = blendMode
        self.centerRect = centerRect
    }
}

// MARK: - Computed Properties

extension DrawCommand {
    /// The final rendered size (size * worldScale).
    @inlinable
    var renderedSize: Size {
        Size(
            width: size.width * worldScale.width,
            height: size.height * worldScale.height
        )
    }

    /// The bounding rectangle in world coordinates.
    @inlinable
    var bounds: Rect {
        let finalSize = renderedSize
        let offsetX = finalSize.width * anchorPoint.x
        let offsetY = finalSize.height * anchorPoint.y
        return Rect(
            x: worldPosition.x - offsetX,
            y: worldPosition.y - offsetY,
            width: finalSize.width,
            height: finalSize.height
        )
    }
}

// MARK: - Equatable

extension DrawCommand: Equatable {}

// MARK: - CustomStringConvertible

extension DrawCommand: CustomStringConvertible {
    var description: String {
        "DrawCommand(pos: \(worldPosition), size: \(size), texture: \(textureID), z: \(zPosition))"
    }
}
