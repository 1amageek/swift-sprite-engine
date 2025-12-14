/// A geometric path composed of lines, curves, and other segments.
///
/// `ShapePath` represents a sequence of drawing commands that define a shape.
/// It supports lines, quadratic curves, cubic curves, arcs, and more.
///
/// Note: Named `ShapePath` to avoid collision with SwiftUI's `Path` type.
///
/// ## Usage
/// ```swift
/// var path = ShapePath()
/// path.move(to: Point(x: 0, y: 0))
/// path.addLine(to: Point(x: 100, y: 0))
/// path.addLine(to: Point(x: 100, y: 100))
/// path.close()
/// ```
public struct ShapePath: Sendable {
    // MARK: - Elements

    /// The elements that make up this path.
    public private(set) var elements: [PathElement] = []

    /// The current point of the path.
    public private(set) var currentPoint: Point = .zero

    // MARK: - Initialization

    /// Creates an empty path.
    public init() {}

    /// Creates a shape path from an array of elements.
    ///
    /// - Parameter elements: The path elements.
    public init(elements: [PathElement]) {
        self.elements = elements
        // Update current point based on last element
        if let last = elements.last {
            switch last {
            case .moveTo(let point), .lineTo(let point):
                currentPoint = point
            case .quadCurveTo(_, let end):
                currentPoint = end
            case .curveTo(_, _, let end):
                currentPoint = end
            case .closeSubpath:
                // Find the last moveTo
                for element in elements.reversed() {
                    if case .moveTo(let point) = element {
                        currentPoint = point
                        break
                    }
                }
            }
        }
    }

    // MARK: - Path Building

    /// Moves the current point to the specified location.
    ///
    /// - Parameter point: The new current point.
    public mutating func move(to point: Point) {
        elements.append(.moveTo(point))
        currentPoint = point
    }

    /// Adds a straight line from the current point to the specified point.
    ///
    /// - Parameter point: The end point of the line.
    public mutating func addLine(to point: Point) {
        elements.append(.lineTo(point))
        currentPoint = point
    }

    /// Adds a quadratic Bezier curve from the current point.
    ///
    /// - Parameters:
    ///   - control: The control point of the curve.
    ///   - end: The end point of the curve.
    public mutating func addQuadCurve(to end: Point, control: Point) {
        elements.append(.quadCurveTo(control, end))
        currentPoint = end
    }

    /// Adds a cubic Bezier curve from the current point.
    ///
    /// - Parameters:
    ///   - control1: The first control point.
    ///   - control2: The second control point.
    ///   - end: The end point of the curve.
    public mutating func addCurve(to end: Point, control1: Point, control2: Point) {
        elements.append(.curveTo(control1, control2, end))
        currentPoint = end
    }

    /// Closes the current subpath by connecting to the starting point.
    public mutating func close() {
        elements.append(.closeSubpath)
        // Find the last moveTo point
        for element in elements.reversed() {
            if case .moveTo(let point) = element {
                currentPoint = point
                break
            }
        }
    }

    // MARK: - Shape Helpers

    /// Adds a rectangle to the path.
    ///
    /// - Parameter rect: The rectangle to add.
    public mutating func addRect(_ rect: Rect) {
        move(to: Point(x: rect.minX, y: rect.minY))
        addLine(to: Point(x: rect.maxX, y: rect.minY))
        addLine(to: Point(x: rect.maxX, y: rect.maxY))
        addLine(to: Point(x: rect.minX, y: rect.maxY))
        close()
    }

    /// Adds a rounded rectangle to the path.
    ///
    /// - Parameters:
    ///   - rect: The rectangle to add.
    ///   - cornerRadius: The radius of the corners.
    public mutating func addRoundedRect(_ rect: Rect, cornerRadius: Float) {
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)

        move(to: Point(x: rect.minX + r, y: rect.minY))

        // Bottom edge and bottom-right corner
        addLine(to: Point(x: rect.maxX - r, y: rect.minY))
        addQuadCurve(
            to: Point(x: rect.maxX, y: rect.minY + r),
            control: Point(x: rect.maxX, y: rect.minY)
        )

        // Right edge and top-right corner
        addLine(to: Point(x: rect.maxX, y: rect.maxY - r))
        addQuadCurve(
            to: Point(x: rect.maxX - r, y: rect.maxY),
            control: Point(x: rect.maxX, y: rect.maxY)
        )

        // Top edge and top-left corner
        addLine(to: Point(x: rect.minX + r, y: rect.maxY))
        addQuadCurve(
            to: Point(x: rect.minX, y: rect.maxY - r),
            control: Point(x: rect.minX, y: rect.maxY)
        )

        // Left edge and bottom-left corner
        addLine(to: Point(x: rect.minX, y: rect.minY + r))
        addQuadCurve(
            to: Point(x: rect.minX + r, y: rect.minY),
            control: Point(x: rect.minX, y: rect.minY)
        )

        close()
    }

    /// Adds an ellipse inscribed in the specified rectangle.
    ///
    /// - Parameter rect: The bounding rectangle of the ellipse.
    public mutating func addEllipse(in rect: Rect) {
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2

        // Approximate ellipse with 4 cubic Bezier curves
        // Magic number for cubic Bezier approximation of circle
        let k: Float = 0.5522847498

        move(to: Point(x: cx + rx, y: cy))

        // Right to top
        addCurve(
            to: Point(x: cx, y: cy + ry),
            control1: Point(x: cx + rx, y: cy + ry * k),
            control2: Point(x: cx + rx * k, y: cy + ry)
        )

        // Top to left
        addCurve(
            to: Point(x: cx - rx, y: cy),
            control1: Point(x: cx - rx * k, y: cy + ry),
            control2: Point(x: cx - rx, y: cy + ry * k)
        )

        // Left to bottom
        addCurve(
            to: Point(x: cx, y: cy - ry),
            control1: Point(x: cx - rx, y: cy - ry * k),
            control2: Point(x: cx - rx * k, y: cy - ry)
        )

        // Bottom to right
        addCurve(
            to: Point(x: cx + rx, y: cy),
            control1: Point(x: cx + rx * k, y: cy - ry),
            control2: Point(x: cx + rx, y: cy - ry * k)
        )

        close()
    }

    /// Adds an arc to the path.
    ///
    /// - Parameters:
    ///   - center: The center of the arc.
    ///   - radius: The radius of the arc.
    ///   - startAngle: The starting angle in radians.
    ///   - endAngle: The ending angle in radians.
    ///   - clockwise: Whether to draw clockwise.
    public mutating func addArc(
        center: Point,
        radius: Float,
        startAngle: Float,
        endAngle: Float,
        clockwise: Bool
    ) {
        let startX = center.x + cos(startAngle) * radius
        let startY = center.y + sin(startAngle) * radius

        if elements.isEmpty {
            move(to: Point(x: startX, y: startY))
        } else {
            addLine(to: Point(x: startX, y: startY))
        }

        // Approximate arc with cubic Bezier curves
        var angle = startAngle
        let endAngleNormalized = clockwise ?
            (endAngle < startAngle ? endAngle : endAngle - 2 * .pi) :
            (endAngle > startAngle ? endAngle : endAngle + 2 * .pi)

        let step: Float = clockwise ? -.pi / 2 : .pi / 2
        let direction: Float = clockwise ? -1 : 1

        while (clockwise && angle > endAngleNormalized) || (!clockwise && angle < endAngleNormalized) {
            var nextAngle = angle + step
            if (clockwise && nextAngle < endAngleNormalized) || (!clockwise && nextAngle > endAngleNormalized) {
                nextAngle = endAngleNormalized
            }

            let arcAngle = nextAngle - angle
            let k = 4.0 / 3.0 * tan(arcAngle / 4)

            let x0 = center.x + cos(angle) * radius
            let y0 = center.y + sin(angle) * radius
            let x3 = center.x + cos(nextAngle) * radius
            let y3 = center.y + sin(nextAngle) * radius

            let x1 = x0 - k * sin(angle) * radius * direction
            let y1 = y0 + k * cos(angle) * radius * direction
            let x2 = x3 + k * sin(nextAngle) * radius * direction
            let y2 = y3 - k * cos(nextAngle) * radius * direction

            addCurve(
                to: Point(x: x3, y: y3),
                control1: Point(x: x1, y: y1),
                control2: Point(x: x2, y: y2)
            )

            angle = nextAngle
        }
    }

    // MARK: - Properties

    /// Whether the path is empty.
    public var isEmpty: Bool {
        elements.isEmpty
    }

    /// The bounding rectangle of the path.
    public var boundingRect: Rect {
        guard !elements.isEmpty else {
            return .zero
        }

        var minX: Float = .greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude

        for element in elements {
            switch element {
            case .moveTo(let point), .lineTo(let point):
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)

            case .quadCurveTo(let control, let end):
                // Approximate bounds by including control point
                minX = min(minX, min(control.x, end.x))
                minY = min(minY, min(control.y, end.y))
                maxX = max(maxX, max(control.x, end.x))
                maxY = max(maxY, max(control.y, end.y))

            case .curveTo(let control1, let control2, let end):
                // Approximate bounds by including control points
                minX = min(minX, min(control1.x, min(control2.x, end.x)))
                minY = min(minY, min(control1.y, min(control2.y, end.y)))
                maxX = max(maxX, max(control1.x, max(control2.x, end.x)))
                maxY = max(maxY, max(control1.y, max(control2.y, end.y)))

            case .closeSubpath:
                break
            }
        }

        if minX == .greatestFiniteMagnitude {
            return .zero
        }

        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Transformations

    /// Returns a new path with the specified transform applied.
    ///
    /// - Parameter transform: The transform to apply.
    /// - Returns: A transformed copy of the path.
    public func applying(_ transform: AffineTransform) -> ShapePath {
        var newPath = ShapePath()

        for element in elements {
            switch element {
            case .moveTo(let point):
                newPath.move(to: transform.transform(point))
            case .lineTo(let point):
                newPath.addLine(to: transform.transform(point))
            case .quadCurveTo(let control, let end):
                newPath.addQuadCurve(
                    to: transform.transform(end),
                    control: transform.transform(control)
                )
            case .curveTo(let control1, let control2, let end):
                newPath.addCurve(
                    to: transform.transform(end),
                    control1: transform.transform(control1),
                    control2: transform.transform(control2)
                )
            case .closeSubpath:
                newPath.close()
            }
        }

        return newPath
    }
}

// MARK: - Path Sampling

extension ShapePath {
    /// Returns the point at the given normalized position along the path.
    ///
    /// - Parameter t: The normalized position (0 to 1).
    /// - Returns: The point at that position, or nil if the path is empty.
    public func point(at t: Float) -> Point? {
        let points = linearizedPoints()
        guard points.count >= 2 else { return points.first }

        let clamped = max(0, min(1, t))
        let totalLength = pathLength(points: points)
        guard totalLength > 0 else { return points.first }

        let targetLength = clamped * totalLength
        var accumulatedLength: Float = 0

        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i + 1]
            let segmentLength = distance(from: p0, to: p1)

            if accumulatedLength + segmentLength >= targetLength {
                let remaining = targetLength - accumulatedLength
                let ratio = segmentLength > 0 ? remaining / segmentLength : 0
                return Point(
                    x: p0.x + (p1.x - p0.x) * ratio,
                    y: p0.y + (p1.y - p0.y) * ratio
                )
            }

            accumulatedLength += segmentLength
        }

        return points.last
    }

    /// Returns the approximate total length of the path.
    ///
    /// The length is calculated by linearizing curves into segments.
    ///
    /// - Returns: The approximate length of the path in points.
    public func approximateLength() -> Float {
        let points = linearizedPoints()
        return pathLength(points: points)
    }

    /// Converts the path to an array of points for sampling.
    private func linearizedPoints() -> [Point] {
        var points: [Point] = []
        var currentPoint = Point.zero
        var subpathStart = Point.zero

        for element in elements {
            switch element {
            case .moveTo(let point):
                points.append(point)
                currentPoint = point
                subpathStart = point

            case .lineTo(let point):
                points.append(point)
                currentPoint = point

            case .quadCurveTo(let control, let end):
                // Sample the quadratic curve
                let steps = 10
                for i in 1...steps {
                    let t = Float(i) / Float(steps)
                    let p = quadraticBezier(p0: currentPoint, p1: control, p2: end, t: t)
                    points.append(p)
                }
                currentPoint = end

            case .curveTo(let c1, let c2, let end):
                // Sample the cubic curve
                let steps = 10
                for i in 1...steps {
                    let t = Float(i) / Float(steps)
                    let p = cubicBezier(p0: currentPoint, p1: c1, p2: c2, p3: end, t: t)
                    points.append(p)
                }
                currentPoint = end

            case .closeSubpath:
                if currentPoint.x != subpathStart.x || currentPoint.y != subpathStart.y {
                    points.append(subpathStart)
                }
                currentPoint = subpathStart
            }
        }

        return points
    }

    private func pathLength(points: [Point]) -> Float {
        var length: Float = 0
        for i in 0..<(points.count - 1) {
            length += distance(from: points[i], to: points[i + 1])
        }
        return length
    }

    private func distance(from p0: Point, to p1: Point) -> Float {
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        return sqrt(dx * dx + dy * dy)
    }

    private func quadraticBezier(p0: Point, p1: Point, p2: Point, t: Float) -> Point {
        let mt = 1 - t
        return Point(
            x: mt * mt * p0.x + 2 * mt * t * p1.x + t * t * p2.x,
            y: mt * mt * p0.y + 2 * mt * t * p1.y + t * t * p2.y
        )
    }

    private func cubicBezier(p0: Point, p1: Point, p2: Point, p3: Point, t: Float) -> Point {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t
        return Point(
            x: mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
            y: mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        )
    }
}

// MARK: - Path Element

/// An element of a path.
public enum PathElement: Sendable {
    /// Moves to a new point without drawing.
    case moveTo(Point)

    /// Draws a line to the specified point.
    case lineTo(Point)

    /// Draws a quadratic Bezier curve with the given control point and end point.
    case quadCurveTo(Point, Point)

    /// Draws a cubic Bezier curve with two control points and an end point.
    case curveTo(Point, Point, Point)

    /// Closes the current subpath.
    case closeSubpath
}
