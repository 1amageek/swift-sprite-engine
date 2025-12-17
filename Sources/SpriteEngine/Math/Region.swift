/// The definition of an arbitrary area.
///
/// `Region` defines a mathematical shape used to determine whether a particular
/// point lies inside the area. Regions are used to define areas that physics
/// fields affect, hit testing, and constructive solid geometry.
///
/// ## Usage
/// ```swift
/// // Create a rectangular region
/// let rect = Region(size: Size(width: 100, height: 100))
///
/// // Create a circular region
/// let circle = Region(radius: 50)
///
/// // Create from a path
/// let custom = Region(path: myPath)
///
/// // Check if point is inside
/// if region.contains(Point(x: 25, y: 25)) {
///     // Point is inside the region
/// }
///
/// // Combine regions
/// let combined = region1.union(with: region2)
/// let intersection = region1.intersection(with: region2)
/// let difference = region1.difference(from: region2)
/// ```
public struct Region: Sendable {
    // MARK: - Shape Type

    private indirect enum Shape: Sendable {
        case infinite
        case rect(Size)
        case circle(CGFloat)
        case path(ShapePath)
        case combined(Region, Region, Operation)
        case inverted(Region)
    }

    private enum Operation: Sendable {
        case union
        case intersection
        case difference
    }

    // MARK: - Properties

    private let shape: Shape

    /// The approximate size of the region.
    ///
    /// For circular regions, returns the diameter.
    /// For rectangular regions, returns the width.
    /// For other regions, returns 0.
    public var size: CGFloat {
        switch shape {
        case .infinite:
            return CGFloat.infinity
        case .rect(let s):
            return max(s.width, s.height)
        case .circle(let radius):
            return radius * 2
        case .path, .combined, .inverted:
            return 0
        }
    }

    /// The path that defines the region, if available.
    public var path: ShapePath? {
        switch shape {
        case .rect(let size):
            var p = ShapePath()
            p.addRect(Rect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ))
            return p
        case .circle(let radius):
            var p = ShapePath()
            p.addEllipse(in: Rect(
                x: -radius,
                y: -radius,
                width: radius * 2,
                height: radius * 2
            ))
            return p
        case .path(let shapePath):
            return shapePath
        case .infinite, .combined, .inverted:
            return nil
        }
    }

    // MARK: - Initialization

    private init(shape: Shape) {
        self.shape = shape
    }

    /// Creates an infinite region that includes all points.
    public static func infinite() -> Region {
        Region(shape: .infinite)
    }

    /// Creates a rectangular region centered at the origin.
    ///
    /// - Parameter size: The size of the rectangle.
    public init(size: Size) {
        self.shape = .rect(size)
    }

    /// Creates a circular region centered at the origin.
    ///
    /// - Parameter radius: The radius of the circle.
    public init(radius: CGFloat) {
        self.shape = .circle(radius)
    }

    /// Creates a region from a path.
    ///
    /// - Parameter path: The path defining the region.
    public init(path: ShapePath) {
        self.shape = .path(path)
    }

    // MARK: - Containment

    /// Returns whether a point is contained in the region.
    ///
    /// - Parameter point: The point to check.
    /// - Returns: `true` if the point is inside the region.
    public func contains(_ point: Point) -> Bool {
        switch shape {
        case .infinite:
            return true

        case .rect(let size):
            return point.x >= -size.width / 2 && point.x <= size.width / 2 &&
                   point.y >= -size.height / 2 && point.y <= size.height / 2

        case .circle(let radius):
            return point.x * point.x + point.y * point.y <= radius * radius

        case .path(let shapePath):
            return containsPointInPath(point, path: shapePath)

        case .combined(let a, let b, let operation):
            switch operation {
            case .union:
                return a.contains(point) || b.contains(point)
            case .intersection:
                return a.contains(point) && b.contains(point)
            case .difference:
                return a.contains(point) && !b.contains(point)
            }

        case .inverted(let region):
            return !region.contains(point)
        }
    }

    // MARK: - Constructive Solid Geometry

    /// Returns the inverse of this region.
    ///
    /// Points inside the original region will be outside the inverse, and vice versa.
    public func inverse() -> Region {
        Region(shape: .inverted(self))
    }

    /// Returns a new region created by combining this region with another.
    ///
    /// - Parameter other: The region to combine with.
    /// - Returns: A region containing all points in either region.
    public func union(with other: Region) -> Region {
        Region(shape: .combined(self, other, .union))
    }

    /// Returns a new region created by intersecting this region with another.
    ///
    /// - Parameter other: The region to intersect with.
    /// - Returns: A region containing only points in both regions.
    public func intersection(with other: Region) -> Region {
        Region(shape: .combined(self, other, .intersection))
    }

    /// Returns a new region created by subtracting another region from this region.
    ///
    /// - Parameter other: The region to subtract.
    /// - Returns: A region containing points in this region but not in the other.
    public func difference(from other: Region) -> Region {
        Region(shape: .combined(self, other, .difference))
    }

    // MARK: - Point in Path Test

    /// Tests if a point is inside a path using the ray casting algorithm.
    private func containsPointInPath(_ point: Point, path: ShapePath) -> Bool {
        let elements = path.elements
        guard !elements.isEmpty else { return false }

        var crossings = 0
        var currentPoint = Point.zero
        var startPoint = Point.zero

        for element in elements {
            switch element {
            case .moveTo(let p):
                currentPoint = p
                startPoint = p

            case .lineTo(let p):
                if lineIntersectsRay(from: currentPoint, to: p, rayOrigin: point) {
                    crossings += 1
                }
                currentPoint = p

            case .quadCurveTo(_, let end):
                // Approximate with line for simplicity
                if lineIntersectsRay(from: currentPoint, to: end, rayOrigin: point) {
                    crossings += 1
                }
                currentPoint = end

            case .curveTo(_, _, let end):
                // Approximate with line for simplicity
                if lineIntersectsRay(from: currentPoint, to: end, rayOrigin: point) {
                    crossings += 1
                }
                currentPoint = end

            case .closeSubpath:
                if lineIntersectsRay(from: currentPoint, to: startPoint, rayOrigin: point) {
                    crossings += 1
                }
                currentPoint = startPoint
            }
        }

        // Odd number of crossings means inside
        return crossings % 2 == 1
    }

    /// Tests if a line segment intersects a horizontal ray from a point.
    private func lineIntersectsRay(from p1: Point, to p2: Point, rayOrigin: Point) -> Bool {
        // Ray goes from rayOrigin to positive X infinity
        let minY = min(p1.y, p2.y)
        let maxY = max(p1.y, p2.y)

        // Check if ray's Y is within line segment's Y range
        guard rayOrigin.y > minY && rayOrigin.y <= maxY else { return false }

        // Calculate X intersection
        let t = (rayOrigin.y - p1.y) / (p2.y - p1.y)
        let xIntersect = p1.x + t * (p2.x - p1.x)

        // Check if intersection is to the right of ray origin
        return xIntersect > rayOrigin.x
    }
}

// MARK: - Factory Methods

extension Region {
    /// Creates a rectangular region.
    ///
    /// - Parameter rect: The rectangle.
    /// - Returns: A region covering the rectangle.
    public static func rectangle(_ rect: Rect) -> Region {
        let path = ShapePath(elements: [
            .moveTo(rect.bottomLeft),
            .lineTo(rect.bottomRight),
            .lineTo(rect.topRight),
            .lineTo(rect.topLeft),
            .closeSubpath
        ])
        return Region(path: path)
    }

    /// Creates an elliptical region.
    ///
    /// - Parameter rect: The bounding rectangle of the ellipse.
    /// - Returns: A region covering the ellipse.
    public static func ellipse(in rect: Rect) -> Region {
        var path = ShapePath()
        path.addEllipse(in: rect)
        return Region(path: path)
    }
}
