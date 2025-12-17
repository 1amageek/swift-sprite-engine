/// A definition for a single tile type.
///
/// `TileDefinition` describes how a tile looks and behaves.
/// It supports single textures, animated textures, rotation, and flipping.
///
/// ## Usage
/// ```swift
/// // Simple colored tile
/// let groundTile = TileDefinition(color: .brown)
///
/// // Textured tile
/// let grassTile = TileDefinition(texture: Texture(imageNamed: "grass.png"), size: Size(width: 16, height: 16))
///
/// // Animated tile
/// let waterTile = TileDefinition(
///     textures: [
///         Texture(imageNamed: "water1.png"),
///         Texture(imageNamed: "water2.png"),
///         Texture(imageNamed: "water3.png")
///     ],
///     size: Size(width: 16, height: 16),
///     timePerFrame: 0.2
/// )
/// ```
public final class TileDefinition {
    /// An optional name for identifying this tile definition.
    public var name: String?

    /// The size of the tile in points.
    public var size: Size

    /// The color of this tile (used when not using a texture or for tinting).
    public var color: Color

    /// The textures for this tile (for animation, use multiple).
    public var textures: [SNTexture]

    /// The duration each texture frame is displayed (for animated tiles).
    public var timePerFrame: CGFloat

    /// The rotation of the tile in 90° increments.
    public var rotation: TileRotation

    /// Whether to flip the tile horizontally.
    public var flipHorizontally: Bool

    /// Whether to flip the tile vertically.
    public var flipVertically: Bool

    /// Whether this tile blocks physics bodies.
    public var isCollidable: Bool

    /// The placement weight for random selection among multiple definitions.
    /// Higher weights increase the probability of selection.
    public var placementWeight: Int

    /// Custom user data associated with this tile.
    public var userData: [String: String]

    /// The current texture (first texture or animated frame).
    public var texture: SNTexture? {
        textures.first
    }

    /// Whether this tile is animated.
    public var isAnimated: Bool {
        textures.count > 1 && timePerFrame > 0
    }

    /// Creates a tile definition with a single texture.
    ///
    /// - Parameters:
    ///   - texture: The texture to display.
    ///   - size: The size of the tile (defaults to 16x16).
    public init(texture: SNTexture, size: Size = Size(width: 16, height: 16)) {
        self.name = nil
        self.size = size
        self.color = .white
        self.textures = [texture]
        self.timePerFrame = 0
        self.rotation = .rotation0
        self.flipHorizontally = false
        self.flipVertically = false
        self.isCollidable = false
        self.placementWeight = 1
        self.userData = [:]
    }

    /// Creates a tile definition with multiple textures for animation.
    ///
    /// - Parameters:
    ///   - textures: The textures for animation frames.
    ///   - size: The size of the tile.
    ///   - timePerFrame: The duration of each frame in seconds.
    public init(textures: [SNTexture], size: Size, timePerFrame: CGFloat) {
        self.name = nil
        self.size = size
        self.color = .white
        self.textures = textures
        self.timePerFrame = timePerFrame
        self.rotation = .rotation0
        self.flipHorizontally = false
        self.flipVertically = false
        self.isCollidable = false
        self.placementWeight = 1
        self.userData = [:]
    }

    /// Creates a colored tile definition (no texture).
    ///
    /// - Parameters:
    ///   - color: The tile color.
    ///   - size: The size of the tile (defaults to 16x16).
    public init(color: Color, size: Size = Size(width: 16, height: 16)) {
        self.name = nil
        self.size = size
        self.color = color
        self.textures = []
        self.timePerFrame = 0
        self.rotation = .rotation0
        self.flipHorizontally = false
        self.flipVertically = false
        self.isCollidable = false
        self.placementWeight = 1
        self.userData = [:]
    }

    /// Returns the texture for a given time (for animated tiles).
    ///
    /// - Parameter time: The elapsed time in seconds.
    /// - Returns: The texture for the current frame.
    public func texture(at time: CGFloat) -> SNTexture? {
        guard !textures.isEmpty else { return nil }
        guard isAnimated else { return textures.first }

        let totalDuration = timePerFrame * CGFloat(textures.count)
        let normalizedTime = time.truncatingRemainder(dividingBy: totalDuration)
        let frameIndex = Int(normalizedTime / timePerFrame) % textures.count
        return textures[frameIndex]
    }
}

/// A container for related tile groups.
///
/// `TileSet` holds tile groups that define the available tiles for a tile map.
/// It also specifies the grid layout type (rectangular, hexagonal, or isometric).
///
/// ## Usage
/// ```swift
/// let tileSet = TileSet(tileGroups: [groundGroup, waterGroup, wallGroup])
/// tileSet.defaultTileSize = Size(width: 16, height: 16)
/// tileSet.type = .grid
///
/// let tileMap = TileMap(tileSet: tileSet, columns: 20, rows: 15)
/// ```
public final class TileSet {
    /// An optional name for this tile set.
    public var name: String?

    /// The tile set's array of tile group objects.
    public var tileGroups: [TileGroup]

    /// The tile set's default tile size.
    public var defaultTileSize: Size

    /// The tile set's default tile group (used for fill operations).
    public var defaultTileGroup: TileGroup?

    /// The layout type of this tile set.
    public var type: TileSetType

    /// Creates a tile set with tile groups and rectangular grid layout.
    ///
    /// - Parameter tileGroups: The tile groups to include.
    public init(tileGroups: [TileGroup]) {
        self.name = nil
        self.tileGroups = tileGroups
        self.defaultTileSize = Size(width: 16, height: 16)
        self.defaultTileGroup = tileGroups.first
        self.type = .grid
    }

    /// Creates a tile set with tile groups and specified layout type.
    ///
    /// - Parameters:
    ///   - tileGroups: The tile groups to include.
    ///   - type: The layout type.
    public init(tileGroups: [TileGroup], type: TileSetType) {
        self.name = nil
        self.tileGroups = tileGroups
        self.defaultTileSize = Size(width: 16, height: 16)
        self.defaultTileGroup = tileGroups.first
        self.type = type
    }

    /// Creates an empty tile set with a default tile size.
    ///
    /// - Parameter tileSize: The default size of tiles.
    public init(tileSize: Size) {
        self.name = nil
        self.tileGroups = []
        self.defaultTileSize = tileSize
        self.defaultTileGroup = nil
        self.type = .grid
    }

    /// Adds a tile group to the set.
    ///
    /// - Parameter group: The tile group to add.
    public func addTileGroup(_ group: TileGroup) {
        tileGroups.append(group)
        if defaultTileGroup == nil {
            defaultTileGroup = group
        }
    }

    /// Returns the tile group with the specified name.
    ///
    /// - Parameter name: The group name.
    /// - Returns: The tile group, or `nil` if not found.
    public func tileGroup(named name: String) -> TileGroup? {
        tileGroups.first { $0.name == name }
    }

    /// Removes all tile groups.
    public func removeAllTileGroups() {
        tileGroups.removeAll()
        defaultTileGroup = nil
    }
}
