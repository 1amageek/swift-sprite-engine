/// A node that automatically creates and renders particle effects.
///
/// `SNEmitterNode` generates small particle sprites that simulate effects like
/// fire, smoke, sparks, snow, and other visual phenomena. Particles are
/// managed internally and cannot be accessed individually.
///
/// ## Usage
/// ```swift
/// // Create a fire emitter
/// let fire = SNEmitterNode()
/// fire.particleTexture = fireTexture
/// fire.particleBirthRate = 100
/// fire.particleLifetime = 2.0
/// fire.particleSpeed = 50
/// fire.emissionAngle = .pi / 2  // Upward
/// fire.emissionAngleRange = .pi / 4
/// fire.particleColor = .orange
/// fire.particleColorBlendFactor = 1.0
/// fire.particleAlphaSpeed = -0.5
/// scene.addChild(fire)
/// ```
///
/// ## Animating Particles
/// You can animate particles in two ways:
///
/// ### Using Keyframe Sequences
/// ```swift
/// let scaleSequence = SNKeyframeSequence(
///     floatValues: [0.2, 0.7, 0.1],
///     times: [0.0, 0.25, 0.75]
/// )
/// emitter.particleScaleSequence = scaleSequence
/// ```
///
/// ### Using Particle Actions
/// ```swift
/// let textures = (0..<8).map { SNTexture(imageNamed: "explosion_\($0)") }
/// emitter.particleAction = SNAction.animate(with: textures, timePerFrame: 0.05)
/// ```
public final class SNEmitterNode: SNNode {
    // MARK: - Particle Birth Rate

    /// The rate at which new particles are created, in particles per second.
    public var particleBirthRate: CGFloat = 0

    /// The maximum number of particles to emit before stopping.
    /// Set to 0 for unlimited particles.
    public var numParticlesToEmit: Int = 0

    // MARK: - Particle Lifetime

    /// The average lifetime of a particle in seconds.
    public var particleLifetime: CGFloat = 1.0

    /// The range of random values for particle lifetime.
    public var particleLifetimeRange: CGFloat = 0

    // MARK: - Particle Position

    /// The average starting position for particles relative to this node.
    public var particlePosition: Point = .zero

    /// The range of random values for particle starting position.
    public var particlePositionRange: Size = .zero

    /// The average starting z-position for particles.
    public var particleZPosition: CGFloat = 0

    /// The range of random values for particle z-position.
    public var particleZPositionRange: CGFloat = 0

    /// The speed at which the particle's depth changes per second.
    public var particleZPositionSpeed: CGFloat = 0

    // MARK: - Particle Velocity

    /// The average initial speed of particles in points per second.
    public var particleSpeed: CGFloat = 0

    /// The range of random values for particle speed.
    public var particleSpeedRange: CGFloat = 0

    /// The average initial direction of particles in radians.
    public var emissionAngle: CGFloat = 0

    /// The range of random values for emission angle in radians.
    public var emissionAngleRange: CGFloat = 0

    /// The acceleration applied to particles in the x direction.
    public var xAcceleration: CGFloat = 0

    /// The acceleration applied to particles in the y direction.
    public var yAcceleration: CGFloat = 0

    // MARK: - Particle Rotation

    /// The average initial rotation of particles in radians.
    public var particleRotation: CGFloat = 0

    /// The range of random values for particle rotation.
    public var particleRotationRange: CGFloat = 0

    /// The speed at which particles rotate in radians per second.
    public var particleRotationSpeed: CGFloat = 0

    // MARK: - Particle Scale

    /// The average initial scale of particles.
    public var particleScale: CGFloat = 1.0

    /// The range of random values for particle scale.
    public var particleScaleRange: CGFloat = 0

    /// The rate at which particle scale changes per second.
    public var particleScaleSpeed: CGFloat = 0

    /// The sequence used to specify the scale factor of a particle over its lifetime.
    ///
    /// When set, this sequence replaces the normal scale simulation (particleScale,
    /// particleScaleRange, particleScaleSpeed) with keyframe-based animation.
    public var particleScaleSequence: SNKeyframeSequence?

    // MARK: - Particle Texture and Size

    /// The texture used to render particles.
    public var particleTexture: SNTexture?

    /// The size of each particle in points.
    public var particleSize: Size = Size(width: 8, height: 8)

    // MARK: - Particle Color

    /// The average initial color of particles.
    public var particleColor: Color = .white

    /// The range of random values for the red component.
    public var particleColorRedRange: CGFloat = 0

    /// The range of random values for the green component.
    public var particleColorGreenRange: CGFloat = 0

    /// The range of random values for the blue component.
    public var particleColorBlueRange: CGFloat = 0

    /// The range of random values for the alpha component.
    public var particleColorAlphaRange: CGFloat = 0

    /// The rate at which the red component changes per second.
    public var particleColorRedSpeed: CGFloat = 0

    /// The rate at which the green component changes per second.
    public var particleColorGreenSpeed: CGFloat = 0

    /// The rate at which the blue component changes per second.
    public var particleColorBlueSpeed: CGFloat = 0

    /// The rate at which the alpha component changes per second.
    public var particleColorAlphaSpeed: CGFloat = 0

    /// The sequence used to specify the color components of a particle over its lifetime.
    ///
    /// When set, this sequence replaces the normal color simulation with keyframe-based animation.
    public var particleColorSequence: SNKeyframeSequence?

    // MARK: - Color Blending

    /// The amount of color blending with the texture.
    public var particleColorBlendFactor: CGFloat = 0

    /// The range of random values for color blend factor.
    public var particleColorBlendFactorRange: CGFloat = 0

    /// The rate at which color blend factor changes per second.
    public var particleColorBlendFactorSpeed: CGFloat = 0

    /// The sequence used to specify the color blend factor of a particle over its lifetime.
    public var particleColorBlendFactorSequence: SNKeyframeSequence?

    // MARK: - Alpha

    /// The average initial alpha value of particles.
    public var particleAlpha: CGFloat = 1.0

    /// The range of random values for particle alpha.
    public var particleAlphaRange: CGFloat = 0

    /// The rate at which particle alpha changes per second.
    public var particleAlphaSpeed: CGFloat = 0

    /// The sequence used to specify the alpha value of a particle over its lifetime.
    ///
    /// When set, this sequence replaces the normal alpha simulation with keyframe-based animation.
    public var particleAlphaSequence: SNKeyframeSequence?

    // MARK: - Blending

    /// The blend mode used when rendering particles.
    public var particleBlendMode: SNBlendMode = .alpha

    // MARK: - Render Order

    /// The order in which particles are rendered.
    public var particleRenderOrder: SNParticleRenderOrder = .oldestFirst

    // MARK: - Target Node

    /// The node in the scene that renders the emitter's particles.
    /// When set, particles are rendered relative to this node instead of the emitter.
    public weak var targetNode: SNNode?

    // MARK: - Physics

    /// A mask defining which physics fields affect the particles.
    public var fieldBitMask: UInt32 = 0xFFFFFFFF

    // MARK: - Shader

    /// A custom shader for rendering particles.
    public var shader: SNShader?

    /// Per-node attribute values for the shader.
    public var attributeValues: [String: SNAttributeValue] = [:]

    // MARK: - Particle Action

    /// An action executed by new particles.
    ///
    /// Although you do not have direct access to the particles created by SpriteEngine,
    /// you can specify an action that all particles execute. Whenever a new particle is
    /// created, the emitter tells the particle to run that action.
    ///
    /// You can use actions to create sophisticated behaviors, such as animating the
    /// particle's textures:
    ///
    /// ```swift
    /// let textures = (0..<8).map { SNTexture(imageNamed: "explosion_\($0)") }
    /// emitter.particleAction = SNAction.animate(with: textures, timePerFrame: 0.05)
    /// ```
    public var particleAction: SNAction?

    // MARK: - Internal State

    /// Whether the emitter's particle simulation is paused.
    ///
    /// When paused, no new particles are emitted and existing particles are not updated.
    /// Use `advanceSimulationTime(_:)` to manually advance the simulation while paused.
    public var isPaused: Bool = false

    private var particles: [Particle] = []
    private var totalParticlesEmitted: Int = 0
    private var timeSinceLastEmission: CGFloat = 0
    private var isEmitting: Bool = true

    /// Reusable proxy node for action evaluation (avoids per-frame allocation)
    private lazy var actionProxyNode: ParticleProxyNode = ParticleProxyNode()

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Simulation Control

    /// Advances the particle simulation by the specified time.
    ///
    /// Use this method to prepopulate an emitter with particles when it is first
    /// added to a scene. This is useful for effects like smoke or snow that should
    /// already be visible when they appear.
    ///
    /// - Parameter time: The time interval to advance.
    public func advanceSimulationTime(_ time: CGFloat) {
        // If paused, temporarily unpause
        let wasPaused = isPaused
        if wasPaused {
            isPaused = false
        }

        let steps = Int(time / (1.0 / 60.0))
        let dt: CGFloat = 1.0 / 60.0
        for _ in 0..<steps {
            updateParticles(deltaTime: dt)
        }

        if wasPaused {
            isPaused = true
        }
    }

    /// Removes all particles and restarts the simulation.
    public func resetSimulation() {
        particles.removeAll()
        totalParticlesEmitted = 0
        timeSinceLastEmission = 0
        isEmitting = true
    }

    // MARK: - Update

    /// Updates the particle system.
    ///
    /// - Parameter deltaTime: The time since the last update.
    public func updateParticles(deltaTime: CGFloat) {
        // Don't update if paused
        if isPaused { return }

        // Emit new particles
        if isEmitting && particleBirthRate > 0 {
            timeSinceLastEmission += deltaTime
            let emissionInterval = 1.0 / particleBirthRate

            while timeSinceLastEmission >= emissionInterval {
                if numParticlesToEmit > 0 && totalParticlesEmitted >= numParticlesToEmit {
                    isEmitting = false
                    break
                }

                emitParticle()
                totalParticlesEmitted += 1
                timeSinceLastEmission -= emissionInterval
            }
        }

        // Update existing particles
        var i = 0
        while i < particles.count {
            var particle = particles[i]
            particle.age += deltaTime

            if particle.age >= particle.lifetime {
                particles.remove(at: i)
                continue
            }

            // Calculate normalized lifetime progress (0.0 to 1.0)
            let progress = particle.age / particle.lifetime

            // ============================================
            // STEP 1: Evaluate particle action
            // ============================================
            // Per SpriteKit docs: "you can treat the particle as if it were a normal node"
            // Actions can modify any property. Sequences will override later if set.
            if let action = particle.action, !particle.actionComplete {
                // Set up the proxy node with current particle state
                actionProxyNode.texture = particle.texture
                actionProxyNode.position = particle.position
                actionProxyNode.rotation = particle.rotation
                actionProxyNode.scale = Size(width: particle.scale, height: particle.scale)
                actionProxyNode.alpha = particle.alpha
                actionProxyNode.color = particle.color
                actionProxyNode.colorBlendFactor = particle.colorBlendFactor
                actionProxyNode.size = particle.size ?? particleSize

                // Evaluate the action
                let completed = action.evaluate(on: actionProxyNode, dt: deltaTime)

                // Copy back ALL action-modified properties
                // Keyframe sequences will override specific properties in STEP 3
                particle.texture = actionProxyNode.texture
                particle.size = actionProxyNode.size
                particle.scale = actionProxyNode.scale.width
                particle.alpha = actionProxyNode.alpha
                particle.color = actionProxyNode.color
                particle.colorBlendFactor = actionProxyNode.colorBlendFactor
                particle.rotation = actionProxyNode.rotation
                // Note: position is NOT copied - velocity-based movement handles position

                if completed {
                    particle.actionComplete = true
                }
            }

            // ============================================
            // STEP 2: Apply physics simulation
            // ============================================
            // Velocity-based movement (always additive, independent of actions)
            particle.velocity.x += xAcceleration * deltaTime
            particle.velocity.y += yAcceleration * deltaTime
            particle.position.x += particle.velocity.x * deltaTime
            particle.position.y += particle.velocity.y * deltaTime

            // Z position speed (always applied)
            particle.zPosition += particleZPositionSpeed * deltaTime

            // Rotation speed (only when action is not controlling rotation)
            // If action is running and modifying rotation, don't apply rotationSpeed
            if particle.actionComplete {
                particle.rotation += particle.rotationSpeed * deltaTime
            }

            // ============================================
            // STEP 3: Apply keyframe sequences (override)
            // ============================================
            // Per SpriteKit docs: "The sequence REPLACES the normal simulation"
            // Sequences have highest priority and override both actions and speed-based changes.

            // Scale: Sequence > Action > Speed-based
            if let scaleSequence = particleScaleSequence {
                particle.scale = scaleSequence.sampleCGFloat(atTime: progress)
            } else if particle.actionComplete && particleScaleSpeed != 0 {
                // Speed-based only applies when action is complete (action controls while running)
                particle.scale += particleScaleSpeed * deltaTime
            }

            // Color: Sequence > Action > Speed-based
            if let colorSequence = particleColorSequence {
                particle.color = colorSequence.sampleColor(atTime: progress)
            } else if particle.actionComplete &&
                      (particleColorRedSpeed != 0 || particleColorGreenSpeed != 0 ||
                       particleColorBlueSpeed != 0 || particleColorAlphaSpeed != 0) {
                particle.color = Color(
                    red: particle.color.red + particleColorRedSpeed * deltaTime,
                    green: particle.color.green + particleColorGreenSpeed * deltaTime,
                    blue: particle.color.blue + particleColorBlueSpeed * deltaTime,
                    alpha: particle.color.alpha + particleColorAlphaSpeed * deltaTime
                )
            }

            // Alpha: Sequence > Action > Speed-based
            if let alphaSequence = particleAlphaSequence {
                particle.alpha = alphaSequence.sampleCGFloat(atTime: progress)
            } else if particle.actionComplete && particleAlphaSpeed != 0 {
                particle.alpha += particleAlphaSpeed * deltaTime
            }
            particle.alpha = max(0, min(1, particle.alpha))

            // Color blend factor: Sequence > Action > Speed-based
            if let blendSequence = particleColorBlendFactorSequence {
                particle.colorBlendFactor = blendSequence.sampleCGFloat(atTime: progress)
            } else if particle.actionComplete && particleColorBlendFactorSpeed != 0 {
                particle.colorBlendFactor += particleColorBlendFactorSpeed * deltaTime
            }
            particle.colorBlendFactor = max(0, min(1, particle.colorBlendFactor))

            particles[i] = particle
            i += 1
        }
    }

    // MARK: - Particle Emission

    private func emitParticle() {
        var particle = Particle()

        // Position
        particle.position = Point(
            x: particlePosition.x + randomRange(-particlePositionRange.width / 2, particlePositionRange.width / 2),
            y: particlePosition.y + randomRange(-particlePositionRange.height / 2, particlePositionRange.height / 2)
        )

        // Lifetime
        particle.lifetime = particleLifetime + randomRange(-particleLifetimeRange / 2, particleLifetimeRange / 2)
        particle.lifetime = max(0.001, particle.lifetime)

        // Velocity
        let speed = particleSpeed + randomRange(-particleSpeedRange / 2, particleSpeedRange / 2)
        let angle = emissionAngle + randomRange(-emissionAngleRange / 2, emissionAngleRange / 2)
        particle.velocity = Point(
            x: cos(angle) * speed,
            y: sin(angle) * speed
        )

        // Rotation
        particle.rotation = particleRotation + randomRange(-particleRotationRange / 2, particleRotationRange / 2)
        particle.rotationSpeed = particleRotationSpeed

        // Scale (use sequence start value if available)
        if let scaleSequence = particleScaleSequence {
            particle.scale = scaleSequence.sampleCGFloat(atTime: 0)
        } else {
            particle.scale = particleScale + randomRange(-particleScaleRange / 2, particleScaleRange / 2)
        }

        // Color (use sequence start value if available)
        if let colorSequence = particleColorSequence {
            particle.color = colorSequence.sampleColor(atTime: 0)
        } else {
            particle.color = Color(
                red: particleColor.red + randomRange(-particleColorRedRange / 2, particleColorRedRange / 2),
                green: particleColor.green + randomRange(-particleColorGreenRange / 2, particleColorGreenRange / 2),
                blue: particleColor.blue + randomRange(-particleColorBlueRange / 2, particleColorBlueRange / 2),
                alpha: particleColor.alpha + randomRange(-particleColorAlphaRange / 2, particleColorAlphaRange / 2)
            )
        }

        // Alpha (use sequence start value if available)
        if let alphaSequence = particleAlphaSequence {
            particle.alpha = alphaSequence.sampleCGFloat(atTime: 0)
        } else {
            particle.alpha = particleAlpha + randomRange(-particleAlphaRange / 2, particleAlphaRange / 2)
        }
        particle.alpha = max(0, min(1, particle.alpha))

        // Color blend factor (use sequence start value if available)
        if let blendSequence = particleColorBlendFactorSequence {
            particle.colorBlendFactor = blendSequence.sampleCGFloat(atTime: 0)
        } else {
            particle.colorBlendFactor = particleColorBlendFactor + randomRange(-particleColorBlendFactorRange / 2, particleColorBlendFactorRange / 2)
        }
        particle.colorBlendFactor = max(0, min(1, particle.colorBlendFactor))

        // Z position
        particle.zPosition = particleZPosition + randomRange(-particleZPositionRange / 2, particleZPositionRange / 2)

        // Copy the texture
        particle.texture = particleTexture

        // Copy the action (if any)
        if let action = particleAction {
            particle.action = action.copy()
            particle.actionComplete = false
        }

        particles.append(particle)
    }

    private func randomRange(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        CGFloat.random(in: min...max)
    }

    // MARK: - Draw Commands

    /// Generates draw commands for all particles.
    ///
    /// - Returns: An array of draw commands.
    internal func generateDrawCommands() -> [DrawCommand] {
        var commands: [DrawCommand] = []

        let basePosition = targetNode?.worldPosition ?? worldPosition
        let baseRotation = targetNode?.worldRotation ?? worldRotation
        let baseScale = targetNode?.worldScale ?? worldScale
        let baseAlpha = targetNode?.worldAlpha ?? worldAlpha

        let sortedParticles: [Particle]
        switch particleRenderOrder {
        case .oldestFirst:
            sortedParticles = particles
        case .oldestLast:
            sortedParticles = particles.reversed()
        case .dontCare:
            sortedParticles = particles
        }

        for particle in sortedParticles {
            let particleWorldPos = Point(
                x: basePosition.x + particle.position.x * baseScale.width,
                y: basePosition.y + particle.position.y * baseScale.height
            )

            let particleRotation = baseRotation + particle.rotation

            let particleScale = Size(
                width: baseScale.width * particle.scale,
                height: baseScale.height * particle.scale
            )

            // Use particle's size if set (by action), otherwise use emitter's particleSize
            let renderSize = particle.size ?? particleSize

            // Apply color blending
            var finalColor = particle.color
            if particle.colorBlendFactor > 0 {
                finalColor = Color(
                    red: finalColor.red * (1 - particle.colorBlendFactor) + particleColor.red * particle.colorBlendFactor,
                    green: finalColor.green * (1 - particle.colorBlendFactor) + particleColor.green * particle.colorBlendFactor,
                    blue: finalColor.blue * (1 - particle.colorBlendFactor) + particleColor.blue * particle.colorBlendFactor,
                    alpha: finalColor.alpha
                )
            }

            // Use particle's texture (may have been changed by action)
            let texture = particle.texture ?? particleTexture

            let command = DrawCommand(
                worldPosition: particleWorldPos,
                worldRotation: particleRotation,
                worldScale: particleScale,
                size: renderSize,
                anchorPoint: Point(x: 0.5, y: 0.5),
                textureID: texture?.textureID ?? .none,
                textureRect: texture?.textureRect() ?? Rect(x: 0, y: 0, width: 1, height: 1),
                filteringMode: texture?.filteringMode ?? .linear,
                usesMipmaps: texture?.usesMipmaps ?? false,
                color: finalColor,
                alpha: baseAlpha * particle.alpha,
                zPosition: zPosition + particle.zPosition
            )
            commands.append(command)
        }

        return commands
    }

    // MARK: - Particle Count

    /// The current number of active particles.
    public var particleCount: Int {
        particles.count
    }
}

// MARK: - Particle

/// Internal representation of a single particle.
private struct Particle {
    var position: Point = .zero
    var velocity: Point = .zero
    var rotation: CGFloat = 0
    var rotationSpeed: CGFloat = 0
    var scale: CGFloat = 1
    var color: Color = .white
    var alpha: CGFloat = 1
    var colorBlendFactor: CGFloat = 0
    var zPosition: CGFloat = 0
    var age: CGFloat = 0
    var lifetime: CGFloat = 1

    // Size (can be changed by action, defaults to emitter's particleSize)
    var size: Size?

    // Texture (can be changed by action)
    var texture: SNTexture?

    // Action state
    var action: Action?
    var actionComplete: Bool = true
}

// MARK: - ParticleProxyNode

/// A lightweight proxy node used to apply actions to particles.
///
/// This internal class provides a minimal node-like interface that actions
/// can operate on, without the overhead of a full SNNode.
internal final class ParticleProxyNode: SNSpriteNode {
    // SNSpriteNode already has all the properties we need:
    // - texture, color, colorBlendFactor, size, alpha
    // - position, rotation, scale (from SNNode)

    override init() {
        super.init(color: .white, size: .zero)
    }
}

// MARK: - Preset Emitters

extension SNEmitterNode {
    /// Creates a fire effect emitter.
    public static func fire() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 200
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 6
        emitter.particleSize = Size(width: 16, height: 16)
        emitter.particleColor = Color(red: 1, green: 0.6, blue: 0.1, alpha: 1)
        emitter.particleColorRedSpeed = -0.3
        emitter.particleColorGreenSpeed = -0.5
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 1.0
        emitter.particleScaleSpeed = -0.5
        emitter.yAcceleration = 20
        emitter.particleBlendMode = .add
        return emitter
    }

    /// Creates a smoke effect emitter.
    public static func smoke() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 50
        emitter.particleLifetime = 3.0
        emitter.particleLifetimeRange = 1.0
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 8
        emitter.particleSize = Size(width: 32, height: 32)
        emitter.particleColor = Color(white: 0.5, alpha: 0.3)
        emitter.particleAlpha = 0.3
        emitter.particleAlphaSpeed = -0.1
        emitter.particleScale = 0.5
        emitter.particleScaleSpeed = 0.3
        emitter.yAcceleration = 10
        emitter.particleBlendMode = .alpha
        return emitter
    }

    /// Creates a spark effect emitter.
    public static func sparks() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 300
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.3
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSize = Size(width: 4, height: 4)
        emitter.particleColor = Color(red: 1, green: 0.9, blue: 0.5, alpha: 1)
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        emitter.yAcceleration = -200
        emitter.particleBlendMode = .add
        return emitter
    }

    /// Creates a snow effect emitter.
    public static func snow() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 100
        emitter.particleLifetime = 5.0
        emitter.particleLifetimeRange = 2.0
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 6
        emitter.particlePositionRange = Size(width: 400, height: 0)
        emitter.particleSize = Size(width: 8, height: 8)
        emitter.particleColor = .white
        emitter.particleAlpha = 0.8
        emitter.particleAlphaRange = 0.2
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.5
        emitter.xAcceleration = 10
        emitter.particleBlendMode = .alpha
        return emitter
    }

    /// Creates a rain effect emitter.
    public static func rain() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 500
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3
        emitter.particleSpeed = 400
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = -.pi / 2 - 0.1
        emitter.emissionAngleRange = 0.05
        emitter.particlePositionRange = Size(width: 500, height: 0)
        emitter.particleSize = Size(width: 2, height: 16)
        emitter.particleColor = Color(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.6)
        emitter.particleBlendMode = .alpha
        return emitter
    }

    /// Creates an explosion effect emitter.
    ///
    /// - Parameter particleCount: The number of particles in the explosion.
    public static func explosion(particleCount: Int = 100) -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = CGFloat(particleCount) * 10
        emitter.numParticlesToEmit = particleCount
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSize = Size(width: 12, height: 12)
        emitter.particleColor = Color(red: 1, green: 0.8, blue: 0.3, alpha: 1)
        emitter.particleColorRedSpeed = -0.5
        emitter.particleColorGreenSpeed = -1.0
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 1.5
        emitter.particleScaleSpeed = -1.0
        emitter.yAcceleration = -50
        emitter.particleBlendMode = .add
        return emitter
    }

    /// Creates a magic sparkle effect emitter.
    public static func magic() -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = 80
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSize = Size(width: 8, height: 8)
        emitter.particleColor = Color(red: 0.8, green: 0.6, blue: 1.0, alpha: 1)
        emitter.particleColorRedRange = 0.2
        emitter.particleColorGreenRange = 0.2
        emitter.particleColorBlueRange = 0.2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.7
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.3
        emitter.particleBlendMode = .add
        return emitter
    }

    /// Creates an animated explosion emitter using particle actions.
    ///
    /// This demonstrates the use of `particleAction` for texture animation.
    ///
    /// - Parameters:
    ///   - textures: An array of textures for the explosion animation.
    ///   - timePerFrame: The duration for each frame of the animation.
    ///   - particleCount: The number of particles to emit.
    public static func animatedExplosion(
        textures: [SNTexture],
        timePerFrame: CGFloat = 0.05,
        particleCount: Int = 20
    ) -> SNEmitterNode {
        let emitter = SNEmitterNode()
        emitter.particleBirthRate = CGFloat(particleCount) * 5
        emitter.numParticlesToEmit = particleCount
        emitter.particleLifetime = CGFloat(textures.count) * timePerFrame + 0.1
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSize = Size(width: 32, height: 32)
        emitter.particleTexture = textures.first
        emitter.particleAction = SNAction.animate(with: textures, timePerFrame: timePerFrame, resize: false, restore: false)
        emitter.particleBlendMode = .add
        return emitter
    }
}
