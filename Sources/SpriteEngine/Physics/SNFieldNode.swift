/// A node that applies physics effects to nearby nodes.
///
/// Field nodes create forces that affect physics bodies within their region.
/// Different field types provide different effects like gravity, drag, or turbulence.
///
/// ## Platform Mapping
/// ```
/// SpriteKit                       Wisp
/// ─────────────────────────────  ─────────────────────────────
/// SKFieldNode                     FieldNode
/// dragField()                     dragField()
/// electricField()                 electricField()
/// linearGravityField(withVector:) linearGravityField(withVector:)
/// magneticField()                 magneticField()
/// noiseField(withSmoothness:...)  noiseField(withSmoothness:...)
/// radialGravityField()            radialGravityField()
/// springField()                   springField()
/// turbulenceField(withSmoothness:...) turbulenceField(withSmoothness:...)
/// velocityField(withVector:)      velocityField(withVector:)
/// velocityField(with: SKTexture)  velocityField(with: Texture)
/// vortexField()                   vortexField()
/// customField(evaluationBlock:)   customField(evaluator:)
/// isEnabled                       isEnabled
/// isExclusive                     isExclusive
/// region                          region
/// minimumRadius                   minimumRadius
/// categoryBitMask                 categoryBitMask
/// strength                        strength
/// falloff                         falloff
/// animationSpeed                  animationSpeed
/// smoothness                      smoothness
/// direction                       direction
/// texture                         texture
/// ```
///
/// ## Usage
/// ```swift
/// // Create a radial gravity field
/// let gravity = SNFieldNode.radialGravityField()
/// gravity.strength = 5.0
/// gravity.falloff = 1.0
/// scene.addChild(gravity)
///
/// // Create a drag field to slow objects
/// let drag = SNFieldNode.dragField()
/// drag.region = Region(radius: 200)
/// scene.addChild(drag)
///
/// // Create a velocity field from a texture (flow map)
/// let flowTexture = SNTexture(imageNamed: "flow.png")
/// let velocityField = SNFieldNode.velocityField(with: flowTexture)
/// scene.addChild(velocityField)
/// ```
public final class SNFieldNode: SNNode {
    // MARK: - Field Type

    /// The type of field effect.
    public enum FieldType: Sendable {
        /// Applies a force that resists motion (like air resistance).
        case drag
        /// Applies a force proportional to electrical charge.
        case electric
        /// Accelerates bodies in a specific direction.
        case linearGravity(direction: Vector2)
        /// Applies magnetic force based on velocity and charge.
        case magnetic
        /// Applies random acceleration (smooth).
        case noise(smoothness: Float, animationSpeed: Float)
        /// Accelerates bodies toward the field node.
        case radialGravity
        /// Applies a spring-like force toward the field node.
        case spring
        /// Applies random acceleration (chaotic).
        case turbulence(smoothness: Float, animationSpeed: Float)
        /// Sets velocity based on a direction.
        case velocity(direction: Vector2)
        /// Sets velocity based on a texture (flow map).
        case velocityTexture
        /// Applies perpendicular force (spinning).
        case vortex
        /// Custom force evaluation.
        case custom(evaluator: @Sendable (FieldEvaluationContext) -> Vector2)
    }

    /// Context provided to custom field evaluators.
    public struct FieldEvaluationContext: Sendable {
        /// Position of the physics body relative to the field node.
        public let position: Point
        /// Velocity of the physics body.
        public let velocity: Vector2
        /// Mass of the physics body.
        public let mass: Float
        /// Charge of the physics body.
        public let charge: Float
        /// Time since the last evaluation.
        public let deltaTime: Float
    }

    // MARK: - Properties

    /// The type of field.
    public let fieldType: FieldType

    /// Whether the field is active.
    public var isEnabled: Bool = true

    /// Whether this field overrides all other fields.
    public var isExclusive: Bool = false

    /// The region affected by the field (relative to node's origin).
    ///
    /// If nil, the field affects the entire scene.
    public var region: Region?

    /// The minimum distance for distance-based calculations.
    public var minimumRadius: Float = 0

    /// A mask defining which categories this field belongs to.
    public var categoryBitMask: UInt32 = 0xFFFFFFFF

    /// The strength of the field.
    public var strength: Float = 1.0

    /// The rate of decay for field strength with distance.
    ///
    /// - 0: No decay (uniform field)
    /// - 1: Linear decay
    /// - 2: Quadratic decay (realistic for gravity)
    public var falloff: Float = 0

    /// The animation speed for noise/turbulence fields.
    public var animationSpeed: Float = 1.0

    /// The smoothness for noise/turbulence fields.
    public var smoothness: Float = 0.5

    /// The direction vector for linear gravity and velocity fields.
    ///
    /// This property can be modified after creation to change the field direction
    /// without recreating the field node.
    public var direction: Vector2 = .zero

    /// The texture used for velocity texture fields.
    ///
    /// For velocity fields, the texture's red and green channels are interpreted
    /// as velocity directions (mapped from 0-1 to -1 to 1).
    public var texture: SNTexture?

    /// Accumulated time for animated fields (noise/turbulence).
    private var elapsedTime: Float = 0

    // MARK: - Initialization

    private init(fieldType: FieldType) {
        self.fieldType = fieldType
        super.init()
    }

    // MARK: - Factory Methods

    /// Creates a field that applies drag (air resistance).
    public static func dragField() -> SNFieldNode {
        SNFieldNode(fieldType: .drag)
    }

    /// Creates a field that applies electrical force.
    ///
    /// Electric fields follow Coulomb's law with inverse-square falloff.
    public static func electricField() -> SNFieldNode {
        let field = SNFieldNode(fieldType: .electric)
        field.falloff = 2  // Inverse square law
        return field
    }

    /// Creates a field that applies gravity in a specific direction.
    ///
    /// - Parameter direction: The gravity direction and magnitude.
    public static func linearGravityField(withVector direction: Vector2) -> SNFieldNode {
        let field = SNFieldNode(fieldType: .linearGravity(direction: direction))
        field.direction = direction
        return field
    }

    /// Creates a field that applies magnetic force.
    public static func magneticField() -> SNFieldNode {
        SNFieldNode(fieldType: .magnetic)
    }

    /// Creates a field that applies smooth random acceleration.
    ///
    /// - Parameters:
    ///   - smoothness: How smooth the noise is (0-1).
    ///   - animationSpeed: How fast the noise changes.
    public static func noiseField(withSmoothness smoothness: Float, animationSpeed: Float) -> SNFieldNode {
        let field = SNFieldNode(fieldType: .noise(smoothness: smoothness, animationSpeed: animationSpeed))
        field.smoothness = smoothness
        field.animationSpeed = animationSpeed
        return field
    }

    /// Creates a field that pulls bodies toward the field node.
    ///
    /// Radial gravity follows the inverse-square law by default.
    public static func radialGravityField() -> SNFieldNode {
        let field = SNFieldNode(fieldType: .radialGravity)
        field.falloff = 2  // Quadratic decay (realistic for gravity)
        return field
    }

    /// Creates a field that applies spring-like force.
    public static func springField() -> SNFieldNode {
        SNFieldNode(fieldType: .spring)
    }

    /// Creates a field that applies chaotic random acceleration.
    ///
    /// - Parameters:
    ///   - smoothness: How smooth the turbulence is (0-1).
    ///   - animationSpeed: How fast the turbulence changes.
    public static func turbulenceField(withSmoothness smoothness: Float, animationSpeed: Float) -> SNFieldNode {
        let field = SNFieldNode(fieldType: .turbulence(smoothness: smoothness, animationSpeed: animationSpeed))
        field.smoothness = smoothness
        field.animationSpeed = animationSpeed
        return field
    }

    /// Creates a field that sets velocity in a specific direction.
    ///
    /// - Parameter direction: The velocity direction.
    public static func velocityField(withVector direction: Vector2) -> SNFieldNode {
        let field = SNFieldNode(fieldType: .velocity(direction: direction))
        field.direction = direction
        return field
    }

    /// Creates a velocity field that uses a texture as a flow map.
    ///
    /// The texture's red channel maps to horizontal velocity and the green channel
    /// maps to vertical velocity. Values are mapped from 0-1 to -1 to 1.
    ///
    /// - Parameter texture: The flow map texture.
    public static func velocityField(with texture: SNTexture) -> SNFieldNode {
        let field = SNFieldNode(fieldType: .velocityTexture)
        field.texture = texture
        return field
    }

    /// Creates a field that applies perpendicular force (vortex/spinning).
    public static func vortexField() -> SNFieldNode {
        SNFieldNode(fieldType: .vortex)
    }

    /// Creates a field with a custom force evaluator.
    ///
    /// - Parameter evaluator: A closure that calculates the force for a physics body.
    public static func customField(evaluator: @escaping @Sendable (FieldEvaluationContext) -> Vector2) -> SNFieldNode {
        SNFieldNode(fieldType: .custom(evaluator: evaluator))
    }

    // MARK: - Time Update

    /// Updates the field's internal time for animated fields.
    ///
    /// Called by PhysicsWorld during simulation.
    ///
    /// - Parameter deltaTime: The time elapsed since the last update.
    internal func update(deltaTime: Float) {
        elapsedTime += deltaTime * animationSpeed
    }

    // MARK: - Force Calculation

    /// Calculates the force to apply to a physics body.
    ///
    /// - Parameter context: The evaluation context.
    /// - Returns: The force vector to apply.
    internal func calculateForce(context: FieldEvaluationContext) -> Vector2 {
        guard isEnabled else { return .zero }

        // Check if position is within region
        if let region = region {
            if !region.contains(context.position) {
                return .zero
            }
        }

        // Calculate distance from field center
        let distance = context.position.distance(to: .zero)

        // Calculate distance-based falloff (SpriteKit-compatible)
        let falloffMultiplier: Float
        if falloff == 0 {
            falloffMultiplier = 1.0
        } else if distance <= minimumRadius {
            falloffMultiplier = 1.0
        } else {
            // Distance beyond minimum radius
            let effectiveDistance = distance - minimumRadius
            if effectiveDistance <= 0 {
                falloffMultiplier = 1.0
            } else {
                // Inverse power law: 1 / (1 + d)^falloff
                falloffMultiplier = 1.0 / pow(1.0 + effectiveDistance, falloff)
            }
        }

        let effectiveStrength = strength * falloffMultiplier

        switch fieldType {
        case .drag:
            // Force opposes velocity (like air resistance)
            return context.velocity * (-effectiveStrength)

        case .electric:
            // Coulomb's law: F = k * q1 * q2 / r²
            // strength represents k * q_field, charge is q_body
            guard distance > minimumRadius else { return .zero }
            let toCenter = Vector2(dx: -context.position.x, dy: -context.position.y)
            let dir = toCenter.normalized
            let forceMagnitude = effectiveStrength * context.charge
            return dir * forceMagnitude

        case .linearGravity(let originalDirection):
            // Use direction property if modified, otherwise use original
            let dir = (self.direction.dx != 0 || self.direction.dy != 0) ? self.direction : originalDirection
            return dir * effectiveStrength

        case .magnetic:
            // Lorentz force: F = q * v × B
            // In 2D, B field is perpendicular to plane, so result is perpendicular to velocity
            let perpendicular = Vector2(dx: -context.velocity.dy, dy: context.velocity.dx)
            return perpendicular * (effectiveStrength * context.charge)

        case .noise:
            // Multi-octave smooth noise
            let freq1 = smoothness * 0.1
            let freq2 = smoothness * 0.23
            let freq3 = smoothness * 0.47

            let noiseX = sin(context.position.x * freq1 + elapsedTime) * 0.5
                       + sin(context.position.y * freq2 + elapsedTime * 1.3) * 0.3
                       + sin((context.position.x + context.position.y) * freq3 + elapsedTime * 0.7) * 0.2

            let noiseY = cos(context.position.y * freq1 + elapsedTime * 1.1) * 0.5
                       + cos(context.position.x * freq2 + elapsedTime * 0.9) * 0.3
                       + cos((context.position.x - context.position.y) * freq3 + elapsedTime * 1.5) * 0.2

            return Vector2(dx: noiseX, dy: noiseY) * effectiveStrength

        case .turbulence:
            // More chaotic than noise - uses multiplication of sine waves
            let turbX = sin(context.position.x * smoothness + elapsedTime * 2.0)
                      * cos(context.position.y * smoothness * 1.5 + elapsedTime)
            let turbY = cos(context.position.y * smoothness + elapsedTime * 1.7)
                      * sin(context.position.x * smoothness * 1.3 + elapsedTime * 1.2)

            return Vector2(dx: turbX, dy: turbY) * effectiveStrength

        case .radialGravity:
            // Pull bodies toward field center
            guard distance > minimumRadius else { return .zero }
            let toCenter = Vector2(dx: -context.position.x, dy: -context.position.y)
            return toCenter.normalized * effectiveStrength

        case .spring:
            // Hooke's law: F = -k * x (force proportional to displacement)
            return Vector2(dx: -context.position.x, dy: -context.position.y) * effectiveStrength

        case .velocity(let originalDirection):
            // Use direction property if modified, otherwise use original
            let dir = (self.direction.dx != 0 || self.direction.dy != 0) ? self.direction : originalDirection
            // Apply force toward target velocity
            let targetVelocity = dir * effectiveStrength
            let velocityDiff = targetVelocity - context.velocity
            return velocityDiff * effectiveStrength

        case .velocityTexture:
            // Sample velocity from texture (flow map)
            guard let tex = texture else { return .zero }

            // Calculate UV coordinates based on position within region
            let u: Float
            let v: Float
            if let region = region {
                // Map position within region to UV
                let regionSize = region.size
                u = (context.position.x + regionSize / 2) / regionSize
                v = (context.position.y + regionSize / 2) / regionSize
            } else {
                // Use position directly (normalized assuming reasonable range)
                u = (context.position.x + 500) / 1000  // Assume -500 to 500 range
                v = (context.position.y + 500) / 1000
            }

            // Sample texture color
            let color = tex.sampleColor(u: u, v: v)

            // Map R and G from [0,1] to [-1,1] for velocity direction
            let velX = (color.r * 2.0 - 1.0) * effectiveStrength
            let velY = (color.g * 2.0 - 1.0) * effectiveStrength

            // Return force to achieve target velocity
            let targetVelocity = Vector2(dx: velX, dy: velY)
            let velocityDiff = targetVelocity - context.velocity
            return velocityDiff * effectiveStrength

        case .vortex:
            // Perpendicular force for rotation (tangential to position)
            guard distance > minimumRadius else { return .zero }
            let perpendicular = Vector2(dx: -context.position.y, dy: context.position.x).normalized
            return perpendicular * effectiveStrength

        case .custom(let evaluator):
            return evaluator(context) * effectiveStrength
        }
    }
}
