/// A specification for constraining a node's position or rotation.
///
/// `SNConstraint` objects are used to automatically adjust a node's position or
/// rotation based on various criteria, such as keeping a node within bounds,
/// facing another node, or maintaining a specific orientation.
///
/// ## Usage
/// ```swift
/// // Constrain position to a rectangle
/// let bounds = SNConstraint.positionX(Range(lowerLimit: 0, upperLimit: 800))
///
/// // Make a node always face another node
/// let orient = SNConstraint.orient(to: targetNode)
///
/// // Apply constraints to a node
/// node.constraints = [bounds, orient]
/// ```
public final class SNConstraint: @unchecked Sendable {
    // MARK: - Constraint Type

    private enum ConstraintType {
        case positionX(Range)
        case positionY(Range)
        case position(Rect)
        case distance(Range, to: () -> SNNode?)
        case rotation(Range)
        case orientToNode(() -> SNNode?, offset: Float)
        case orientToPoint(Point, offset: Float)
    }

    // MARK: - Properties

    private let type: ConstraintType

    /// Whether the constraint is enabled.
    public var isEnabled: Bool = true

    // MARK: - Initialization

    private init(type: ConstraintType) {
        self.type = type
    }

    // MARK: - Factory Methods: Position

    /// Creates a constraint that limits the x position.
    ///
    /// - Parameter range: The allowed range for the x position.
    /// - Returns: A constraint.
    public static func positionX(_ range: Range) -> SNConstraint {
        SNConstraint(type: .positionX(range))
    }

    /// Creates a constraint that limits the y position.
    ///
    /// - Parameter range: The allowed range for the y position.
    /// - Returns: A constraint.
    public static func positionY(_ range: Range) -> SNConstraint {
        SNConstraint(type: .positionY(range))
    }

    /// Creates a constraint that limits position to a rectangle.
    ///
    /// - Parameter rect: The bounding rectangle.
    /// - Returns: A constraint.
    public static func position(in rect: Rect) -> SNConstraint {
        SNConstraint(type: .position(rect))
    }

    // MARK: - Factory Methods: Distance

    /// Creates a constraint that maintains a distance range to another node.
    ///
    /// - Parameters:
    ///   - range: The allowed distance range.
    ///   - node: The reference node.
    /// - Returns: A constraint.
    public static func distance(_ range: Range, to node: SNNode) -> SNConstraint {
        SNConstraint(type: .distance(range, to: { [weak node] in node }))
    }

    // MARK: - Factory Methods: Rotation

    /// Creates a constraint that limits the rotation.
    ///
    /// - Parameter range: The allowed rotation range in radians.
    /// - Returns: A constraint.
    public static func rotation(_ range: Range) -> SNConstraint {
        SNConstraint(type: .rotation(range))
    }

    /// Creates a constraint that limits the rotation in degrees.
    ///
    /// - Parameter range: The allowed rotation range in degrees.
    /// - Returns: A constraint.
    public static func rotationDegrees(_ range: Range) -> SNConstraint {
        let radianRange = Range(
            lowerLimit: range.lowerLimit * .pi / 180,
            upperLimit: range.upperLimit * .pi / 180
        )
        return SNConstraint(type: .rotation(radianRange))
    }

    // MARK: - Factory Methods: Orientation

    /// Creates a constraint that orients the node toward another node.
    ///
    /// - Parameters:
    ///   - node: The target node to face.
    ///   - offset: An angular offset in radians.
    /// - Returns: A constraint.
    public static func orient(to node: SNNode, offset: Float = 0) -> SNConstraint {
        SNConstraint(type: .orientToNode({ [weak node] in node }, offset: offset))
    }

    /// Creates a constraint that orients the node toward a point.
    ///
    /// - Parameters:
    ///   - point: The target point to face.
    ///   - offset: An angular offset in radians.
    /// - Returns: A constraint.
    public static func orient(to point: Point, offset: Float = 0) -> SNConstraint {
        SNConstraint(type: .orientToPoint(point, offset: offset))
    }

    // MARK: - Apply

    /// Applies this constraint to a node.
    ///
    /// - Parameter node: The node to constrain.
    public func apply(to node: SNNode) {
        guard isEnabled else { return }

        switch type {
        case .positionX(let range):
            node.position.x = range.clamp(node.position.x)

        case .positionY(let range):
            node.position.y = range.clamp(node.position.y)

        case .position(let rect):
            node.position.x = max(rect.minX, min(rect.maxX, node.position.x))
            node.position.y = max(rect.minY, min(rect.maxY, node.position.y))

        case .distance(let range, let getTargetNode):
            guard let targetNode = getTargetNode() else { return }
            // Use world positions for cross-hierarchy constraints
            let targetWorldPos = targetNode.worldPosition
            let nodeWorldPos = node.worldPosition
            let dx = nodeWorldPos.x - targetWorldPos.x
            let dy = nodeWorldPos.y - targetWorldPos.y
            let currentDistance = sqrt(dx * dx + dy * dy)

            guard currentDistance > 0 else { return }

            let clampedDistance = range.clamp(currentDistance)
            if clampedDistance != currentDistance {
                let scale = clampedDistance / currentDistance
                // Calculate new world position
                let newWorldX = targetWorldPos.x + dx * scale
                let newWorldY = targetWorldPos.y + dy * scale
                // Apply delta to local position
                node.position.x += newWorldX - nodeWorldPos.x
                node.position.y += newWorldY - nodeWorldPos.y
            }

        case .rotation(let range):
            node.rotation = range.clamp(node.rotation)

        case .orientToNode(let getTargetNode, let offset):
            guard let targetNode = getTargetNode() else { return }
            // Use world positions for cross-hierarchy constraints
            let targetWorldPos = targetNode.worldPosition
            let nodeWorldPos = node.worldPosition
            let dx = targetWorldPos.x - nodeWorldPos.x
            let dy = targetWorldPos.y - nodeWorldPos.y
            let angle = atan2(dy, dx)
            node.rotation = angle + offset

        case .orientToPoint(let point, let offset):
            // Point is in world/scene coordinates
            let nodeWorldPos = node.worldPosition
            let dx = point.x - nodeWorldPos.x
            let dy = point.y - nodeWorldPos.y
            let angle = atan2(dy, dx)
            node.rotation = angle + offset
        }
    }
}
