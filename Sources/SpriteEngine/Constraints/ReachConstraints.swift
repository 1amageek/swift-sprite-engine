/// A specification of the degree of freedom when solving inverse kinematics.
///
/// `ReachConstraints` defines the range of motion for a node when an inverse
/// kinematic (IK) action is executed. It specifies the minimum and maximum
/// angles that a joint can rotate.
///
/// ## Usage
/// ```swift
/// // Create reach constraints for an arm joint
/// let constraints = ReachConstraints(
///     lowerAngleLimit: -.pi / 4,  // -45 degrees
///     upperAngleLimit: .pi / 2     // 90 degrees
/// )
///
/// // Apply to a node
/// node.reachConstraints = constraints
///
/// // Run a reach action
/// let reach = Action.reach(to: targetNode, rootNode: shoulderNode, duration: 0.5)
/// handNode.run(reach)
/// ```
public struct ReachConstraints: Hashable, Sendable {
    /// The minimum angle in radians.
    ///
    /// The node cannot rotate below this angle during IK solving.
    public var lowerAngleLimit: Float

    /// The maximum angle in radians.
    ///
    /// The node cannot rotate above this angle during IK solving.
    public var upperAngleLimit: Float

    /// Creates reach constraints with the specified angle limits.
    ///
    /// - Parameters:
    ///   - lowerAngleLimit: The minimum angle in radians.
    ///   - upperAngleLimit: The maximum angle in radians.
    public init(lowerAngleLimit: Float, upperAngleLimit: Float) {
        self.lowerAngleLimit = lowerAngleLimit
        self.upperAngleLimit = upperAngleLimit
    }

    /// Creates reach constraints with angle limits in degrees.
    ///
    /// - Parameters:
    ///   - lowerAngleDegrees: The minimum angle in degrees.
    ///   - upperAngleDegrees: The maximum angle in degrees.
    public init(lowerAngleDegrees: Float, upperAngleDegrees: Float) {
        self.lowerAngleLimit = lowerAngleDegrees * .pi / 180
        self.upperAngleLimit = upperAngleDegrees * .pi / 180
    }

    /// The angular range of motion.
    public var range: Float {
        upperAngleLimit - lowerAngleLimit
    }

    /// The center angle of the range.
    public var centerAngle: Float {
        (lowerAngleLimit + upperAngleLimit) / 2
    }

    /// Clamps an angle to be within the constraints.
    ///
    /// - Parameter angle: The angle to clamp.
    /// - Returns: The clamped angle.
    public func clamp(_ angle: Float) -> Float {
        max(lowerAngleLimit, min(upperAngleLimit, angle))
    }

    /// Returns whether an angle is within the constraints.
    ///
    /// - Parameter angle: The angle to check.
    /// - Returns: `true` if the angle is within the allowed range.
    public func contains(_ angle: Float) -> Bool {
        angle >= lowerAngleLimit && angle <= upperAngleLimit
    }
}

// MARK: - Factory Methods

extension ReachConstraints {
    /// Creates constraints with no limits (full 360° rotation).
    public static var noLimits: ReachConstraints {
        ReachConstraints(lowerAngleLimit: -.pi, upperAngleLimit: .pi)
    }

    /// Creates constraints for a typical shoulder joint.
    public static var shoulder: ReachConstraints {
        ReachConstraints(lowerAngleDegrees: -90, upperAngleDegrees: 90)
    }

    /// Creates constraints for a typical elbow joint.
    public static var elbow: ReachConstraints {
        ReachConstraints(lowerAngleDegrees: 0, upperAngleDegrees: 145)
    }

    /// Creates constraints for a typical knee joint.
    public static var knee: ReachConstraints {
        ReachConstraints(lowerAngleDegrees: -145, upperAngleDegrees: 0)
    }

    /// Creates constraints for a typical hip joint.
    public static var hip: ReachConstraints {
        ReachConstraints(lowerAngleDegrees: -45, upperAngleDegrees: 120)
    }
}

// MARK: - CustomStringConvertible

extension ReachConstraints: CustomStringConvertible {
    public var description: String {
        let lowerDeg = lowerAngleLimit * 180 / .pi
        let upperDeg = upperAngleLimit * 180 / .pi
        return "ReachConstraints(\(lowerDeg)° to \(upperDeg)°)"
    }
}

// MARK: - Codable

extension ReachConstraints: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lowerAngleLimit = try container.decode(Float.self)
        upperAngleLimit = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lowerAngleLimit)
        try container.encode(upperAngleLimit)
    }
}
