/// Base class for warp geometry definitions.
///
/// `SNWarpGeometry` defines how a sprite or other node's geometry can be
/// deformed. Subclasses provide specific deformation methods like grids.
///
/// ## Usage
/// ```swift
/// // Create a grid-based warp
/// let warp = SNSNWarpGeometryGrid(columns: 4, rows: 4)
///
/// // Apply to a sprite
/// sprite.warpGeometry = warp
/// ```
public class SNWarpGeometry {
    /// The number of vertices in this warp geometry.
    public var vertexCount: Int {
        0
    }

    /// Creates a new warp geometry.
    public init() {}

    /// Returns the source position for a vertex at the given index.
    ///
    /// - Parameter index: The vertex index.
    /// - Returns: The source position in normalized coordinates (0-1).
    public func sourcePosition(at index: Int) -> Point {
        Point(x: 0, y: 0)
    }

    /// Returns the destination position for a vertex at the given index.
    ///
    /// - Parameter index: The vertex index.
    /// - Returns: The destination position in normalized coordinates.
    public func destinationPosition(at index: Int) -> Point {
        Point(x: 0, y: 0)
    }

    /// Creates a copy of this warp geometry.
    ///
    /// - Returns: A new warp geometry with the same configuration.
    public func copy() -> SNWarpGeometry {
        SNWarpGeometry()
    }
}
