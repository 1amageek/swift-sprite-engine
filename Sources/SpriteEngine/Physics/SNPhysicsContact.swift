/// Information about a collision between two physics bodies.
///
/// `SNPhysicsContact` is created automatically by the physics system to describe
/// a contact between two physical bodies. To receive contact messages, set the
/// `physicsWorld.contactDelegate` and configure `contactTestBitMask` on your
/// physics bodies.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKPhysicsContact                SNPhysicsContact
/// bodyA                           bodyA
/// bodyB                           bodyB
/// contactPoint                    contactPoint
/// contactNormal                   contactNormal
/// collisionImpulse                collisionImpulse
/// ```
///
/// ## Usage
/// ```swift
/// class GameScene: SNScene, SNPhysicsContactDelegate {
///     override func sceneDidLoad() {
///         physicsWorld.contactDelegate = self
///     }
///
///     func didBegin(_ contact: SNPhysicsContact) {
///         if contact.collisionImpulse > 5 {
///             // Strong collision
///             print("Impact force: \(contact.collisionImpulse)")
///         }
///     }
/// }
/// ```
public struct SNPhysicsContact: Sendable {
    /// The first body in the contact.
    public let bodyA: SNPhysicsBody

    /// The second body in the contact.
    public let bodyB: SNPhysicsBody

    /// The contact point between the two physics bodies, in scene coordinates.
    public let contactPoint: Point

    /// The normal vector specifying the direction of the collision.
    ///
    /// The normal points from bodyA to bodyB.
    public let contactNormal: Vector2

    /// The penetration depth.
    ///
    /// This indicates how much the bodies are overlapping.
    public let penetration: Float

    /// The impulse that specifies how hard these two bodies struck each other in Newton-seconds.
    ///
    /// Use this value to determine the severity of a collision. Higher values
    /// indicate more forceful impacts.
    public let collisionImpulse: Float

    /// Creates a physics contact.
    ///
    /// - Parameters:
    ///   - bodyA: The first body in the contact.
    ///   - bodyB: The second body in the contact.
    ///   - contactPoint: The point where the contact occurred.
    ///   - contactNormal: The collision normal (pointing from A to B).
    ///   - penetration: The penetration depth.
    ///   - collisionImpulse: The impulse magnitude in Newton-seconds.
    public init(
        bodyA: SNPhysicsBody,
        bodyB: SNPhysicsBody,
        contactPoint: Point,
        contactNormal: Vector2,
        penetration: Float,
        collisionImpulse: Float = 0
    ) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.contactPoint = contactPoint
        self.contactNormal = contactNormal
        self.penetration = penetration
        self.collisionImpulse = collisionImpulse
    }
}

/// Delegate for receiving physics contact notifications.
///
/// Implement this protocol to respond to collisions. The delegate is called
/// when two physics bodies with overlapping `contactTestBitMask` values come
/// into contact.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKPhysicsContactDelegate        PhysicsContactDelegate
/// didBegin(_:)                    didBegin(_:)
/// didEnd(_:)                      didEnd(_:)
/// ```
///
/// ## Usage
/// ```swift
/// class GameScene: SNScene, SNPhysicsContactDelegate {
///     override func sceneDidLoad() {
///         physicsWorld.contactDelegate = self
///     }
///
///     func didBegin(_ contact: SNPhysicsContact) {
///         // Handle collision start
///         let nodeA = contact.bodyA.node
///         let nodeB = contact.bodyB.node
///
///         if contact.collisionImpulse > 10 {
///             // Play impact sound for hard collisions
///         }
///     }
///
///     func didEnd(_ contact: SNPhysicsContact) {
///         // Handle collision end
///     }
/// }
/// ```
public protocol SNPhysicsContactDelegate: AnyObject {
    /// Called when two bodies first contact each other.
    ///
    /// - Parameter contact: Information about the contact.
    func didBegin(_ contact: SNPhysicsContact)

    /// Called when the contact ends between two physics bodies.
    ///
    /// - Parameter contact: Information about the contact that ended.
    func didEnd(_ contact: SNPhysicsContact)
}

// Default implementations
extension SNPhysicsContactDelegate {
    public func didBegin(_ contact: SNPhysicsContact) {}
    public func didEnd(_ contact: SNPhysicsContact) {}
}

/// Result of a physics ray cast.
///
/// Returned by `SNPhysicsWorld.raycast(from:to:)` when a ray intersects a physics body.
public struct SNPhysicsRaycastResult: Sendable {
    /// The body that was hit.
    public let body: SNPhysicsBody

    /// The point where the ray hit, in scene coordinates.
    public let point: Point

    /// The normal vector at the hit point.
    public let normal: Vector2

    /// The distance from the ray origin to the hit point.
    public let distance: Float

    /// Creates a raycast result.
    ///
    /// - Parameters:
    ///   - body: The body that was hit.
    ///   - point: The hit point.
    ///   - normal: The surface normal at the hit point.
    ///   - distance: The distance from the ray origin.
    public init(body: SNPhysicsBody, point: Point, normal: Vector2 = .zero, distance: Float) {
        self.body = body
        self.point = point
        self.normal = normal
        self.distance = distance
    }
}
