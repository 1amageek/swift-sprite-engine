/// A grid-based warp geometry for mesh deformation.
///
/// `SNSNWarpGeometryGrid` divides a sprite into a grid of vertices that can
/// be individually displaced to create deformation effects like bending,
/// twisting, or wave animations.
///
/// ## Usage
/// ```swift
/// // Create a 4x4 grid (25 vertices)
/// var warp = SNSNWarpGeometryGrid(columns: 4, rows: 4)
///
/// // Deform the top-right corner
/// warp.setDestinationPosition(Point(x: 1.1, y: 1.1), at: 24)
///
/// // Apply to a sprite
/// sprite.warpGeometry = warp
/// sprite.subdivisionLevels = 2  // Smooth the deformation
/// ```
///
/// ## Grid Layout
/// Vertices are arranged in row-major order:
/// ```
/// Row 4: [20][21][22][23][24]
/// Row 3: [15][16][17][18][19]
/// Row 2: [10][11][12][13][14]
/// Row 1: [ 5][ 6][ 7][ 8][ 9]
/// Row 0: [ 0][ 1][ 2][ 3][ 4]
/// ```
public final class SNSNWarpGeometryGrid: SNWarpGeometry {
    /// The number of columns in the grid.
    public let columns: Int

    /// The number of rows in the grid.
    public let rows: Int

    /// The source positions of vertices (normalized 0-1 coordinates).
    private var sourcePositions: [Point]

    /// The destination positions of vertices (can exceed 0-1 for deformation).
    private var destinationPositions: [Point]

    /// The total number of vertices in the grid.
    public override var vertexCount: Int {
        (columns + 1) * (rows + 1)
    }

    // MARK: - Initialization

    /// Creates a warp geometry grid with the specified dimensions.
    ///
    /// The grid is initialized with source positions in a regular grid
    /// pattern and destination positions matching the source positions.
    ///
    /// - Parameters:
    ///   - columns: The number of columns (horizontal divisions).
    ///   - rows: The number of rows (vertical divisions).
    public init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)

        let vertexCols = self.columns + 1
        let vertexRows = self.rows + 1
        let count = vertexCols * vertexRows

        self.sourcePositions = []
        self.destinationPositions = []
        self.sourcePositions.reserveCapacity(count)
        self.destinationPositions.reserveCapacity(count)

        // Initialize with regular grid positions
        for row in 0..<vertexRows {
            for col in 0..<vertexCols {
                let x = Float(col) / Float(self.columns)
                let y = Float(row) / Float(self.rows)
                let point = Point(x: x, y: y)
                self.sourcePositions.append(point)
                self.destinationPositions.append(point)
            }
        }

        super.init()
    }

    /// Creates a warp geometry grid with custom positions.
    ///
    /// - Parameters:
    ///   - columns: The number of columns.
    ///   - rows: The number of rows.
    ///   - sourcePositions: The source vertex positions.
    ///   - destinationPositions: The destination vertex positions.
    public init(
        columns: Int,
        rows: Int,
        sourcePositions: [Point],
        destinationPositions: [Point]
    ) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)

        let expectedCount = (self.columns + 1) * (self.rows + 1)

        // Validate and copy positions
        if sourcePositions.count == expectedCount {
            self.sourcePositions = sourcePositions
        } else {
            self.sourcePositions = SNSNWarpGeometryGrid.createDefaultPositions(
                columns: self.columns,
                rows: self.rows
            )
        }

        if destinationPositions.count == expectedCount {
            self.destinationPositions = destinationPositions
        } else {
            self.destinationPositions = self.sourcePositions
        }

        super.init()
    }

    // MARK: - Position Access

    /// Returns the source position for a vertex at the given index.
    ///
    /// - Parameter index: The vertex index.
    /// - Returns: The source position, or (0, 0) if index is out of bounds.
    public override func sourcePosition(at index: Int) -> Point {
        guard index >= 0 && index < sourcePositions.count else {
            return Point(x: 0, y: 0)
        }
        return sourcePositions[index]
    }

    /// Returns the destination position for a vertex at the given index.
    ///
    /// - Parameter index: The vertex index.
    /// - Returns: The destination position, or (0, 0) if index is out of bounds.
    public override func destinationPosition(at index: Int) -> Point {
        guard index >= 0 && index < destinationPositions.count else {
            return Point(x: 0, y: 0)
        }
        return destinationPositions[index]
    }

    /// Sets the destination position for a vertex.
    ///
    /// - Parameters:
    ///   - position: The new destination position.
    ///   - index: The vertex index.
    public func setDestinationPosition(_ position: Point, at index: Int) {
        guard index >= 0 && index < destinationPositions.count else { return }
        destinationPositions[index] = position
    }

    /// Returns the vertex index for a given column and row.
    ///
    /// - Parameters:
    ///   - column: The column index (0 to columns).
    ///   - row: The row index (0 to rows).
    /// - Returns: The vertex index, or nil if out of bounds.
    public func vertexIndex(atColumn column: Int, row: Int) -> Int? {
        guard column >= 0 && column <= columns && row >= 0 && row <= rows else {
            return nil
        }
        return row * (columns + 1) + column
    }

    /// Returns the source position at a specific grid location.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: The source position, or nil if out of bounds.
    public func sourcePosition(atColumn column: Int, row: Int) -> Point? {
        guard let index = vertexIndex(atColumn: column, row: row) else {
            return nil
        }
        return sourcePositions[index]
    }

    /// Returns the destination position at a specific grid location.
    ///
    /// - Parameters:
    ///   - column: The column index.
    ///   - row: The row index.
    /// - Returns: The destination position, or nil if out of bounds.
    public func destinationPosition(atColumn column: Int, row: Int) -> Point? {
        guard let index = vertexIndex(atColumn: column, row: row) else {
            return nil
        }
        return destinationPositions[index]
    }

    /// Sets the destination position at a specific grid location.
    ///
    /// - Parameters:
    ///   - position: The new destination position.
    ///   - column: The column index.
    ///   - row: The row index.
    public func setDestinationPosition(_ position: Point, atColumn column: Int, row: Int) {
        guard let index = vertexIndex(atColumn: column, row: row) else { return }
        destinationPositions[index] = position
    }

    // MARK: - Bulk Access

    /// Returns all source positions.
    public var allSourcePositions: [Point] {
        sourcePositions
    }

    /// Returns all destination positions.
    public var allDestinationPositions: [Point] {
        destinationPositions
    }

    /// Replaces all destination positions.
    ///
    /// - Parameter positions: The new destination positions. Must match vertex count.
    public func setAllDestinationPositions(_ positions: [Point]) {
        guard positions.count == vertexCount else { return }
        destinationPositions = positions
    }

    /// Resets all destination positions to match source positions.
    public func resetDestinations() {
        destinationPositions = sourcePositions
    }

    // MARK: - Interpolation

    /// Creates a new warp geometry by interpolating between two geometries.
    ///
    /// - Parameters:
    ///   - from: The starting geometry.
    ///   - to: The ending geometry.
    ///   - progress: The interpolation factor (0 = from, 1 = to).
    /// - Returns: A new interpolated warp geometry, or nil if geometries are incompatible.
    public static func interpolate(
        from: SNSNWarpGeometryGrid,
        to: SNSNWarpGeometryGrid,
        progress: Float
    ) -> SNSNWarpGeometryGrid? {
        guard from.columns == to.columns && from.rows == to.rows else {
            return nil
        }

        let t = max(0, min(1, progress))
        var newDestinations: [Point] = []
        newDestinations.reserveCapacity(from.vertexCount)

        for i in 0..<from.vertexCount {
            let fromPos = from.destinationPosition(at: i)
            let toPos = to.destinationPosition(at: i)
            let interpolated = Point(
                x: fromPos.x + (toPos.x - fromPos.x) * t,
                y: fromPos.y + (toPos.y - fromPos.y) * t
            )
            newDestinations.append(interpolated)
        }

        return SNSNWarpGeometryGrid(
            columns: from.columns,
            rows: from.rows,
            sourcePositions: from.sourcePositions,
            destinationPositions: newDestinations
        )
    }

    // MARK: - Copy

    /// Creates a copy of this warp geometry grid.
    ///
    /// - Returns: A new warp geometry grid with the same configuration.
    public override func copy() -> SNWarpGeometry {
        SNSNWarpGeometryGrid(
            columns: columns,
            rows: rows,
            sourcePositions: sourcePositions,
            destinationPositions: destinationPositions
        )
    }

    // MARK: - Helpers

    private static func createDefaultPositions(columns: Int, rows: Int) -> [Point] {
        let vertexCols = columns + 1
        let vertexRows = rows + 1
        var positions: [Point] = []
        positions.reserveCapacity(vertexCols * vertexRows)

        for row in 0..<vertexRows {
            for col in 0..<vertexCols {
                let x = Float(col) / Float(columns)
                let y = Float(row) / Float(rows)
                positions.append(Point(x: x, y: y))
            }
        }

        return positions
    }
}

// MARK: - Preset Warps

extension SNSNWarpGeometryGrid {
    /// Creates a wave deformation effect.
    ///
    /// - Parameters:
    ///   - columns: The number of columns.
    ///   - rows: The number of rows.
    ///   - amplitude: The wave amplitude (0-1).
    ///   - frequency: The wave frequency.
    ///   - phase: The wave phase offset.
    ///   - horizontal: Whether the wave is horizontal (true) or vertical (false).
    /// - Returns: A warp geometry grid with wave deformation.
    public static func wave(
        columns: Int,
        rows: Int,
        amplitude: Float,
        frequency: Float,
        phase: Float = 0,
        horizontal: Bool = true
    ) -> SNSNWarpGeometryGrid {
        let grid = SNSNWarpGeometryGrid(columns: columns, rows: rows)

        for row in 0...(rows) {
            for col in 0...(columns) {
                guard let index = grid.vertexIndex(atColumn: col, row: row) else { continue }
                let source = grid.sourcePosition(at: index)

                let offset: Float
                if horizontal {
                    offset = sin(source.y * frequency * .pi * 2 + phase) * amplitude
                    grid.setDestinationPosition(
                        Point(x: source.x + offset, y: source.y),
                        at: index
                    )
                } else {
                    offset = sin(source.x * frequency * .pi * 2 + phase) * amplitude
                    grid.setDestinationPosition(
                        Point(x: source.x, y: source.y + offset),
                        at: index
                    )
                }
            }
        }

        return grid
    }

    /// Creates a bulge/pinch deformation effect.
    ///
    /// - Parameters:
    ///   - columns: The number of columns.
    ///   - rows: The number of rows.
    ///   - center: The center of the effect (normalized 0-1).
    ///   - radius: The radius of the effect (normalized).
    ///   - strength: Positive for bulge, negative for pinch.
    /// - Returns: A warp geometry grid with bulge/pinch deformation.
    public static func bulge(
        columns: Int,
        rows: Int,
        center: Point = Point(x: 0.5, y: 0.5),
        radius: Float = 0.5,
        strength: Float = 0.3
    ) -> SNSNWarpGeometryGrid {
        let grid = SNSNWarpGeometryGrid(columns: columns, rows: rows)

        for row in 0...(rows) {
            for col in 0...(columns) {
                guard let index = grid.vertexIndex(atColumn: col, row: row) else { continue }
                let source = grid.sourcePosition(at: index)

                let dx = source.x - center.x
                let dy = source.y - center.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance < radius && distance > 0 {
                    let factor: Float = 1.0 - (distance / radius)
                    let bulgeAmount: Float = factor * factor * strength
                    let scale: Float = 1.0 + bulgeAmount

                    let newX = center.x + dx * scale
                    let newY = center.y + dy * scale
                    grid.setDestinationPosition(Point(x: newX, y: newY), at: index)
                }
            }
        }

        return grid
    }

    /// Creates a twist/swirl deformation effect.
    ///
    /// - Parameters:
    ///   - columns: The number of columns.
    ///   - rows: The number of rows.
    ///   - center: The center of the twist.
    ///   - radius: The radius of the effect.
    ///   - angle: The maximum rotation angle in radians.
    /// - Returns: A warp geometry grid with twist deformation.
    public static func twist(
        columns: Int,
        rows: Int,
        center: Point = Point(x: 0.5, y: 0.5),
        radius: Float = 0.5,
        angle: Float = Float.pi / 4
    ) -> SNSNWarpGeometryGrid {
        let grid = SNSNWarpGeometryGrid(columns: columns, rows: rows)

        for row in 0...(rows) {
            for col in 0...(columns) {
                guard let index = grid.vertexIndex(atColumn: col, row: row) else { continue }
                let source = grid.sourcePosition(at: index)

                let dx = source.x - center.x
                let dy = source.y - center.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance < radius {
                    let factor: Float = 1.0 - (distance / radius)
                    let rotation: Float = factor * factor * angle

                    let cosR = cos(rotation)
                    let sinR = sin(rotation)

                    let newX = center.x + dx * cosR - dy * sinR
                    let newY = center.y + dx * sinR + dy * cosR
                    grid.setDestinationPosition(Point(x: newX, y: newY), at: index)
                }
            }
        }

        return grid
    }
}
