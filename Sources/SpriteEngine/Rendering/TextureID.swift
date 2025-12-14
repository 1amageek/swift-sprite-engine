/// An opaque identifier for a texture managed by the rendering backend.
///
/// This is an internal implementation detail. Users should work with the
/// `Texture` class instead of directly manipulating TextureIDs.
///
/// Textures are loaded and managed by the platform-specific layer:
/// - Web: JavaScript/WebGPU loads textures and assigns IDs
/// - Preview: TextureRegistry loads from Bundle and assigns IDs
///
/// ## Rendering Flow
/// ```
/// 1. User: Texture(imageNamed: "player.png")
/// 2. Registry: assigns TextureID, loads image data
/// 3. Sprite: stores Texture reference
/// 4. Render: DrawCommand carries TextureID
/// 5. Platform: looks up texture data by ID, renders
/// ```
internal struct TextureID: RawRepresentable, Hashable, Sendable {
    internal let rawValue: UInt32

    internal init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    /// Represents no texture (solid color rendering).
    internal static let none = TextureID(rawValue: 0)
}

// MARK: - CustomStringConvertible

extension TextureID: CustomStringConvertible {
    internal var description: String {
        rawValue == 0 ? "TextureID.none" : "TextureID(\(rawValue))"
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension TextureID: ExpressibleByIntegerLiteral {
    internal init(integerLiteral value: UInt32) {
        self.rawValue = value
    }
}
