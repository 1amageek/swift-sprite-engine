/// A connection between two physics bodies.
///
/// `SNPhysicsJoint` connects two physics bodies together, constraining their
/// relative movement. Different joint types provide different behaviors.
///
/// ## Usage
/// ```swift
/// // Create a pin joint (rotates freely around a point)
/// let pin = SNPhysicsJoint.pin(
///     bodyA: bodyA,
///     bodyB: bodyB,
///     anchor: Point(x: 100, y: 100)
/// )
/// scene.physicsWorld.add(pin)
///
/// // Create a spring joint
/// let spring = SNPhysicsJoint.spring(
///     bodyA: bodyA,
///     bodyB: bodyB,
///     anchorA: Point(x: 0, y: 0),
///     anchorB: Point(x: 0, y: 0),
///     frequency: 2.0,
///     damping: 0.5
/// )
/// scene.physicsWorld.add(spring)
/// ```
public class SNPhysicsJoint {
    // MARK: - Properties

    /// The first body connected by the joint.
    public private(set) weak var bodyA: SNPhysicsBody?

    /// The second body connected by the joint.
    public private(set) weak var bodyB: SNPhysicsBody?

    /// The physics world this joint belongs to.
    internal weak var world: SNPhysicsWorld?

    /// The instantaneous reaction force, in newtons, currently being directed at the anchor point.
    ///
    /// This property is updated by the physics simulation and represents the force
    /// needed to maintain the joint constraint.
    public private(set) var reactionForce: Vector2 = .zero

    /// The instantaneous reaction torque, in newton-meters, currently being directed at the anchor point.
    ///
    /// This property is updated by the physics simulation and represents the torque
    /// needed to maintain the joint constraint.
    public private(set) var reactionTorque: Float = 0

    // MARK: - Initialization

    internal init(bodyA: SNPhysicsBody, bodyB: SNPhysicsBody) {
        self.bodyA = bodyA
        self.bodyB = bodyB
    }

    // MARK: - Internal Updates

    /// Updates the reaction force and torque values (called by physics simulation).
    internal func updateReactionForces(force: Vector2, torque: Float) {
        self.reactionForce = force
        self.reactionTorque = torque
    }
}

// MARK: - Pin Joint

/// A joint that connects two bodies at a single point, allowing rotation.
public final class SNPhysicsJointPin: SNPhysicsJoint {
    /// The anchor point in scene coordinates.
    public var anchor: Point

    /// Whether rotation limits are enabled.
    public var shouldEnableLimits: Bool = false

    /// The lower rotation limit in radians.
    public var lowerAngleLimit: Float = -.pi

    /// The upper rotation limit in radians.
    public var upperAngleLimit: Float = .pi

    /// The friction applied to the rotation.
    public var frictionTorque: Float = 0

    /// The speed, in radians per second, at which the physics bodies are driven around the pin joint.
    ///
    /// Set this to a non-zero value to have the joint act like a motor, driving
    /// the connected bodies to rotate at the specified speed.
    public var rotationSpeed: Float = 0

    /// Creates a pin joint.
    ///
    /// - Parameters:
    ///   - bodyA: The first body.
    ///   - bodyB: The second body.
    ///   - anchor: The anchor point in scene coordinates.
    public init(bodyA: SNPhysicsBody, bodyB: SNPhysicsBody, anchor: Point) {
        self.anchor = anchor
        super.init(bodyA: bodyA, bodyB: bodyB)
    }
}

// MARK: - Spring Joint

/// A joint that simulates a spring between two anchor points.
public final class SNPhysicsJointSpring: SNPhysicsJoint {
    /// The anchor point on body A in local coordinates.
    public var anchorA: Point

    /// The anchor point on body B in local coordinates.
    public var anchorB: Point

    /// The oscillation frequency of the spring in Hz.
    public var frequency: Float

    /// The damping ratio (0 = no damping, 1 = critical damping).
    public var damping: Float

    /// Creates a spring joint.
    ///
    /// - Parameters:
    ///   - bodyA: The first body.
    ///   - bodyB: The second body.
    ///   - anchorA: The anchor point on body A.
    ///   - anchorB: The anchor point on body B.
    ///   - frequency: The oscillation frequency.
    ///   - damping: The damping ratio.
    public init(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchorA: Point,
        anchorB: Point,
        frequency: Float = 1.0,
        damping: Float = 0.5
    ) {
        self.anchorA = anchorA
        self.anchorB = anchorB
        self.frequency = frequency
        self.damping = damping
        super.init(bodyA: bodyA, bodyB: bodyB)
    }
}

// MARK: - Fixed Joint

/// A joint that rigidly connects two bodies with no relative movement.
public final class SNPhysicsJointFixed: SNPhysicsJoint {
    /// The anchor point in scene coordinates.
    public var anchor: Point

    /// Creates a fixed joint.
    ///
    /// - Parameters:
    ///   - bodyA: The first body.
    ///   - bodyB: The second body.
    ///   - anchor: The anchor point in scene coordinates.
    public init(bodyA: SNPhysicsBody, bodyB: SNPhysicsBody, anchor: Point) {
        self.anchor = anchor
        super.init(bodyA: bodyA, bodyB: bodyB)
    }
}

// MARK: - Sliding Joint

/// A joint that allows sliding along an axis.
public final class SNPhysicsJointSliding: SNPhysicsJoint {
    /// The anchor point in scene coordinates.
    public var anchor: Point

    /// The axis of sliding (normalized).
    public var axis: Vector2

    /// Whether distance limits are enabled.
    public var shouldEnableLimits: Bool = false

    /// The lower distance limit.
    public var lowerDistanceLimit: Float = 0

    /// The upper distance limit.
    public var upperDistanceLimit: Float = .infinity

    /// Creates a sliding joint.
    ///
    /// - Parameters:
    ///   - bodyA: The first body.
    ///   - bodyB: The second body.
    ///   - anchor: The anchor point in scene coordinates.
    ///   - axis: The axis of sliding.
    public init(bodyA: SNPhysicsBody, bodyB: SNPhysicsBody, anchor: Point, axis: Vector2) {
        self.anchor = anchor
        self.axis = axis.normalized
        super.init(bodyA: bodyA, bodyB: bodyB)
    }
}

// MARK: - Limit Joint

/// A joint that constrains the distance between two points.
public final class SNPhysicsJointLimit: SNPhysicsJoint {
    /// The anchor point on body A in local coordinates.
    public var anchorA: Point

    /// The anchor point on body B in local coordinates.
    public var anchorB: Point

    /// The maximum distance between the anchor points.
    public var maxLength: Float

    /// Creates a limit joint.
    ///
    /// - Parameters:
    ///   - bodyA: The first body.
    ///   - bodyB: The second body.
    ///   - anchorA: The anchor point on body A.
    ///   - anchorB: The anchor point on body B.
    ///   - maxLength: The maximum allowed distance.
    public init(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchorA: Point,
        anchorB: Point,
        maxLength: Float
    ) {
        self.anchorA = anchorA
        self.anchorB = anchorB
        self.maxLength = maxLength
        super.init(bodyA: bodyA, bodyB: bodyB)
    }
}

// MARK: - Factory Methods

extension SNPhysicsJoint {
    /// Creates a pin joint.
    public static func pin(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchor: Point
    ) -> SNPhysicsJointPin {
        SNPhysicsJointPin(bodyA: bodyA, bodyB: bodyB, anchor: anchor)
    }

    /// Creates a spring joint.
    public static func spring(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchorA: Point,
        anchorB: Point,
        frequency: Float = 1.0,
        damping: Float = 0.5
    ) -> SNPhysicsJointSpring {
        SNPhysicsJointSpring(
            bodyA: bodyA,
            bodyB: bodyB,
            anchorA: anchorA,
            anchorB: anchorB,
            frequency: frequency,
            damping: damping
        )
    }

    /// Creates a fixed joint.
    public static func fixed(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchor: Point
    ) -> SNPhysicsJointFixed {
        SNPhysicsJointFixed(bodyA: bodyA, bodyB: bodyB, anchor: anchor)
    }

    /// Creates a sliding joint.
    public static func sliding(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchor: Point,
        axis: Vector2
    ) -> SNPhysicsJointSliding {
        SNPhysicsJointSliding(bodyA: bodyA, bodyB: bodyB, anchor: anchor, axis: axis)
    }

    /// Creates a limit joint.
    public static func limit(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        anchorA: Point,
        anchorB: Point,
        maxLength: Float
    ) -> SNPhysicsJointLimit {
        SNPhysicsJointLimit(
            bodyA: bodyA,
            bodyB: bodyB,
            anchorA: anchorA,
            anchorB: anchorB,
            maxLength: maxLength
        )
    }
}
