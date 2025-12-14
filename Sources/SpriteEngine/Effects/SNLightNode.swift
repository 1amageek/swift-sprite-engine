/// A node that provides 2D lighting effects to the scene.
///
/// `SNLightNode` simulates light sources that affect sprites configured with lighting masks.
/// Lights can cast ambient light, directional light, and shadows.
///
/// ## Usage
/// ```swift
/// // Create a point light
/// let light = SNLightNode()
/// light.lightColor = .white
/// light.ambientColor = Color(white: 0.2)
/// light.falloff = 1.0
/// light.categoryBitMask = 1
/// scene.addChild(light)
///
/// // Configure a sprite to receive lighting
/// sprite.lightingBitMask = 1
/// sprite.shadowCastBitMask = 1
/// ```
///
/// ## Lighting Model
/// The lighting calculation combines:
/// - **Ambient**: Base illumination applied everywhere
/// - **Diffuse**: Light intensity based on surface angle
/// - **Shadows**: Areas blocked from the light source
public final class SNLightNode: SNNode {
    // MARK: - Enable/Disable

    /// Whether this light is currently active.
    public var isEnabled: Bool = true

    // MARK: - Category

    /// A mask defining which lighting categories this light belongs to.
    /// Sprites are only lit if their `lightingBitMask` has matching bits.
    public var categoryBitMask: UInt32 = 0xFFFFFFFF

    // MARK: - Colors

    /// The ambient color of the light.
    /// This color is applied uniformly to all affected sprites.
    public var ambientColor: Color = Color(white: 0.2, alpha: 1)

    /// The diffuse and specular color of the light source.
    /// This color affects how sprites are illuminated based on their angle to the light.
    public var lightColor: Color = .white

    /// The color of shadows cast by this light.
    public var shadowColor: Color = Color(red: 0, green: 0, blue: 0, alpha: 0.5)

    // MARK: - Falloff

    /// The exponent for the rate of light decay with distance.
    /// - 0: No falloff (constant intensity)
    /// - 1: Linear falloff
    /// - 2: Quadratic falloff (physically realistic)
    public var falloff: Float = 1.0

    // MARK: - Light Type

    /// The type of light source.
    public var lightType: LightType = .point

    /// The direction of directional lights (in radians).
    /// Only used when `lightType` is `.directional`.
    public var direction: Float = 0

    /// The cone angle for spot lights (in radians).
    /// Only used when `lightType` is `.spot`.
    public var spotAngle: Float = .pi / 4

    // MARK: - Range

    /// The maximum distance the light affects.
    /// Set to 0 for unlimited range.
    public var range: Float = 0

    // MARK: - Intensity

    /// The intensity multiplier for the light.
    public var intensity: Float = 1.0

    // MARK: - Normal Map Support

    /// Whether this light should use normal maps for per-pixel lighting.
    public var usesNormalMap: Bool = true

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    /// Creates a light with the specified color.
    ///
    /// - Parameter color: The light color.
    public init(lightColor: Color) {
        super.init()
        self.lightColor = lightColor
    }

    // MARK: - Light Calculation

    /// Calculates the light intensity at a given point.
    ///
    /// - Parameter point: The point to calculate intensity for.
    /// - Returns: The light intensity at that point (0-1).
    public func intensity(at point: Point) -> Float {
        guard isEnabled else { return 0 }

        let lightPos = worldPosition
        let dx = point.x - lightPos.x
        let dy = point.y - lightPos.y
        let distance = sqrt(dx * dx + dy * dy)

        // Check range
        if range > 0 && distance > range {
            return 0
        }

        // Calculate base intensity with falloff
        var result: Float = intensity
        if falloff > 0 && distance > 0 {
            result /= pow(distance, falloff)
        }

        // Apply spot light cone
        if lightType == .spot {
            let angleToPoint = atan2(dy, dx)
            let angleDiff = abs(normalizeAngle(angleToPoint - direction))
            if angleDiff > spotAngle / 2 {
                return 0
            }
            // Soft edge falloff for spot light
            let edgeFalloff = 1.0 - (angleDiff / (spotAngle / 2))
            result *= edgeFalloff
        }

        return min(1, max(0, result))
    }

    private func normalizeAngle(_ angle: Float) -> Float {
        var result = angle
        while result > .pi {
            result -= 2 * .pi
        }
        while result < -.pi {
            result += 2 * .pi
        }
        return result
    }
}

// MARK: - Light Type

/// The type of light source.
public enum LightType: Int, Sendable {
    /// A point light that emits in all directions.
    case point = 0

    /// A directional light with parallel rays.
    case directional = 1

    /// A spot light with a cone of illumination.
    case spot = 2
}

// MARK: - Factory Methods

extension SNLightNode {
    /// Creates a point light.
    ///
    /// - Parameters:
    ///   - color: The light color.
    ///   - intensity: The light intensity.
    ///   - falloff: The falloff exponent.
    /// - Returns: A configured point light.
    public static func pointLight(
        color: Color = .white,
        intensity: Float = 1.0,
        falloff: Float = 1.0
    ) -> SNLightNode {
        let light = SNLightNode()
        light.lightType = .point
        light.lightColor = color
        light.intensity = intensity
        light.falloff = falloff
        return light
    }

    /// Creates a directional light.
    ///
    /// - Parameters:
    ///   - color: The light color.
    ///   - direction: The light direction in radians.
    ///   - intensity: The light intensity.
    /// - Returns: A configured directional light.
    public static func directionalLight(
        color: Color = .white,
        direction: Float = -.pi / 2,
        intensity: Float = 1.0
    ) -> SNLightNode {
        let light = SNLightNode()
        light.lightType = .directional
        light.lightColor = color
        light.direction = direction
        light.intensity = intensity
        light.falloff = 0  // No distance falloff for directional lights
        return light
    }

    /// Creates a spot light.
    ///
    /// - Parameters:
    ///   - color: The light color.
    ///   - direction: The light direction in radians.
    ///   - spotAngle: The cone angle in radians.
    ///   - intensity: The light intensity.
    ///   - falloff: The falloff exponent.
    /// - Returns: A configured spot light.
    public static func spotLight(
        color: Color = .white,
        direction: Float = -.pi / 2,
        spotAngle: Float = .pi / 4,
        intensity: Float = 1.0,
        falloff: Float = 1.0
    ) -> SNLightNode {
        let light = SNLightNode()
        light.lightType = .spot
        light.lightColor = color
        light.direction = direction
        light.spotAngle = spotAngle
        light.intensity = intensity
        light.falloff = falloff
        return light
    }

    /// Creates an ambient-only light.
    ///
    /// - Parameter color: The ambient color.
    /// - Returns: A light with only ambient illumination.
    public static func ambientLight(color: Color) -> SNLightNode {
        let light = SNLightNode()
        light.ambientColor = color
        light.lightColor = .clear
        light.intensity = 0
        return light
    }
}

