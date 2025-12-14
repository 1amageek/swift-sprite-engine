/// Texture filtering modes to use when a texture is drawn at a size
/// other than its native size.
///
/// The filtering mode affects how textures appear when scaled up or down.
///
/// ## Example
/// ```swift
/// // For pixel art, use nearest neighbor filtering
/// texture.filteringMode = .nearest
///
/// // For smooth scaling, use linear filtering
/// texture.filteringMode = .linear
/// ```
public enum TextureFilteringMode: Int, Hashable, Sendable {
    /// Each pixel is drawn using the nearest point in the texture.
    ///
    /// This mode is faster and preserves sharp edges, making it ideal
    /// for pixel art. However, results may appear pixelated when scaled.
    case nearest = 0

    /// Each pixel is drawn using a linear filter of multiple texels.
    ///
    /// This mode produces smoother results but may be slower.
    /// It's better for photographs and non-pixel-art graphics.
    case linear = 1
}
