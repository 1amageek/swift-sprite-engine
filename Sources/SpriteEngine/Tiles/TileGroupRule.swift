/// Rules that describe how various tiles should be placed in a map.
///
/// When a tile is filled in a tile map, the tile group rule defines how
/// neighboring tiles are populated based on adjacency rules. A rule with
/// multiple definitions uses the placement weights of the definitions to
/// select which to use deterministically based on position.
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

    /// Selects a tile definition based on placement weights using a seeded random generator.
    ///
    /// - Parameter generator: A random number generator to use for selection.
    /// - Returns: A selected tile definition, or `nil` if none available.
    public func selectTileDefinition<T: RandomNumberGenerator>(using generator: inout T) -> TileDefinition? {
        guard !tileDefinitions.isEmpty else { return nil }
        guard tileDefinitions.count > 1 else { return tileDefinitions.first }

        // Calculate total weight
        let totalWeight = tileDefinitions.reduce(0) { $0 + $1.placementWeight }
        guard totalWeight > 0 else { return tileDefinitions.first }

        // Select based on weight using provided generator
        var randomValue = Int.random(in: 0..<totalWeight, using: &generator)
        for definition in tileDefinitions {
            randomValue -= definition.placementWeight
            if randomValue < 0 {
                return definition
            }
        }

        return tileDefinitions.first
    }

    /// Selects a tile definition deterministically based on tile position.
    ///
    /// Uses a fixed hash function (FNV-1a) to select consistently for the same coordinates
    /// across all runs and platforms.
    ///
    /// - Parameters:
    ///   - column: The column index of the tile.
    ///   - row: The row index of the tile.
    /// - Returns: A selected tile definition, or `nil` if none available.
    public func selectTileDefinition(atColumn column: Int, row: Int) -> TileDefinition? {
        guard !tileDefinitions.isEmpty else { return nil }
        guard tileDefinitions.count > 1 else { return tileDefinitions.first }

        // Calculate total weight
        let totalWeight = tileDefinitions.reduce(0) { $0 + $1.placementWeight }
        guard totalWeight > 0 else { return tileDefinitions.first }

        // Use FNV-1a hash for deterministic, cross-platform consistent hashing
        // This does NOT use Swift's Hasher (which is seeded per-process)
        let hash = Self.fnv1aHash(column: column, row: row)

        // Map hash to weight range
        var randomValue = Int(hash % UInt64(totalWeight))
        for definition in tileDefinitions {
            randomValue -= definition.placementWeight
            if randomValue < 0 {
                return definition
            }
        }

        return tileDefinitions.first
    }

    /// FNV-1a hash function for deterministic hashing across all runs.
    /// Uses fixed constants that don't change between process runs.
    private static func fnv1aHash(column: Int, row: Int) -> UInt64 {
        // FNV-1a parameters for 64-bit
        let fnvPrime: UInt64 = 1099511628211
        let fnvOffsetBasis: UInt64 = 14695981039346656037

        var hash = fnvOffsetBasis

        // Hash column bytes
        var col = UInt64(bitPattern: Int64(column))
        for _ in 0..<8 {
            hash ^= col & 0xFF
            hash = hash &* fnvPrime
            col >>= 8
        }

        // Hash row bytes
        var r = UInt64(bitPattern: Int64(row))
        for _ in 0..<8 {
            hash ^= r & 0xFF
            hash = hash &* fnvPrime
            r >>= 8
        }

        return hash
    }

    /// Selects a tile definition based on placement weights.
    ///
    /// - Note: This method uses position-based hashing for deterministic results.
    ///         For explicit control, use `selectTileDefinition(atColumn:row:)` or
    ///         `selectTileDefinition(using:)`.
    ///
    /// - Returns: The first tile definition (deterministic fallback).
    @available(*, deprecated, message: "Use selectTileDefinition(atColumn:row:) for deterministic selection")
    public func selectTileDefinition() -> TileDefinition? {
        // Return first definition for backward compatibility with deterministic behavior
        return tileDefinitions.first
    }
}
