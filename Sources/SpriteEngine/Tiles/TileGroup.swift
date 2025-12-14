/// A set of tiles that collectively define one type of terrain.
///
/// `TileGroup` contains either the definition of a single tile or an array of
/// `TileGroupRule` objects that define adjacency rules for auto-tiling.
///
/// ## Usage
/// ```swift
/// // Simple tile group with a single definition
/// let grassGroup = TileGroup(tileDefinition: grassTile)
///
/// // Complex tile group with rules for auto-tiling
/// let waterGroup = TileGroup(rules: [
///     TileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [waterCenter]),
///     TileGroupRule(adjacency: .adjacencyEdgeTop, tileDefinitions: [waterTopEdge]),
///     TileGroupRule(adjacency: .adjacencyCornerTopLeft, tileDefinitions: [waterCornerTL]),
///     // ... more rules for all edge cases
/// ])
/// ```
public final class TileGroup {
    /// An optional name for this tile group.
    public var name: String?

    /// The rules that define tile placement based on adjacency.
    public var rules: [TileGroupRule]

    /// Whether this is an empty (eraser) tile group.
    private let isEmpty: Bool

    /// Creates a simple tile group with a single tile definition.
    ///
    /// - Parameter tileDefinition: The tile definition for this group.
    public init(tileDefinition: TileDefinition) {
        self.name = nil
        self.rules = [
            TileGroupRule(adjacency: [], tileDefinitions: [tileDefinition])
        ]
        self.isEmpty = false
    }

    /// Creates a tile group with the specified rules.
    ///
    /// - Parameter rules: The tile group rules.
    public init(rules: [TileGroupRule]) {
        self.name = nil
        self.rules = rules
        self.isEmpty = false
    }

    /// Private initializer for empty tile groups.
    private init(empty: Bool) {
        self.name = nil
        self.rules = []
        self.isEmpty = empty
    }

    /// Creates an empty tile group that erases tiles at that location.
    ///
    /// - Returns: An empty tile group.
    public static func empty() -> TileGroup {
        TileGroup(empty: true)
    }

    /// Returns the rule matching the given adjacency mask.
    ///
    /// - Parameter adjacency: The adjacency mask to match.
    /// - Returns: The matching rule, or `nil` if no rule matches.
    public func rule(for adjacency: TileAdjacencyMask) -> TileGroupRule? {
        // Find exact match first
        if let exactMatch = rules.first(where: { $0.adjacency == adjacency }) {
            return exactMatch
        }

        // Find best partial match (rule that is subset of adjacency)
        var bestMatch: TileGroupRule?
        var bestMatchCount = -1

        for rule in rules {
            if adjacency.contains(rule.adjacency) {
                let matchCount = rule.adjacency.rawValue.nonzeroBitCount
                if matchCount > bestMatchCount {
                    bestMatch = rule
                    bestMatchCount = matchCount
                }
            }
        }

        return bestMatch ?? rules.first
    }

    /// Returns a tile definition for the given adjacency and position.
    ///
    /// - Parameters:
    ///   - adjacency: The adjacency mask.
    ///   - column: The column index (for deterministic weighted selection).
    ///   - row: The row index (for deterministic weighted selection).
    /// - Returns: A tile definition, or `nil` for empty groups.
    public func tileDefinition(for adjacency: TileAdjacencyMask, atColumn column: Int, row: Int) -> TileDefinition? {
        guard !isEmpty else { return nil }
        return rule(for: adjacency)?.selectTileDefinition(atColumn: column, row: row)
    }

    /// Returns a tile definition for the given adjacency.
    ///
    /// - Note: This overload always returns the first definition.
    ///         Use `tileDefinition(for:atColumn:row:)` for weighted selection.
    ///
    /// - Parameter adjacency: The adjacency mask.
    /// - Returns: A tile definition, or `nil` for empty groups.
    @available(*, deprecated, message: "Use tileDefinition(for:atColumn:row:) for deterministic weighted selection")
    public func tileDefinition(for adjacency: TileAdjacencyMask) -> TileDefinition? {
        guard !isEmpty else { return nil }
        return rule(for: adjacency)?.tileDefinitions.first
    }

    /// The default tile definition (ignoring adjacency).
    public var defaultTileDefinition: TileDefinition? {
        rules.first?.tileDefinitions.first
    }
}

// MARK: - UInt32 Extension for Bit Counting

extension UInt32 {
    /// The number of non-zero bits in this value.
    var nonzeroBitCount: Int {
        var count = 0
        var value = self
        while value != 0 {
            count += Int(value & 1)
            value >>= 1
        }
        return count
    }
}
