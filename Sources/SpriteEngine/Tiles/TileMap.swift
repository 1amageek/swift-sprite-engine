/// A node that displays a two-dimensional array of tiles.
///
/// `TileMap` is a specialized node for rendering tile-based levels.
/// It supports auto-tiling with adjacency rules, animated tiles,
/// collision detection, and efficient rendering.
///
/// ## Usage
/// ```swift
/// // Create tile definitions
/// let groundTile = TileDefinition(color: .brown)
/// groundTile.isCollidable = true
///
/// // Create a tile group
/// let groundGroup = TileGroup(tileDefinition: groundTile)
///
/// // Create a tile set
/// let tileSet = TileSet(tileGroups: [groundGroup])
/// tileSet.defaultTileSize = Size(width: 16, height: 16)
///
/// // Create the tile map
/// let tileMap = TileMap(tileSet: tileSet, columns: 20, rows: 15)
///
/// // Fill with ground
/// tileMap.fill(with: groundGroup)
///
/// scene.addChild(tileMap)
/// ```
public final class SNTileMap: SNNode {
    // MARK: - Properties

    /// The tile set used by this map.
    public let tileSet: TileSet

    /// The number of columns in the tile map.
    public let numberOfColumns: Int

    /// The number of rows in the tile map.
    public let numberOfRows: Int

    /// The size of each tile in points.
    public var tileSize: Size {
        tileSet.defaultTileSize
    }

    /// The anchor point for positioning tiles.
    /// Default: (0.5, 0.5) means center is at the node's position.
    public var anchorPoint: Point = Point(x: 0.5, y: 0.5)

    /// The total size of the tile map in points.
    public var mapSize: Size {
        Size(
            width: CGFloat(numberOfColumns) * tileSize.width,
            height: CGFloat(numberOfRows) * tileSize.height
        )
    }

    // MARK: - Tinting

    /// The base color for the tile map.
    public var color: Color = .white

    /// Controls the blending between textures and the color.
    /// 0 = no color blending, 1 = maximum color blending.
    public var colorBlendFactor: CGFloat = 0

    /// The blend mode used when compositing tiles.
    public var blendMode: SNBlendMode = .alpha

    // MARK: - Lighting

    /// A mask that defines how the tile map is lit by light nodes in the scene.
    ///
    /// When a light node's `categoryBitMask` matches any bits in this mask,
    /// the light will affect this tile map.
    public var lightingBitMask: UInt32 = 0

    // MARK: - Shader

    /// Defines a shader which is applied to each tile of the tile map.
    public var shader: SNShader?

    /// The values of each attribute associated with the tile map's attached shader.
    public var attributeValues: [String: SNAttributeValue] = [:]

    /// Sets an attribute value for an attached shader.
    ///
    /// - Parameters:
    ///   - value: The attribute value.
    ///   - attribute: The attribute name.
    public func setValue(_ value: SNAttributeValue, forAttribute attribute: String) {
        attributeValues[attribute] = value
    }

    /// Returns the value of a shader attribute.
    ///
    /// - Parameter name: The attribute name.
    /// - Returns: The attribute value, or `nil` if not found.
    public func value(forAttributeNamed name: String) -> SNAttributeValue? {
        attributeValues[name]
    }

    // MARK: - Internal Storage

    /// Tile groups for each cell.
    private var tileGroups: [TileGroup?]

    /// Tile definitions for each cell (may override group selection).
    private var tileDefinitions: [TileDefinition?]

    // MARK: - Initialization

    /// Creates a tile map with the specified tile set and dimensions.
    ///
    /// - Parameters:
    ///   - tileSet: The tile set to use.
    ///   - columns: The number of columns.
    ///   - rows: The number of rows.
    public init(tileSet: TileSet, columns: Int, rows: Int) {
        self.tileSet = tileSet
        self.numberOfColumns = columns
        self.numberOfRows = rows
        self.tileGroups = Array(repeating: nil, count: columns * rows)
        self.tileDefinitions = Array(repeating: nil, count: columns * rows)
        super.init()
    }

    // MARK: - Tile Access

    /// Returns the tile group at the specified position.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: The tile group, or `nil` if empty or out of bounds.
    public func tileGroup(atColumn column: Int, row: Int) -> TileGroup? {
        guard isValidPosition(column: column, row: row) else { return nil }
        return tileGroups[row * numberOfColumns + column]
    }

    /// Returns the tile definition at the specified position.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: The tile definition, or `nil` if empty or out of bounds.
    public func tileDefinition(atColumn column: Int, row: Int) -> TileDefinition? {
        guard isValidPosition(column: column, row: row) else { return nil }
        let index = row * numberOfColumns + column

        // Return explicit definition if set
        if let definition = tileDefinitions[index] {
            return definition
        }

        // Otherwise derive from group using position-based selection
        guard let group = tileGroups[index] else { return nil }
        let adjacency = calculateAdjacency(at: column, row: row)
        return group.tileDefinition(for: adjacency, atColumn: column, row: row)
    }

    /// Sets the tile group at the specified position.
    ///
    /// - Parameters:
    ///   - group: The tile group to set (nil to clear).
    ///   - column: The column index.
    ///   - row: The row index.
    public func setTileGroup(_ group: TileGroup?, forColumn column: Int, row: Int) {
        guard isValidPosition(column: column, row: row) else { return }
        let index = row * numberOfColumns + column
        tileGroups[index] = group
        tileDefinitions[index] = nil
    }

    /// Sets the tile group and definition at the specified position.
    ///
    /// - Parameters:
    ///   - group: The tile group.
    ///   - definition: The specific tile definition to use.
    ///   - column: The column index.
    ///   - row: The row index.
    public func setTileGroup(
        _ group: TileGroup?,
        andTileDefinition definition: TileDefinition?,
        forColumn column: Int,
        row: Int
    ) {
        guard isValidPosition(column: column, row: row) else { return }
        let index = row * numberOfColumns + column
        tileGroups[index] = group
        tileDefinitions[index] = definition
    }

    /// Fills the entire tile map with a tile group.
    ///
    /// - Parameter group: The tile group to fill with.
    public func fill(with group: TileGroup) {
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                setTileGroup(group, forColumn: column, row: row)
            }
        }
    }

    // MARK: - Coordinate Conversion

    /// Returns the column index for the given position.
    ///
    /// - Parameter position: The position in node coordinates.
    /// - Returns: The column index.
    public func tileColumnIndex(fromPosition position: Point) -> Int {
        let adjustedX = position.x + anchorPoint.x * mapSize.width
        return Int(adjustedX / tileSize.width)
    }

    /// Returns the row index for the given position.
    ///
    /// - Parameter position: The position in node coordinates.
    /// - Returns: The row index.
    public func tileRowIndex(fromPosition position: Point) -> Int {
        let adjustedY = position.y + anchorPoint.y * mapSize.height
        return Int(adjustedY / tileSize.height)
    }

    /// Returns the center position of a tile in node coordinates.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: The center point of the tile.
    public func centerOfTile(atColumn column: Int, row: Int) -> Point {
        let x = (CGFloat(column) + 0.5) * tileSize.width - anchorPoint.x * mapSize.width
        let y = (CGFloat(row) + 0.5) * tileSize.height - anchorPoint.y * mapSize.height
        return Point(x: x, y: y)
    }

    // MARK: - Collision

    /// Returns whether any collidable tile exists at the given position.
    ///
    /// - Parameter point: The point in node coordinates.
    /// - Returns: `true` if a collidable tile exists at this position.
    public func hasCollision(at point: Point) -> Bool {
        let column = tileColumnIndex(fromPosition: point)
        let row = tileRowIndex(fromPosition: point)
        return hasCollision(atColumn: column, row: row)
    }

    /// Returns whether any collidable tile exists at the given tile coordinate.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: `true` if a collidable tile exists at this position.
    public func hasCollision(atColumn column: Int, row: Int) -> Bool {
        guard let definition = tileDefinition(atColumn: column, row: row) else {
            return false
        }
        return definition.isCollidable
    }

    /// Returns all collidable tiles intersecting a rectangle.
    ///
    /// - Parameter rect: The rectangle in node coordinates.
    /// - Returns: An array of (column, row) tuples for collidable tiles.
    public func collidableTiles(in rect: Rect) -> [(column: Int, row: Int)] {
        var result: [(column: Int, row: Int)] = []

        let startCol = max(0, tileColumnIndex(fromPosition: Point(x: rect.minX, y: 0)))
        let endCol = min(numberOfColumns - 1, tileColumnIndex(fromPosition: Point(x: rect.maxX, y: 0)))
        let startRow = max(0, tileRowIndex(fromPosition: Point(x: 0, y: rect.minY)))
        let endRow = min(numberOfRows - 1, tileRowIndex(fromPosition: Point(x: 0, y: rect.maxY)))

        for row in startRow...endRow {
            for column in startCol...endCol {
                if hasCollision(atColumn: column, row: row) {
                    result.append((column, row))
                }
            }
        }

        return result
    }

    // MARK: - Adjacency Calculation

    /// Calculates the adjacency mask for a tile position.
    private func calculateAdjacency(at column: Int, row: Int) -> TileAdjacencyMask {
        var adjacency: TileAdjacencyMask = []
        let currentGroup = tileGroups[row * numberOfColumns + column]

        // Check all 8 directions
        let directions: [(dx: Int, dy: Int, mask: TileAdjacencyMask)] = [
            (0, 1, .adjacencyUp),
            (1, 1, .adjacencyUpRight),
            (1, 0, .adjacencyRight),
            (1, -1, .adjacencyDownRight),
            (0, -1, .adjacencyDown),
            (-1, -1, .adjacencyDownLeft),
            (-1, 0, .adjacencyLeft),
            (-1, 1, .adjacencyUpLeft)
        ]

        for (dx, dy, mask) in directions {
            let neighborCol = column + dx
            let neighborRow = row + dy

            if isValidPosition(column: neighborCol, row: neighborRow) {
                let neighborGroup = tileGroups[neighborRow * numberOfColumns + neighborCol]
                // Consider same group or any group as adjacent
                if neighborGroup != nil && neighborGroup === currentGroup {
                    adjacency.insert(mask)
                }
            }
        }

        return adjacency
    }

    // MARK: - Validation

    /// Checks if a position is valid.
    private func isValidPosition(column: Int, row: Int) -> Bool {
        column >= 0 && column < numberOfColumns && row >= 0 && row < numberOfRows
    }

    // MARK: - Draw Commands

    /// Generates draw commands for the visible tiles.
    ///
    /// - Parameters:
    ///   - visibleRect: The visible area in node coordinates.
    ///   - currentTime: The current time for animation.
    /// - Returns: An array of draw commands for visible tiles.
    internal func generateDrawCommands(visibleRect: Rect? = nil, currentTime: CGFloat = 0) -> [DrawCommand] {
        var commands: [DrawCommand] = []

        // Determine visible tile range
        let startCol: Int
        let endCol: Int
        let startRow: Int
        let endRow: Int

        if let rect = visibleRect {
            startCol = max(0, tileColumnIndex(fromPosition: Point(x: rect.minX, y: 0)))
            endCol = min(numberOfColumns - 1, tileColumnIndex(fromPosition: Point(x: rect.maxX, y: 0)))
            startRow = max(0, tileRowIndex(fromPosition: Point(x: 0, y: rect.minY)))
            endRow = min(numberOfRows - 1, tileRowIndex(fromPosition: Point(x: 0, y: rect.maxY)))
        } else {
            startCol = 0
            endCol = numberOfColumns - 1
            startRow = 0
            endRow = numberOfRows - 1
        }

        let worldPos = worldPosition
        let worldRot = worldRotation
        let worldScl = worldScale
        let baseAlpha = worldAlpha

        for row in startRow...endRow {
            for column in startCol...endCol {
                guard let definition = tileDefinition(atColumn: column, row: row) else {
                    continue
                }

                let tileCenter = centerOfTile(atColumn: column, row: row)
                let tileWorldPos = Point(
                    x: worldPos.x + tileCenter.x * worldScl.width,
                    y: worldPos.y + tileCenter.y * worldScl.height
                )

                // Calculate rotation including tile rotation
                let tileRotation = worldRot + definition.rotation.radians

                // Calculate scale with flip
                var tileScale = worldScl
                if definition.flipHorizontally {
                    tileScale.width *= -1
                }
                if definition.flipVertically {
                    tileScale.height *= -1
                }

                // Get texture (animated or static)
                let tileTexture = definition.texture(at: currentTime)
                let textureID = tileTexture?.textureID ?? .none

                // Apply color blending
                var finalColor = definition.color
                if colorBlendFactor > 0 {
                    finalColor = Color(
                        red: definition.color.red * (1 - colorBlendFactor) + color.red * colorBlendFactor,
                        green: definition.color.green * (1 - colorBlendFactor) + color.green * colorBlendFactor,
                        blue: definition.color.blue * (1 - colorBlendFactor) + color.blue * colorBlendFactor,
                        alpha: definition.color.alpha
                    )
                }

                let command = DrawCommand(
                    worldPosition: tileWorldPos,
                    worldRotation: tileRotation,
                    worldScale: tileScale,
                    size: definition.size,
                    anchorPoint: Point(x: 0.5, y: 0.5),
                    textureID: textureID,
                    textureRect: tileTexture?.textureRect() ?? Rect(x: 0, y: 0, width: 1, height: 1),
                    filteringMode: tileTexture?.filteringMode ?? .linear,
                    usesMipmaps: tileTexture?.usesMipmaps ?? false,
                    color: finalColor,
                    alpha: baseAlpha,
                    zPosition: zPosition
                )
                commands.append(command)
            }
        }

        return commands
    }

    // MARK: - Frame

    /// The bounding frame of this tile map.
    public override var frame: Rect {
        Rect(
            x: position.x - anchorPoint.x * mapSize.width,
            y: position.y - anchorPoint.y * mapSize.height,
            width: mapSize.width,
            height: mapSize.height
        )
    }
}
