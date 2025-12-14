/// A bitmask defining how neighboring tiles affect tile placement.
///
/// `TileAdjacencyMask` is used in tile group rules to specify which
/// tile definitions to use based on the presence of adjacent tiles.
///
/// ## Usage
/// ```swift
/// // A tile with neighbors on all sides
/// let surrounded = TileAdjacencyMask.adjacencyAll
///
/// // A tile with only a neighbor above
/// let topOnly = TileAdjacencyMask.adjacencyUp
///
/// // A corner piece
/// let corner: TileAdjacencyMask = [.adjacencyUp, .adjacencyRight]
/// ```
public struct TileAdjacencyMask: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    // MARK: - Cardinal Directions

    /// Adjacent tile above.
    public static let adjacencyUp = TileAdjacencyMask(rawValue: 1 << 0)

    /// Adjacent tile to the upper-right.
    public static let adjacencyUpRight = TileAdjacencyMask(rawValue: 1 << 1)

    /// Adjacent tile to the right.
    public static let adjacencyRight = TileAdjacencyMask(rawValue: 1 << 2)

    /// Adjacent tile to the lower-right.
    public static let adjacencyDownRight = TileAdjacencyMask(rawValue: 1 << 3)

    /// Adjacent tile below.
    public static let adjacencyDown = TileAdjacencyMask(rawValue: 1 << 4)

    /// Adjacent tile to the lower-left.
    public static let adjacencyDownLeft = TileAdjacencyMask(rawValue: 1 << 5)

    /// Adjacent tile to the left.
    public static let adjacencyLeft = TileAdjacencyMask(rawValue: 1 << 6)

    /// Adjacent tile to the upper-left.
    public static let adjacencyUpLeft = TileAdjacencyMask(rawValue: 1 << 7)

    // MARK: - Compound Masks

    /// All cardinal directions (up, right, down, left).
    public static let adjacencyCardinal: TileAdjacencyMask = [
        .adjacencyUp, .adjacencyRight, .adjacencyDown, .adjacencyLeft
    ]

    /// All diagonal directions (corners).
    public static let adjacencyDiagonal: TileAdjacencyMask = [
        .adjacencyUpRight, .adjacencyDownRight, .adjacencyDownLeft, .adjacencyUpLeft
    ]

    /// All eight directions.
    public static let adjacencyAll: TileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpRight, .adjacencyRight, .adjacencyDownRight,
        .adjacencyDown, .adjacencyDownLeft, .adjacencyLeft, .adjacencyUpLeft
    ]

    // MARK: - Edge Masks (for 9-slice auto-tiling)

    /// Top edge (no neighbor above, neighbors left and right).
    public static let adjacencyEdgeTop: TileAdjacencyMask = [
        .adjacencyLeft, .adjacencyRight, .adjacencyDown,
        .adjacencyDownLeft, .adjacencyDownRight
    ]

    /// Bottom edge (no neighbor below, neighbors left and right).
    public static let adjacencyEdgeBottom: TileAdjacencyMask = [
        .adjacencyLeft, .adjacencyRight, .adjacencyUp,
        .adjacencyUpLeft, .adjacencyUpRight
    ]

    /// Left edge (no neighbor to the left, neighbors above and below).
    public static let adjacencyEdgeLeft: TileAdjacencyMask = [
        .adjacencyUp, .adjacencyDown, .adjacencyRight,
        .adjacencyUpRight, .adjacencyDownRight
    ]

    /// Right edge (no neighbor to the right, neighbors above and below).
    public static let adjacencyEdgeRight: TileAdjacencyMask = [
        .adjacencyUp, .adjacencyDown, .adjacencyLeft,
        .adjacencyUpLeft, .adjacencyDownLeft
    ]

    // MARK: - Corner Masks (for 9-slice auto-tiling)

    /// Top-left corner.
    public static let adjacencyCornerTopLeft: TileAdjacencyMask = [
        .adjacencyRight, .adjacencyDown, .adjacencyDownRight
    ]

    /// Top-right corner.
    public static let adjacencyCornerTopRight: TileAdjacencyMask = [
        .adjacencyLeft, .adjacencyDown, .adjacencyDownLeft
    ]

    /// Bottom-left corner.
    public static let adjacencyCornerBottomLeft: TileAdjacencyMask = [
        .adjacencyRight, .adjacencyUp, .adjacencyUpRight
    ]

    /// Bottom-right corner.
    public static let adjacencyCornerBottomRight: TileAdjacencyMask = [
        .adjacencyLeft, .adjacencyUp, .adjacencyUpLeft
    ]

    // MARK: - Hexagonal Adjacency

    /// Upper-left for hexagonal grids.
    public static let hexagonalAdjacencyUpperLeft = TileAdjacencyMask(rawValue: 1 << 8)

    /// Upper-right for hexagonal grids.
    public static let hexagonalAdjacencyUpperRight = TileAdjacencyMask(rawValue: 1 << 9)

    /// Right for hexagonal grids.
    public static let hexagonalAdjacencyRight = TileAdjacencyMask(rawValue: 1 << 10)

    /// Lower-right for hexagonal grids.
    public static let hexagonalAdjacencyLowerRight = TileAdjacencyMask(rawValue: 1 << 11)

    /// Lower-left for hexagonal grids.
    public static let hexagonalAdjacencyLowerLeft = TileAdjacencyMask(rawValue: 1 << 12)

    /// Left for hexagonal grids.
    public static let hexagonalAdjacencyLeft = TileAdjacencyMask(rawValue: 1 << 13)

    /// All hexagonal adjacencies.
    public static let hexagonalAdjacencyAll: TileAdjacencyMask = [
        .hexagonalAdjacencyUpperLeft, .hexagonalAdjacencyUpperRight,
        .hexagonalAdjacencyRight, .hexagonalAdjacencyLowerRight,
        .hexagonalAdjacencyLowerLeft, .hexagonalAdjacencyLeft
    ]
}
