/// Rules that describe how various tiles should be placed in a map.
///
/// When a tile is filled in a tile map, the tile group rule defines how
/// neighboring tiles are populated based on adjacency rules. A rule with
/// multiple definitions uses the placement weights of the definitions to
/// randomly select which to use.
///
/// ## Usage
/// ```swift
/// // Create a rule for center tiles (surrounded by same terrain)
/// let centerRule = TileGroupRule(
///     adjacency: .adjacencyAll,
///     tileDefinitions: [centerTile]
/// )
///
/// // Create a rule for top edge
/// let topEdgeRule = TileGroupRule(
///     adjacency: .adjacencyEdgeTop,
///     tileDefinitions: [topEdgeTile]
/// )
/// ```
public final class TileGroupRule {
    /// An optional name for this rule.
    public var name: String?

    /// The adjacency requirement for this rule.
    public var adjacency: TileAdjacencyMask

    /// The tile definitions used for this rule.
    /// When multiple definitions are provided, one is selected based on placement weights.
    public var tileDefinitions: [TileDefinition]

    /// Creates a tile group rule with adjacency and tile definitions.
    ///
    /// - Parameters:
    ///   - adjacency: The adjacency mask defining when this rule applies.
    ///   - tileDefinitions: The tile definitions to use when the rule matches.
    public init(adjacency: TileAdjacencyMask, tileDefinitions: [TileDefinition]) {
        self.name = nil
        self.adjacency = adjacency
        self.tileDefinitions = tileDefinitions
    }

    /// Selects a tile definition based on placement weights.
    ///
    /// - Returns: A randomly selected tile definition, or `nil` if none available.
    public func selectTileDefinition() -> TileDefinition? {
        guard !tileDefinitions.isEmpty else { return nil }
        guard tileDefinitions.count > 1 else { return tileDefinitions.first }

        // Calculate total weight
        let totalWeight = tileDefinitions.reduce(0) { $0 + $1.placementWeight }
        guard totalWeight > 0 else { return tileDefinitions.first }

        // Select based on weight
        var randomValue = Int.random(in: 0..<totalWeight)
        for definition in tileDefinitions {
            randomValue -= definition.placementWeight
            if randomValue < 0 {
                return definition
            }
        }

        return tileDefinitions.first
    }
}
