/// An enumeration defining how tiles are arranged in a tile map.
public enum TileSetType: Int, Sendable {
    /// Standard rectangular grid layout.
    case grid = 0

    /// Hexagonal grid with flat-topped hexagons.
    /// Columns are offset every other row.
    case hexagonalFlat = 1

    /// Hexagonal grid with pointy-topped hexagons.
    /// Rows are offset every other column.
    case hexagonalPointy = 2

    /// Isometric (diamond-shaped) grid layout.
    /// Used for 2.5D perspective games.
    case isometric = 3
}
