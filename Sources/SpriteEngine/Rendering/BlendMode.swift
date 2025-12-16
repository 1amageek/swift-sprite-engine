/// The modes that describe how source and destination pixel colors
/// are used to calculate the new destination color.
///
/// Blend modes determine how a sprite's colors combine with the colors
/// already in the framebuffer.
///
/// ## Example
/// ```swift
/// sprite.blendMode = .add  // Additive blending for glow effects
/// ```
public enum SNBlendMode: Int, Hashable, Sendable {
    /// The source and destination colors are blended by multiplying
    /// the source alpha value.
    ///
    /// This is the default blend mode. The formula is:
    /// `result = source * sourceAlpha + destination * (1 - sourceAlpha)`
    case alpha = 0

    /// The source and destination colors are added together.
    ///
    /// Useful for glow effects, fire, and other additive lighting.
    /// The formula is: `result = source + destination`
    case add = 1

    /// The source color is subtracted from the destination color.
    ///
    /// The formula is: `result = destination - source`
    case subtract = 2

    /// The source color is multiplied by the destination color.
    ///
    /// Useful for shadows and darkening effects.
    /// The formula is: `result = source * destination`
    case multiply = 3

    /// The source color is multiplied by the destination color and then doubled.
    ///
    /// Similar to multiply but with increased intensity.
    /// The formula is: `result = 2 * source * destination`
    case multiplyX2 = 4

    /// The source color is added to the destination color times the inverted source color.
    ///
    /// Useful for lightening effects.
    /// The formula is: `result = source + destination * (1 - source)`
    case screen = 5

    /// The source color replaces the destination color.
    ///
    /// No blending occurs; the source completely overwrites the destination.
    case replace = 6

    /// The source color is multiplied by the destination alpha.
    case multiplyAlpha = 7
}
