/// A protocol for nodes that support warp geometry deformation.
///
/// Types conforming to `Warpable` can have their geometry deformed
/// using `WarpGeometry` objects. This enables effects like bending,
/// twisting, and wave animations on sprites and other nodes.
///
/// ## Usage
/// ```swift
/// // Apply a warp to a sprite
/// let warp = WarpGeometryGrid.wave(columns: 8, rows: 8, amplitude: 0.1, frequency: 2)
/// sprite.warpGeometry = warp
/// sprite.subdivisionLevels = 2
/// ```
public protocol Warpable: AnyObject {
    /// The warp geometry applied to this node.
    ///
    /// When set, the node's geometry is deformed according to the
    /// warp geometry's source and destination positions. Set to `nil`
    /// to remove the warp effect.
    var warpGeometry: WarpGeometry? { get set }

    /// The number of subdivision levels for warp smoothing.
    ///
    /// Higher values create smoother deformations at the cost of
    /// more geometry. Typical values are 0-3:
    /// - 0: No subdivision (raw grid vertices)
    /// - 1: One level of subdivision (4x geometry)
    /// - 2: Two levels of subdivision (16x geometry)
    /// - 3: Three levels of subdivision (64x geometry)
    var subdivisionLevels: Int { get set }
}
