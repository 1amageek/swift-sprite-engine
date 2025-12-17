/// The allowed rotations for a tile definition.
///
/// Tiles can be rotated in 90° increments.
public enum TileRotation: Int, Sendable {
    /// No rotation (0°).
    case rotation0 = 0
    /// Rotated 90° counter-clockwise.
    case rotation90 = 1
    /// Rotated 180°.
    case rotation180 = 2
    /// Rotated 270° counter-clockwise (90° clockwise).
    case rotation270 = 3

    /// The rotation angle in radians.
    public var radians: CGFloat {
        CGFloat(rawValue) * .pi / 2
    }

    /// The rotation angle in degrees.
    public var degrees: CGFloat {
        CGFloat(rawValue) * 90
    }
}
