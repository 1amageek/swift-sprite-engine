/// Manages physics simulation for a scene.
///
/// `SNPhysicsWorld` handles gravity, collision detection, and physics updates.
/// Each `SNScene` has an associated `SNPhysicsWorld`.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKPhysicsWorld                  SNPhysicsWorld
/// gravity                         gravity
/// speed                           speed
/// contactDelegate                 contactDelegate
/// add(_:)                         add(_:)
/// remove(_:)                      remove(_:)
/// removeAllJoints()               removeAllJoints()
/// body(at:)                       body(at:)
/// body(in:)                       body(in:)
/// body(alongRayStart:end:)        body(alongRayStart:end:)
/// enumerateBodies(at:using:)      enumerateBodies(at:using:)
/// enumerateBodies(in:using:)      enumerateBodies(in:using:)
/// enumerateBodies(alongRayStart:end:using:)  enumerateBodies(alongRayStart:end:using:)
/// sampleFields(at:)               sampleFields(at:)
/// ```
///
/// ## Usage
/// ```swift
/// class GameScene: SNScene {
///     override func sceneDidLoad() {
///         physicsWorld.gravity = Vector2(dx: 0, dy: -980) // 9.8 m/s² in points
///         physicsWorld.contactDelegate = self
///     }
/// }
/// ```
public final class SNPhysicsWorld: @unchecked Sendable {
    // MARK: - Properties

    /// The gravity vector applied to all dynamic bodies.
    /// Default is (0, -980) representing Earth gravity in points/s².
    public var gravity: Vector2 = Vector2(dx: 0, dy: -980)

    /// The speed multiplier for physics simulation.
    public var speed: Float = 1.0

    /// The delegate that receives contact notifications.
    public weak var contactDelegate: SNPhysicsContactDelegate?

    /// All physics bodies in this world.
    private var bodies: [SNPhysicsBody] = []

    /// All physics joints in this world.
    private var joints: [SNPhysicsJoint] = []

    /// The scene this world belongs to.
    public internal(set) weak var scene: SNScene?

    // MARK: - Contact Tracking

    /// Tracks contact pairs from the previous frame for didEnd callbacks.
    private var previousContacts: Set<ContactPair> = []

    /// Tracks contact pairs from the current frame.
    private var currentContacts: Set<ContactPair> = []

    /// Stores contact info for the current frame (for didEnd callbacks).
    private var currentContactInfo: [ContactPair: SNPhysicsContact] = [:]

    /// A hashable pair of physics bodies for contact tracking.
    private struct ContactPair: Hashable {
        let idA: ObjectIdentifier
        let idB: ObjectIdentifier

        init(_ bodyA: SNPhysicsBody, _ bodyB: SNPhysicsBody) {
            // Always store in consistent order for proper hashing
            let a = ObjectIdentifier(bodyA)
            let b = ObjectIdentifier(bodyB)
            if a < b {
                self.idA = a
                self.idB = b
            } else {
                self.idA = b
                self.idB = a
            }
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Joint Management

    /// Adds a joint to the physics world.
    ///
    /// When a joint is added, it is also registered with both connected physics bodies
    /// so they can track their joint connections via their `joints` property.
    ///
    /// - Parameter joint: The joint to add.
    public func add(_ joint: SNPhysicsJoint) {
        if !joints.contains(where: { $0 === joint }) {
            joints.append(joint)
            joint.world = self

            // Register joint with both bodies
            joint.bodyA?.joints.append(joint)
            joint.bodyB?.joints.append(joint)
        }
    }

    /// Removes a specific joint from the physics world.
    ///
    /// When removed, the joint is also unregistered from both connected physics bodies.
    ///
    /// - Parameter joint: The joint to remove.
    public func remove(_ joint: SNPhysicsJoint) {
        joints.removeAll { $0 === joint }
        joint.world = nil

        // Unregister joint from both bodies
        joint.bodyA?.joints.removeAll { $0 === joint }
        joint.bodyB?.joints.removeAll { $0 === joint }
    }

    /// Removes all joints from the physics world.
    ///
    /// All joints are also unregistered from their connected physics bodies.
    public func removeAllJoints() {
        for joint in joints {
            joint.world = nil

            // Unregister joint from both bodies
            joint.bodyA?.joints.removeAll { $0 === joint }
            joint.bodyB?.joints.removeAll { $0 === joint }
        }
        joints.removeAll()
    }

    // MARK: - Body Management

    /// Registers a physics body with this world.
    internal func addBody(_ body: SNPhysicsBody) {
        if !bodies.contains(where: { $0 === body }) {
            bodies.append(body)
        }
    }

    /// Removes a physics body from this world.
    internal func removeBody(_ body: SNPhysicsBody) {
        bodies.removeAll { $0 === body }
    }

    // MARK: - Simulation

    /// Performs one step of physics simulation.
    ///
    /// - Parameter dt: The time step in seconds.
    internal func simulate(dt: Float) {
        let scaledDt = dt * speed
        guard scaledDt > 0 else { return }

        // Reset current frame contact tracking
        currentContacts.removeAll(keepingCapacity: true)
        currentContactInfo.removeAll(keepingCapacity: true)

        // Store previous positions for CCD
        for body in bodies where body.isDynamic && body.usesPreciseCollisionDetection {
            if let node = body.node {
                body.previousPosition = node.position
            }
        }

        // Collect fields from the scene
        let fields = collectFieldNodes()

        // Update field node time (for animated fields like noise/turbulence)
        for field in fields {
            field.update(deltaTime: scaledDt)
        }

        // Apply gravity, fields, and integrate velocities
        for body in bodies where body.isDynamic {
            // Skip pinned bodies
            if body.pinned { continue }

            // Apply gravity
            if body.affectedByGravity {
                body.velocity += gravity * scaledDt
            }

            // Apply field forces
            if let node = body.node {
                let fieldForce = calculateFieldForce(for: body, at: node.worldPosition, fields: fields, dt: scaledDt)
                if !fieldForce.isZero {
                    body.velocity += fieldForce * (scaledDt / body.mass)
                }
            }

            // Apply linear damping
            body.velocity = body.velocity * (1.0 - body.linearDamping * scaledDt)

            // Apply angular damping
            body.angularVelocity = body.angularVelocity * (1.0 - body.angularDamping * scaledDt)

            // Update position
            if let node = body.node {
                node.position.x += body.velocity.dx * scaledDt
                node.position.y += body.velocity.dy * scaledDt

                // Update rotation
                if body.allowsRotation {
                    node.rotation += body.angularVelocity * scaledDt
                }
            }
        }

        // Detect CCD collisions for fast-moving bodies
        detectCCDCollisions(dt: scaledDt)

        // Detect and resolve regular collisions
        detectCollisions()

        // Process contact end events
        processContactEndEvents()

        // Update previous contacts for next frame
        previousContacts = currentContacts
    }

    /// Processes contact end events by comparing current and previous contacts.
    private func processContactEndEvents() {
        guard contactDelegate != nil else { return }

        // Find contacts that ended (were in previous but not in current)
        let endedContacts = previousContacts.subtracting(currentContacts)

        for pair in endedContacts {
            // Find the bodies for this pair
            let bodyA = bodies.first { ObjectIdentifier($0) == pair.idA }
            let bodyB = bodies.first { ObjectIdentifier($0) == pair.idB }

            guard let a = bodyA, let b = bodyB else { continue }

            // Only notify if contact test is enabled
            guard shouldNotify(a, b) else { continue }

            // Remove from contacted bodies tracking
            a.contactedBodies.remove(ObjectIdentifier(b))
            b.contactedBodies.remove(ObjectIdentifier(a))

            // Create an end contact (with zero impulse since collision ended)
            guard let nodeA = a.node, let nodeB = b.node else { continue }
            let posA = nodeA.worldPosition
            let posB = nodeB.worldPosition

            // Use midpoint as contact point for end event
            let contactPoint = Point(
                x: (posA.x + posB.x) / 2,
                y: (posA.y + posB.y) / 2
            )

            // Normal from A to B
            let dx = posB.x - posA.x
            let dy = posB.y - posA.y
            let dist = sqrt(dx * dx + dy * dy)
            let normal = dist > 0 ? Vector2(dx: dx / dist, dy: dy / dist) : Vector2(dx: 1, dy: 0)

            let endContact = SNPhysicsContact(
                bodyA: a,
                bodyB: b,
                contactPoint: contactPoint,
                contactNormal: normal,
                penetration: 0,
                collisionImpulse: 0
            )

            contactDelegate?.didEnd(endContact)
        }
    }

    // MARK: - Continuous Collision Detection (CCD)

    /// Detects collisions for fast-moving bodies using swept collision detection.
    private func detectCCDCollisions(dt: Float) {
        for body in bodies where body.isDynamic && body.usesPreciseCollisionDetection {
            guard let node = body.node,
                  let previousPos = body.previousPosition else { continue }

            let currentPos = node.position
            let movement = Vector2(dx: currentPos.x - previousPos.x, dy: currentPos.y - previousPos.y)

            // Skip if not moving significantly
            guard movement.magnitude > 0.001 else { continue }

            // Find the earliest collision along the movement path
            var earliestT: Float = 1.0
            var earliestContact: (body: SNPhysicsBody, normal: Vector2)?

            for otherBody in bodies where otherBody !== body {
                // Skip if they shouldn't interact
                guard shouldTest(body, otherBody) else { continue }

                guard let otherNode = otherBody.node else { continue }
                let otherBox = otherBody.boundingBox(at: otherNode.worldPosition)

                // Expand the target box by the moving body's size (Minkowski sum approach)
                let bodyHalfSize = body.boundingBoxHalfSize
                let expandedBox = Rect(
                    x: otherBox.origin.x - bodyHalfSize.width,
                    y: otherBox.origin.y - bodyHalfSize.height,
                    width: otherBox.size.width + bodyHalfSize.width * 2,
                    height: otherBox.size.height + bodyHalfSize.height * 2
                )

                // Ray-box intersection using the body center
                if let (t, normal) = rayIntersectsRectWithT(
                    from: previousPos,
                    direction: movement,
                    rect: expandedBox
                ) {
                    if t < earliestT && t >= 0 && t < 1 {
                        earliestT = t
                        earliestContact = (otherBody, normal)
                    }
                }
            }

            // If we found an earlier collision, handle it
            if let contact = earliestContact, earliestT < 1.0 {
                // Move body to collision point (with small offset)
                let collisionPoint = Point(
                    x: previousPos.x + movement.dx * earliestT - contact.normal.dx * 0.01,
                    y: previousPos.y + movement.dy * earliestT - contact.normal.dy * 0.01
                )
                node.position = collisionPoint

                // Calculate collision response
                let velocityAlongNormal = body.velocity.dot(contact.normal)
                if velocityAlongNormal < 0 {
                    // Reflect velocity
                    let restitution = min(body.restitution, contact.body.restitution)
                    let reflectedVelocity = body.velocity - contact.normal * (velocityAlongNormal * (1 + restitution))
                    body.velocity = reflectedVelocity
                }

                // Create and report contact
                let physicsContact = SNPhysicsContact(
                    bodyA: body,
                    bodyB: contact.body,
                    contactPoint: collisionPoint,
                    contactNormal: contact.normal,
                    penetration: 0,
                    collisionImpulse: abs(velocityAlongNormal) * body.mass
                )

                let pair = ContactPair(body, contact.body)
                currentContacts.insert(pair)

                body.contactedBodies.insert(ObjectIdentifier(contact.body))
                contact.body.contactedBodies.insert(ObjectIdentifier(body))

                if shouldNotify(body, contact.body) && !previousContacts.contains(pair) {
                    contactDelegate?.didBegin(physicsContact)
                }
            }

            // Clear previous position for next frame
            body.previousPosition = nil
        }
    }

    /// Ray-box intersection returning the parametric t value and hit normal.
    private func rayIntersectsRectWithT(from start: Point, direction: Vector2, rect: Rect) -> (Float, Vector2)? {
        let invDir = Vector2(
            dx: direction.dx != 0 ? 1 / direction.dx : .infinity,
            dy: direction.dy != 0 ? 1 / direction.dy : .infinity
        )

        let t1 = (rect.minX - start.x) * invDir.dx
        let t2 = (rect.maxX - start.x) * invDir.dx
        let t3 = (rect.minY - start.y) * invDir.dy
        let t4 = (rect.maxY - start.y) * invDir.dy

        let tMinX = min(t1, t2)
        let tMaxX = max(t1, t2)
        let tMinY = min(t3, t4)
        let tMaxY = max(t3, t4)

        let tmin = max(tMinX, tMinY)
        let tmax = min(tMaxX, tMaxY)

        if tmax < 0 || tmin > tmax {
            return nil
        }

        let t = tmin >= 0 ? tmin : tmax

        // Calculate normal based on which face was hit
        let normal: Vector2
        if tmin == tMinX {
            normal = direction.dx > 0 ? Vector2(dx: -1, dy: 0) : Vector2(dx: 1, dy: 0)
        } else {
            normal = direction.dy > 0 ? Vector2(dx: 0, dy: -1) : Vector2(dx: 0, dy: 1)
        }

        return (t, normal)
    }

    // MARK: - Collision Detection

    private func detectCollisions() {
        let bodyCount = bodies.count

        for i in 0..<bodyCount {
            for j in (i + 1)..<bodyCount {
                let bodyA = bodies[i]
                let bodyB = bodies[j]

                // Check if they should collide
                guard shouldTest(bodyA, bodyB) else { continue }

                // Get positions
                guard let nodeA = bodyA.node, let nodeB = bodyB.node else { continue }
                let posA = nodeA.worldPosition
                let posB = nodeB.worldPosition

                // Check for collision
                if var contact = checkCollision(bodyA, at: posA, with: bodyB, at: posB) {
                    let pair = ContactPair(bodyA, bodyB)

                    // Resolve collision and get impulse magnitude
                    var impulseMagnitude: Float = 0
                    if shouldCollide(bodyA, bodyB) {
                        impulseMagnitude = resolveCollision(contact)
                    }

                    // Create contact with collision impulse
                    contact = SNPhysicsContact(
                        bodyA: contact.bodyA,
                        bodyB: contact.bodyB,
                        contactPoint: contact.contactPoint,
                        contactNormal: contact.contactNormal,
                        penetration: contact.penetration,
                        collisionImpulse: impulseMagnitude
                    )

                    // Track this contact
                    currentContacts.insert(pair)
                    currentContactInfo[pair] = contact

                    // Track contacted bodies
                    bodyA.contactedBodies.insert(ObjectIdentifier(bodyB))
                    bodyB.contactedBodies.insert(ObjectIdentifier(bodyA))

                    // Notify delegate - only for NEW contacts
                    if shouldNotify(bodyA, bodyB) {
                        let isNewContact = !previousContacts.contains(pair)
                        if isNewContact {
                            contactDelegate?.didBegin(contact)
                        }
                    }
                }
            }
        }
    }

    private func shouldTest(_ a: SNPhysicsBody, _ b: SNPhysicsBody) -> Bool {
        // At least one must be dynamic
        guard a.isDynamic || b.isDynamic else { return false }

        // Check category masks
        let aTestsB = (a.collisionBitMask & b.categoryBitMask) != 0 ||
                      (a.contactTestBitMask & b.categoryBitMask) != 0
        let bTestsA = (b.collisionBitMask & a.categoryBitMask) != 0 ||
                      (b.contactTestBitMask & a.categoryBitMask) != 0

        return aTestsB || bTestsA
    }

    private func shouldCollide(_ a: SNPhysicsBody, _ b: SNPhysicsBody) -> Bool {
        (a.collisionBitMask & b.categoryBitMask) != 0 ||
        (b.collisionBitMask & a.categoryBitMask) != 0
    }

    private func shouldNotify(_ a: SNPhysicsBody, _ b: SNPhysicsBody) -> Bool {
        (a.contactTestBitMask & b.categoryBitMask) != 0 ||
        (b.contactTestBitMask & a.categoryBitMask) != 0
    }

    private func checkCollision(_ bodyA: SNPhysicsBody, at posA: Point,
                                with bodyB: SNPhysicsBody, at posB: Point) -> SNPhysicsContact? {
        let boxA = bodyA.boundingBox(at: posA)
        let boxB = bodyB.boundingBox(at: posB)

        // AABB intersection test
        guard boxA.intersects(boxB) else { return nil }

        // Calculate penetration
        let overlapX = min(boxA.maxX - boxB.minX, boxB.maxX - boxA.minX)
        let overlapY = min(boxA.maxY - boxB.minY, boxB.maxY - boxA.minY)

        // Determine collision normal (shortest axis)
        let normal: Vector2
        let penetration: Float

        if overlapX < overlapY {
            penetration = overlapX
            normal = posA.x < posB.x ? Vector2(dx: -1, dy: 0) : Vector2(dx: 1, dy: 0)
        } else {
            penetration = overlapY
            normal = posA.y < posB.y ? Vector2(dx: 0, dy: -1) : Vector2(dx: 0, dy: 1)
        }

        // Contact point (midpoint of overlap)
        let contactPoint = Point(
            x: (max(boxA.minX, boxB.minX) + min(boxA.maxX, boxB.maxX)) / 2,
            y: (max(boxA.minY, boxB.minY) + min(boxA.maxY, boxB.maxY)) / 2
        )

        return SNPhysicsContact(
            bodyA: bodyA,
            bodyB: bodyB,
            contactPoint: contactPoint,
            contactNormal: normal,
            penetration: penetration
        )
    }

    /// Resolves a collision and returns the impulse magnitude in Newton-seconds.
    @discardableResult
    private func resolveCollision(_ contact: SNPhysicsContact) -> Float {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        guard let nodeA = bodyA.node, let nodeB = bodyB.node else { return 0 }

        // Check if either body is pinned
        let aDynamic = bodyA.isDynamic && !bodyA.pinned
        let bDynamic = bodyB.isDynamic && !bodyB.pinned

        // Separate bodies
        let separation = contact.contactNormal * contact.penetration

        if aDynamic && bDynamic {
            // Both dynamic: split separation
            nodeA.position.x += separation.dx / 2
            nodeA.position.y += separation.dy / 2
            nodeB.position.x -= separation.dx / 2
            nodeB.position.y -= separation.dy / 2
        } else if aDynamic {
            // Only A is dynamic
            nodeA.position.x += separation.dx
            nodeA.position.y += separation.dy
        } else if bDynamic {
            // Only B is dynamic
            nodeB.position.x -= separation.dx
            nodeB.position.y -= separation.dy
        }

        // Calculate relative velocity
        let relativeVelocity = bodyA.velocity - bodyB.velocity
        let velocityAlongNormal = relativeVelocity.dot(contact.contactNormal)

        // Don't resolve if velocities are separating
        guard velocityAlongNormal > 0 else { return 0 }

        // Calculate restitution (bounciness)
        let restitution = min(bodyA.restitution, bodyB.restitution)

        // Calculate impulse magnitude
        var impulseMagnitude = -(1 + restitution) * velocityAlongNormal

        // Account for mass
        let invMassA = aDynamic ? 1 / bodyA.mass : 0
        let invMassB = bDynamic ? 1 / bodyB.mass : 0
        impulseMagnitude /= (invMassA + invMassB)

        // Apply impulse
        let impulse = contact.contactNormal * impulseMagnitude

        if aDynamic {
            bodyA.velocity = bodyA.velocity - impulse * invMassA
        }
        if bDynamic {
            bodyB.velocity = bodyB.velocity + impulse * invMassB
        }

        // Apply friction
        let tangent = relativeVelocity - contact.contactNormal * velocityAlongNormal
        if !tangent.isZero {
            let tangentNormal = tangent.normalized
            let friction = (bodyA.friction + bodyB.friction) / 2
            let frictionImpulse = tangentNormal * impulseMagnitude * friction

            if aDynamic {
                bodyA.velocity = bodyA.velocity - frictionImpulse * invMassA
            }
            if bDynamic {
                bodyB.velocity = bodyB.velocity + frictionImpulse * invMassB
            }
        }

        // Return absolute impulse magnitude in Newton-seconds
        return abs(impulseMagnitude)
    }

    // MARK: - Queries (Single Body)

    /// Returns the first body found at the specified point.
    ///
    /// Use this method to quickly check if there's a physics body at a given location.
    /// If you need all bodies at a point, use `bodies(at:)` or `enumerateBodies(at:using:)`.
    ///
    /// - Parameter point: The point to check, in scene coordinates.
    /// - Returns: A physics body at the point, or nil if none exists.
    public func body(at point: Point) -> SNPhysicsBody? {
        bodies.first { body in
            guard let node = body.node else { return false }
            return body.boundingBox(at: node.worldPosition).contains(point)
        }
    }

    /// Returns the first body found intersecting the specified rectangle.
    ///
    /// - Parameter rect: The rectangle to check, in scene coordinates.
    /// - Returns: A physics body intersecting the rectangle, or nil if none exists.
    public func body(in rect: Rect) -> SNPhysicsBody? {
        bodies.first { body in
            guard let node = body.node else { return false }
            return body.boundingBox(at: node.worldPosition).intersects(rect)
        }
    }

    /// Returns the first body found along a ray from start to end.
    ///
    /// This is a convenience method that returns only the first body hit.
    /// For more detailed results, use `raycast(from:to:)` or `enumerateBodies(alongRayStart:end:using:)`.
    ///
    /// - Parameters:
    ///   - start: The starting point of the ray.
    ///   - end: The ending point of the ray.
    /// - Returns: The first physics body along the ray, or nil if none is hit.
    public func body(alongRayStart start: Point, end: Point) -> SNPhysicsBody? {
        raycast(from: start, to: end)?.body
    }

    // MARK: - Queries (All Bodies)

    /// Returns all bodies at the specified point.
    ///
    /// - Parameter point: The point to check, in scene coordinates.
    /// - Returns: An array of physics bodies at the point.
    public func bodies(at point: Point) -> [SNPhysicsBody] {
        bodies.filter { body in
            guard let node = body.node else { return false }
            return body.boundingBox(at: node.worldPosition).contains(point)
        }
    }

    /// Returns all bodies intersecting the specified rectangle.
    ///
    /// - Parameter rect: The rectangle to check, in scene coordinates.
    /// - Returns: An array of physics bodies intersecting the rectangle.
    public func bodies(in rect: Rect) -> [SNPhysicsBody] {
        bodies.filter { body in
            guard let node = body.node else { return false }
            return body.boundingBox(at: node.worldPosition).intersects(rect)
        }
    }

    /// Returns all bodies that are currently in contact with the specified body.
    ///
    /// This is used internally by `SNPhysicsBody.allContactedBodies()`.
    ///
    /// - Parameter body: The body to check contacts for.
    /// - Returns: An array of bodies in contact with the specified body.
    internal func bodiesInContact(with body: SNPhysicsBody) -> [SNPhysicsBody] {
        bodies.filter { otherBody in
            guard otherBody !== body else { return false }
            return body.contactedBodies.contains(ObjectIdentifier(otherBody))
        }
    }

    // MARK: - Queries (Enumeration)

    /// Enumerates all bodies at the specified point.
    ///
    /// The block is called for each body found at the point. Set the stop pointer
    /// to true to stop enumeration early.
    ///
    /// - Parameters:
    ///   - point: The point to check, in scene coordinates.
    ///   - block: A closure called for each body found.
    ///     - body: The physics body at the point.
    ///     - stop: Set to true to stop enumeration.
    public func enumerateBodies(at point: Point, using block: (SNPhysicsBody, UnsafeMutablePointer<Bool>) -> Void) {
        var stop = false
        for body in bodies {
            guard !stop else { break }
            guard let node = body.node else { continue }
            if body.boundingBox(at: node.worldPosition).contains(point) {
                block(body, &stop)
            }
        }
    }

    /// Enumerates all bodies intersecting the specified rectangle.
    ///
    /// The block is called for each body found in the rectangle. Set the stop pointer
    /// to true to stop enumeration early.
    ///
    /// - Parameters:
    ///   - rect: The rectangle to check, in scene coordinates.
    ///   - block: A closure called for each body found.
    ///     - body: The physics body in the rectangle.
    ///     - stop: Set to true to stop enumeration.
    public func enumerateBodies(in rect: Rect, using block: (SNPhysicsBody, UnsafeMutablePointer<Bool>) -> Void) {
        var stop = false
        for body in bodies {
            guard !stop else { break }
            guard let node = body.node else { continue }
            if body.boundingBox(at: node.worldPosition).intersects(rect) {
                block(body, &stop)
            }
        }
    }

    /// Enumerates all bodies along a ray from start to end.
    ///
    /// The block is called for each body intersected by the ray, in order from
    /// closest to farthest. Set the stop pointer to true to stop enumeration early.
    ///
    /// - Parameters:
    ///   - start: The starting point of the ray.
    ///   - end: The ending point of the ray.
    ///   - block: A closure called for each body found.
    ///     - body: The physics body hit by the ray.
    ///     - point: The point where the ray intersects the body.
    ///     - normal: The surface normal at the intersection point.
    ///     - stop: Set to true to stop enumeration.
    public func enumerateBodies(alongRayStart start: Point, end: Point,
                                using block: (SNPhysicsBody, Point, Vector2, UnsafeMutablePointer<Bool>) -> Void) {
        // Collect all ray hits
        var hits: [(body: SNPhysicsBody, point: Point, normal: Vector2, distance: Float)] = []

        for body in bodies {
            guard let node = body.node else { continue }
            let box = body.boundingBox(at: node.worldPosition)

            if let (intersection, normal) = rayIntersectsRectWithNormal(from: start, to: end, rect: box) {
                let distance = start.distance(to: intersection)
                hits.append((body, intersection, normal, distance))
            }
        }

        // Sort by distance
        hits.sort { $0.distance < $1.distance }

        // Enumerate
        var stop = false
        for hit in hits {
            guard !stop else { break }
            block(hit.body, hit.point, hit.normal, &stop)
        }
    }

    // MARK: - Raycast

    /// Performs a ray cast and returns the first body hit with detailed information.
    ///
    /// - Parameters:
    ///   - start: The starting point of the ray.
    ///   - end: The ending point of the ray.
    /// - Returns: A `SNPhysicsRaycastResult` containing hit information, or nil if no body is hit.
    public func raycast(from start: Point, to end: Point) -> SNPhysicsRaycastResult? {
        var closestResult: SNPhysicsRaycastResult?
        var closestDistance: Float = .infinity

        for body in bodies {
            guard let node = body.node else { continue }
            let box = body.boundingBox(at: node.worldPosition)

            if let (intersection, normal) = rayIntersectsRectWithNormal(from: start, to: end, rect: box) {
                let distance = start.distance(to: intersection)
                if distance < closestDistance {
                    closestDistance = distance
                    closestResult = SNPhysicsRaycastResult(
                        body: body,
                        point: intersection,
                        normal: normal,
                        distance: distance
                    )
                }
            }
        }

        return closestResult
    }

    /// Performs a ray cast and returns all bodies hit.
    ///
    /// - Parameters:
    ///   - start: The starting point of the ray.
    ///   - end: The ending point of the ray.
    /// - Returns: An array of `SNPhysicsRaycastResult` sorted by distance, or empty if no bodies are hit.
    public func raycastAll(from start: Point, to end: Point) -> [SNPhysicsRaycastResult] {
        var results: [SNPhysicsRaycastResult] = []

        for body in bodies {
            guard let node = body.node else { continue }
            let box = body.boundingBox(at: node.worldPosition)

            if let (intersection, normal) = rayIntersectsRectWithNormal(from: start, to: end, rect: box) {
                let distance = start.distance(to: intersection)
                results.append(SNPhysicsRaycastResult(
                    body: body,
                    point: intersection,
                    normal: normal,
                    distance: distance
                ))
            }
        }

        return results.sorted { $0.distance < $1.distance }
    }

    private func rayIntersectsRectWithNormal(from start: Point, to end: Point, rect: Rect) -> (Point, Vector2)? {
        let direction = Vector2(dx: end.x - start.x, dy: end.y - start.y)
        let invDir = Vector2(
            dx: direction.dx != 0 ? 1 / direction.dx : .infinity,
            dy: direction.dy != 0 ? 1 / direction.dy : .infinity
        )

        let t1 = (rect.minX - start.x) * invDir.dx
        let t2 = (rect.maxX - start.x) * invDir.dx
        let t3 = (rect.minY - start.y) * invDir.dy
        let t4 = (rect.maxY - start.y) * invDir.dy

        let tMinX = min(t1, t2)
        let tMaxX = max(t1, t2)
        let tMinY = min(t3, t4)
        let tMaxY = max(t3, t4)

        let tmin = max(tMinX, tMinY)
        let tmax = min(tMaxX, tMaxY)

        if tmax < 0 || tmin > tmax || tmin > 1 {
            return nil
        }

        let t = tmin >= 0 ? tmin : tmax
        let hitPoint = Point(
            x: start.x + direction.dx * t,
            y: start.y + direction.dy * t
        )

        // Calculate surface normal based on which face was hit
        let normal: Vector2
        if tmin == tMinX {
            // Hit left or right face
            normal = direction.dx > 0 ? Vector2(dx: -1, dy: 0) : Vector2(dx: 1, dy: 0)
        } else {
            // Hit top or bottom face
            normal = direction.dy > 0 ? Vector2(dx: 0, dy: -1) : Vector2(dx: 0, dy: 1)
        }

        return (hitPoint, normal)
    }

    // MARK: - Field Sampling

    /// Samples the combined force of all fields at the specified position.
    ///
    /// This method calculates what force would be applied to a hypothetical physics body
    /// at the given position. Useful for visualizing field effects or AI decision making.
    ///
    /// - Parameter position: The position to sample, in scene coordinates.
    /// - Returns: The combined force vector from all fields at that position.
    public func sampleFields(at position: Point) -> Vector2 {
        let fields = collectFieldNodes()
        guard !fields.isEmpty else { return .zero }

        // Create a dummy context with default values
        let context = SNFieldNode.FieldEvaluationContext(
            position: position,
            velocity: .zero,
            mass: 1.0,
            charge: 0.0,
            deltaTime: 1.0 / 60.0
        )

        var totalForce = Vector2.zero

        for field in fields {
            // Convert position to field's local space
            let fieldPosition = field.worldPosition
            let localPosition = Point(
                x: position.x - fieldPosition.x,
                y: position.y - fieldPosition.y
            )

            let localContext = SNFieldNode.FieldEvaluationContext(
                position: localPosition,
                velocity: context.velocity,
                mass: context.mass,
                charge: context.charge,
                deltaTime: context.deltaTime
            )

            let force = field.calculateForce(context: localContext)

            if field.isExclusive && !force.isZero {
                return force
            }

            totalForce = totalForce + force
        }

        return totalForce
    }

    // MARK: - Field Helpers

    /// Collects all FieldNode instances from the scene hierarchy.
    private func collectFieldNodes() -> [SNFieldNode] {
        guard let scene = scene else { return [] }

        var fields: [SNFieldNode] = []
        collectFieldNodesRecursive(from: scene, into: &fields)
        return fields
    }

    /// Recursively collects FieldNodes from a node hierarchy.
    private func collectFieldNodesRecursive(from node: SNNode, into fields: inout [SNFieldNode]) {
        if let field = node as? SNFieldNode, field.isEnabled {
            fields.append(field)
        }

        for child in node.children {
            collectFieldNodesRecursive(from: child, into: &fields)
        }
    }

    /// Calculates the total field force for a physics body at a given position.
    private func calculateFieldForce(for body: SNPhysicsBody, at position: Point, fields: [SNFieldNode], dt: Float) -> Vector2 {
        guard !fields.isEmpty else { return .zero }

        var totalForce = Vector2.zero

        for field in fields {
            // Check field category mask against body's field bit mask
            guard (field.categoryBitMask & body.fieldBitMask) != 0 else { continue }

            // Convert position to field's local space
            let fieldPosition = field.worldPosition
            let localPosition = Point(
                x: position.x - fieldPosition.x,
                y: position.y - fieldPosition.y
            )

            let context = SNFieldNode.FieldEvaluationContext(
                position: localPosition,
                velocity: body.velocity,
                mass: body.mass,
                charge: body.charge,
                deltaTime: dt
            )

            let force = field.calculateForce(context: context)

            // If field is exclusive and has effect, return immediately
            if field.isExclusive && !force.isZero {
                return force
            }

            totalForce = totalForce + force
        }

        return totalForce
    }
}
