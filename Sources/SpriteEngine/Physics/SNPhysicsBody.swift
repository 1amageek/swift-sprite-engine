/// A physics body that adds physical simulation to a node.
///
/// `SNPhysicsBody` provides collision detection and basic physics simulation.
/// Attach it to a `SNNode` to enable physics interactions.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKPhysicsBody                   SNPhysicsBody
/// init(circleOfRadius:)           init(circleOfRadius:)
/// init(rectangleOf:)              init(rectangleOf:)
/// init(polygonFrom:)              init(polygonFrom:)
/// init(edgeLoopFrom:)             init(edgeLoopFrom:)
/// init(edgeChainFrom:)            init(edgeChainFrom:)
/// init(bodies:)                   init(bodies:)
/// ```
///
/// ## Usage
/// ```swift
/// let player = SNSpriteNode(color: .blue, size: Size(width: 32, height: 32))
/// player.physicsBody = SNPhysicsBody(rectangleOf: player.size)
/// player.physicsBody?.categoryBitMask = 0x1
/// player.physicsBody?.collisionBitMask = 0x2
/// ```
public final class SNPhysicsBody: @unchecked Sendable {
    // MARK: - Shape

    /// The shape used for collision detection.
    public enum Shape: Sendable {
        /// A rectangular shape centered on the node's origin.
        case rectangle(Size)

        /// A rectangular shape centered on a specific point.
        case rectangleWithCenter(size: Size, center: Point)

        /// A circular shape centered on the node's origin.
        case circle(radius: Float)

        /// A circular shape centered on a specific point.
        case circleWithCenter(radius: Float, center: Point)

        /// An edge loop (static, for boundaries).
        case edgeLoop(Rect)

        /// An edge loop from a path (static boundary).
        case edgeLoopFromPath(path: [Point])

        /// An edge chain (open path, static).
        case edgeChain(path: [Point])

        /// A convex polygon shape.
        case polygon(path: [Point])

        /// A compound body made of multiple shapes.
        case compound(bodies: [SNPhysicsBody])
    }

    /// The collision shape of this body.
    public let shape: Shape

    /// The center offset for offset shapes.
    public let centerOffset: Point

    // MARK: - Physical Properties

    /// Whether this body is affected by physics forces.
    /// Static bodies (like ground) should set this to `false`.
    public var isDynamic: Bool = true

    /// Whether this body is affected by gravity.
    public var affectedByGravity: Bool = true

    /// Whether this body can rotate.
    public var allowsRotation: Bool = true

    /// The mass of the body in kilograms.
    ///
    /// When set, automatically recalculates `density` based on `area`.
    public var mass: Float = 1.0 {
        didSet {
            if area > 0 {
                _density = mass / area
            }
        }
    }

    /// The density of the object, in kilograms per square meter.
    ///
    /// When set, automatically recalculates `mass` based on `area`.
    public var density: Float {
        get { _density }
        set {
            _density = newValue
            mass = newValue * area
        }
    }
    private var _density: Float = 1.0

    /// The area covered by the body in square points.
    ///
    /// This is a read-only property calculated from the shape.
    public var area: Float {
        switch shape {
        case .rectangle(let size), .rectangleWithCenter(let size, _):
            return size.width * size.height
        case .circle(let radius), .circleWithCenter(let radius, _):
            return .pi * radius * radius
        case .edgeLoop, .edgeLoopFromPath, .edgeChain:
            return 0 // Edge bodies have no area
        case .polygon(let path):
            return calculatePolygonArea(path)
        case .compound(let bodies):
            return bodies.reduce(0) { $0 + $1.area }
        }
    }

    /// The friction coefficient (0 = frictionless, 1 = high friction).
    public var friction: Float = 0.2

    /// The restitution (bounciness, 0 = no bounce, 1 = perfect bounce).
    public var restitution: Float = 0.0

    /// Linear damping (air resistance, 0 = none).
    ///
    /// A property that reduces the body's linear velocity.
    public var linearDamping: Float = 0.1

    /// Angular damping (rotational resistance, 0 = none).
    ///
    /// A property that reduces the body's rotational velocity.
    public var angularDamping: Float = 0.1

    // MARK: - Velocity

    /// The linear velocity of the body in meters per second.
    public var velocity: Vector2 = .zero

    /// The angular velocity in radians per second.
    public var angularVelocity: Float = 0

    // MARK: - Collision Categories

    /// A mask defining the category this body belongs to.
    public var categoryBitMask: UInt32 = 0xFFFFFFFF

    /// A mask defining which categories this body collides with.
    public var collisionBitMask: UInt32 = 0xFFFFFFFF

    /// A mask defining which categories trigger contact notifications.
    public var contactTestBitMask: UInt32 = 0

    /// Whether the physics world uses continuous collision detection for this body.
    ///
    /// Enable this for fast-moving objects to prevent tunneling through thin objects.
    public var usesPreciseCollisionDetection: Bool = false

    // MARK: - Field Interaction

    /// A mask defining which categories of physics fields can exert forces on this body.
    public var fieldBitMask: UInt32 = 0xFFFFFFFF

    /// The electrical charge of the physics body.
    ///
    /// Used by electric and magnetic field nodes.
    public var charge: Float = 0.0

    // MARK: - Pinning

    /// Whether the physics body's node is pinned to its parent node.
    ///
    /// A pinned body can rotate freely around its anchor point but cannot translate.
    public var pinned: Bool = false

    // MARK: - State

    /// Whether the body is resting (not moving).
    public var isResting: Bool = false

    /// The node this body is attached to.
    public internal(set) weak var node: SNNode?

    /// The physics joints connected to this body.
    public internal(set) var joints: [SNPhysicsJoint] = []

    /// Bodies currently in contact with this body.
    internal var contactedBodies: Set<ObjectIdentifier> = []

    // MARK: - Previous Position (for CCD)

    /// Previous position for continuous collision detection.
    internal var previousPosition: Point?

    // MARK: - Initialization

    /// Creates a rectangular physics body centered on the owning node's origin.
    ///
    /// - Parameter size: The size of the rectangle.
    public init(rectangleOf size: Size) {
        self.shape = .rectangle(size)
        self.centerOffset = .zero
    }

    /// Creates a rectangular physics body centered on an arbitrary point.
    ///
    /// - Parameters:
    ///   - size: The size of the rectangle.
    ///   - center: The center point relative to the node's origin.
    public init(rectangleOf size: Size, center: Point) {
        self.shape = .rectangleWithCenter(size: size, center: center)
        self.centerOffset = center
    }

    /// Creates a circular physics body centered on the owning node's origin.
    ///
    /// - Parameter radius: The radius of the circle.
    public init(circleOfRadius radius: Float) {
        self.shape = .circle(radius: radius)
        self.centerOffset = .zero
    }

    /// Creates a circular physics body centered on an arbitrary point.
    ///
    /// - Parameters:
    ///   - radius: The radius of the circle.
    ///   - center: The center point relative to the node's origin.
    public init(circleOfRadius radius: Float, center: Point) {
        self.shape = .circleWithCenter(radius: radius, center: center)
        self.centerOffset = center
    }

    /// Creates an edge loop physics body from a rectangle (static boundary).
    ///
    /// - Parameter rect: The rectangle defining the edge loop.
    public init(edgeLoopFrom rect: Rect) {
        self.shape = .edgeLoop(rect)
        self.centerOffset = .zero
        self.isDynamic = false
        self.affectedByGravity = false
    }

    /// Creates an edge loop physics body from a path (static boundary).
    ///
    /// The path is automatically closed.
    ///
    /// - Parameter path: The points defining the edge loop.
    public init(edgeLoopFrom path: [Point]) {
        self.shape = .edgeLoopFromPath(path: path)
        self.centerOffset = .zero
        self.isDynamic = false
        self.affectedByGravity = false
    }

    /// Creates an edge chain physics body (open path, static).
    ///
    /// - Parameter path: The points defining the edge chain.
    public init(edgeChainFrom path: [Point]) {
        self.shape = .edgeChain(path: path)
        self.centerOffset = .zero
        self.isDynamic = false
        self.affectedByGravity = false
    }

    /// Creates a polygonal physics body.
    ///
    /// The path must define a convex polygon for correct collision detection.
    ///
    /// - Parameter path: The points defining the polygon vertices.
    public init(polygonFrom path: [Point]) {
        self.shape = .polygon(path: path)
        self.centerOffset = .zero
    }

    /// Creates a compound physics body from multiple bodies.
    ///
    /// - Parameter bodies: The bodies to combine.
    public init(bodies: [SNPhysicsBody]) {
        self.shape = .compound(bodies: bodies)
        self.centerOffset = .zero
        // Calculate combined mass
        self.mass = bodies.reduce(0) { $0 + $1.mass }
    }

    /// Creates a physics body with a custom shape.
    ///
    /// - Parameter shape: The shape for the physics body.
    public init(shape: Shape) {
        self.shape = shape
        switch shape {
        case .rectangleWithCenter(_, let center), .circleWithCenter(_, let center):
            self.centerOffset = center
        default:
            self.centerOffset = .zero
        }
    }

    // MARK: - Forces and Impulses

    /// Applies a force to the center of gravity of the body.
    ///
    /// Forces are applied over time. Call each frame for continuous force.
    ///
    /// - Parameter force: The force vector in Newtons.
    public func applyForce(_ force: Vector2) {
        guard isDynamic && !pinned else { return }
        let acceleration = force / mass
        velocity += acceleration
    }

    /// Applies a force to a specific point of the body.
    ///
    /// This can cause both linear and angular acceleration.
    ///
    /// - Parameters:
    ///   - force: The force vector in Newtons.
    ///   - point: The point where the force is applied, in scene coordinates.
    public func applyForce(_ force: Vector2, at point: Point) {
        guard isDynamic else { return }
        guard let node = node else { return }

        // Apply linear force (if not pinned)
        if !pinned {
            let acceleration = force / mass
            velocity += acceleration
        }

        // Apply torque from off-center force
        if allowsRotation {
            let centerOfMass = Point(
                x: node.position.x + centerOffset.x,
                y: node.position.y + centerOffset.y
            )
            let r = Vector2(dx: point.x - centerOfMass.x, dy: point.y - centerOfMass.y)
            // 2D cross product: r × F = rx * Fy - ry * Fx
            let torque = r.dx * force.dy - r.dy * force.dx
            applyTorque(torque)
        }
    }

    /// Applies torque to the body.
    ///
    /// - Parameter torque: The torque in Newton-meters.
    public func applyTorque(_ torque: Float) {
        guard isDynamic && allowsRotation else { return }
        // Simplified moment of inertia (assumes uniform density)
        let momentOfInertia = mass * area / 12.0  // Rough approximation
        if momentOfInertia > 0 {
            angularVelocity += torque / momentOfInertia
        }
    }

    /// Applies an impulse to the center of gravity of the body.
    ///
    /// Impulses are instantaneous changes in momentum.
    ///
    /// - Parameter impulse: The impulse vector in Newton-seconds.
    public func applyImpulse(_ impulse: Vector2) {
        guard isDynamic && !pinned else { return }
        velocity += impulse / mass
    }

    /// Applies an impulse to a specific point of the body.
    ///
    /// This can cause both linear and angular velocity changes.
    ///
    /// - Parameters:
    ///   - impulse: The impulse vector in Newton-seconds.
    ///   - point: The point where the impulse is applied, in scene coordinates.
    public func applyImpulse(_ impulse: Vector2, at point: Point) {
        guard isDynamic else { return }
        guard let node = node else { return }

        // Apply linear impulse (if not pinned)
        if !pinned {
            velocity += impulse / mass
        }

        // Apply angular impulse from off-center impulse
        if allowsRotation {
            let centerOfMass = Point(
                x: node.position.x + centerOffset.x,
                y: node.position.y + centerOffset.y
            )
            let r = Vector2(dx: point.x - centerOfMass.x, dy: point.y - centerOfMass.y)
            // 2D cross product: r × impulse
            let angularImpulse = r.dx * impulse.dy - r.dy * impulse.dx
            applyAngularImpulse(angularImpulse)
        }
    }

    /// Applies an impulse that imparts angular momentum to the body.
    ///
    /// - Parameter impulse: The angular impulse in Newton-meter-seconds.
    public func applyAngularImpulse(_ impulse: Float) {
        guard isDynamic && allowsRotation else { return }
        let momentOfInertia = mass * area / 12.0
        if momentOfInertia > 0 {
            angularVelocity += impulse / momentOfInertia
        }
    }

    // MARK: - Contact Queries

    /// Returns all physics bodies that this body is currently in contact with.
    ///
    /// - Returns: An array of physics bodies in contact.
    public func allContactedBodies() -> [SNPhysicsBody] {
        guard let node = node, let scene = node.scene else { return [] }
        return scene.physicsWorld.bodiesInContact(with: self)
    }

    // MARK: - Bounding Box

    /// Returns the axis-aligned bounding box for collision detection.
    ///
    /// - Parameter position: The world position to calculate the bounding box at.
    /// - Returns: The axis-aligned bounding box.
    public func boundingBox(at position: Point) -> Rect {
        let effectivePosition = Point(
            x: position.x + centerOffset.x,
            y: position.y + centerOffset.y
        )

        switch shape {
        case .rectangle(let size), .rectangleWithCenter(let size, _):
            return Rect(
                x: effectivePosition.x - size.width / 2,
                y: effectivePosition.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        case .circle(let radius), .circleWithCenter(let radius, _):
            return Rect(
                x: effectivePosition.x - radius,
                y: effectivePosition.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        case .edgeLoop(let rect):
            return rect
        case .edgeLoopFromPath(let path), .edgeChain(let path), .polygon(let path):
            return calculatePathBoundingBox(path, at: position)
        case .compound(let bodies):
            var combinedBox: Rect?
            for body in bodies {
                let box = body.boundingBox(at: position)
                if let existing = combinedBox {
                    combinedBox = existing.union(box)
                } else {
                    combinedBox = box
                }
            }
            return combinedBox ?? Rect(x: position.x, y: position.y, width: 0, height: 0)
        }
    }

    /// Returns the half-size of the bounding box (for CCD calculations).
    internal var boundingBoxHalfSize: Size {
        switch shape {
        case .rectangle(let size), .rectangleWithCenter(let size, _):
            return Size(width: size.width / 2, height: size.height / 2)
        case .circle(let radius), .circleWithCenter(let radius, _):
            return Size(width: radius, height: radius)
        case .edgeLoop(let rect):
            return Size(width: rect.size.width / 2, height: rect.size.height / 2)
        case .edgeLoopFromPath(let path), .edgeChain(let path), .polygon(let path):
            guard !path.isEmpty else { return Size(width: 0, height: 0) }
            var minX = path[0].x
            var maxX = path[0].x
            var minY = path[0].y
            var maxY = path[0].y
            for point in path {
                minX = min(minX, point.x)
                maxX = max(maxX, point.x)
                minY = min(minY, point.y)
                maxY = max(maxY, point.y)
            }
            return Size(width: (maxX - minX) / 2, height: (maxY - minY) / 2)
        case .compound(let bodies):
            var maxWidth: Float = 0
            var maxHeight: Float = 0
            for body in bodies {
                let half = body.boundingBoxHalfSize
                maxWidth = max(maxWidth, half.width)
                maxHeight = max(maxHeight, half.height)
            }
            return Size(width: maxWidth, height: maxHeight)
        }
    }

    // MARK: - Helper Methods

    private func calculatePolygonArea(_ path: [Point]) -> Float {
        guard path.count >= 3 else { return 0 }
        var area: Float = 0
        let n = path.count
        for i in 0..<n {
            let j = (i + 1) % n
            area += path[i].x * path[j].y
            area -= path[j].x * path[i].y
        }
        return abs(area) / 2
    }

    private func calculatePathBoundingBox(_ path: [Point], at position: Point) -> Rect {
        guard !path.isEmpty else {
            return Rect(x: position.x, y: position.y, width: 0, height: 0)
        }

        var minX = path[0].x
        var maxX = path[0].x
        var minY = path[0].y
        var maxY = path[0].y

        for point in path {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return Rect(
            x: position.x + minX,
            y: position.y + minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}

// MARK: - Convenience Factory Methods

extension SNPhysicsBody {
    /// Creates a physics body sized to match a sprite.
    ///
    /// - Parameter sprite: The sprite to match.
    /// - Returns: A physics body matching the sprite's size.
    public static func body(for sprite: SNSpriteNode) -> SNPhysicsBody {
        SNPhysicsBody(rectangleOf: sprite.size)
    }

    /// Creates a static (non-moving) rectangular body.
    ///
    /// - Parameter size: The size of the rectangle.
    /// - Returns: A static physics body.
    public static func staticBody(rectangleOf size: Size) -> SNPhysicsBody {
        let body = SNPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.affectedByGravity = false
        return body
    }

    /// Creates a static circular body.
    ///
    /// - Parameter radius: The radius of the circle.
    /// - Returns: A static physics body.
    public static func staticBody(circleOfRadius radius: Float) -> SNPhysicsBody {
        let body = SNPhysicsBody(circleOfRadius: radius)
        body.isDynamic = false
        body.affectedByGravity = false
        return body
    }

    /// Creates a static polygon body.
    ///
    /// - Parameter path: The polygon vertices.
    /// - Returns: A static physics body.
    public static func staticBody(polygonFrom path: [Point]) -> SNPhysicsBody {
        let body = SNPhysicsBody(polygonFrom: path)
        body.isDynamic = false
        body.affectedByGravity = false
        return body
    }
}

// MARK: - Joint Management (Internal)

extension SNPhysicsBody {
    /// Adds a joint to this body's joint list.
    internal func addJoint(_ joint: SNPhysicsJoint) {
        if !joints.contains(where: { $0 === joint }) {
            joints.append(joint)
        }
    }

    /// Removes a joint from this body's joint list.
    internal func removeJoint(_ joint: SNPhysicsJoint) {
        joints.removeAll { $0 === joint }
    }
}
