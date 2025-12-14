/// A custom shader program for rendering nodes.
///
/// `Shader` allows you to apply custom visual effects to sprites and other nodes
/// using WGSL (WebGPU Shading Language) shader code. Shaders can have uniforms
/// (shared data) and attributes (per-node data).
///
/// ## Usage
/// ```swift
/// // Create a simple color-shift shader
/// let shaderSource = """
/// @fragment
/// fn main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
///     let color = textureSample(texture, sampler, uv);
///     return vec4<f32>(color.r * u_tint.r, color.g * u_tint.g, color.b * u_tint.b, color.a);
/// }
/// """
///
/// let shader = Shader(source: shaderSource)
/// shader.addUniform(Uniform(name: "u_tint", float4: (1.0, 0.5, 0.0, 1.0)))
///
/// sprite.shader = shader
/// ```
///
/// ## Uniforms vs Attributes
/// - **Uniforms**: Shared across all nodes using this shader. Changed per-frame or per-draw-call.
/// - **Attributes**: Per-node data. Each node can have different values.
public final class Shader {
    /// An optional name for identifying this shader.
    public var name: String?

    /// The WGSL shader source code.
    public let source: String

    /// The uniforms used by this shader.
    public private(set) var uniforms: [Uniform]

    /// The attributes defined by this shader.
    public private(set) var attributes: [ShaderAttribute]

    // MARK: - Initialization

    /// Creates a shader with source code.
    ///
    /// - Parameter source: The WGSL shader source code.
    public init(source: String) {
        self.name = nil
        self.source = source
        self.uniforms = []
        self.attributes = []
    }

    /// Creates a shader with source code and uniforms.
    ///
    /// - Parameters:
    ///   - source: The WGSL shader source code.
    ///   - uniforms: The uniforms to include.
    public init(source: String, uniforms: [Uniform]) {
        self.name = nil
        self.source = source
        self.uniforms = uniforms
        self.attributes = []
    }

    /// Creates a shader with source code, uniforms, and attributes.
    ///
    /// - Parameters:
    ///   - source: The WGSL shader source code.
    ///   - uniforms: The uniforms to include.
    ///   - attributes: The per-node attributes to include.
    public init(source: String, uniforms: [Uniform], attributes: [ShaderAttribute]) {
        self.name = nil
        self.source = source
        self.uniforms = uniforms
        self.attributes = attributes
    }

    // MARK: - Uniform Management

    /// Adds a uniform to the shader.
    ///
    /// - Parameter uniform: The uniform to add.
    public func addUniform(_ uniform: Uniform) {
        // Replace existing uniform with same name
        if let index = uniforms.firstIndex(where: { $0.name == uniform.name }) {
            uniforms[index] = uniform
        } else {
            uniforms.append(uniform)
        }
    }

    /// Removes a uniform by name.
    ///
    /// - Parameter name: The name of the uniform to remove.
    public func removeUniform(named name: String) {
        uniforms.removeAll { $0.name == name }
    }

    /// Returns the uniform with the specified name.
    ///
    /// - Parameter name: The uniform name.
    /// - Returns: The uniform, or `nil` if not found.
    public func uniform(named name: String) -> Uniform? {
        uniforms.first { $0.name == name }
    }

    // MARK: - Attribute Management

    /// Adds an attribute to the shader.
    ///
    /// - Parameter attribute: The attribute to add.
    public func addAttribute(_ attribute: ShaderAttribute) {
        // Replace existing attribute with same name
        if let index = attributes.firstIndex(where: { $0.name == attribute.name }) {
            attributes[index] = attribute
        } else {
            attributes.append(attribute)
        }
    }

    /// Removes an attribute by name.
    ///
    /// - Parameter name: The name of the attribute to remove.
    public func removeAttribute(named name: String) {
        attributes.removeAll { $0.name == name }
    }

    /// Returns the attribute with the specified name.
    ///
    /// - Parameter name: The attribute name.
    /// - Returns: The attribute, or `nil` if not found.
    public func attribute(named name: String) -> ShaderAttribute? {
        attributes.first { $0.name == name }
    }
}

// MARK: - Built-in Shaders

extension Shader {
    /// Creates a grayscale shader.
    ///
    /// - Returns: A shader that converts colors to grayscale.
    public static func grayscale() -> Shader {
        let source = """
        // Grayscale shader
        // Converts the texture to grayscale using luminance weights
        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let texColor = textureSample(texture, textureSampler, uv);
            let gray = dot(texColor.rgb, vec3<f32>(0.299, 0.587, 0.114));
            return vec4<f32>(gray, gray, gray, texColor.a) * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "grayscale"
        return shader
    }

    /// Creates a sepia tone shader.
    ///
    /// - Returns: A shader that applies a sepia tone effect.
    public static func sepia() -> Shader {
        let source = """
        // Sepia shader
        // Applies a warm sepia tone to the texture
        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let texColor = textureSample(texture, textureSampler, uv);
            var sepia: vec3<f32>;
            sepia.r = dot(texColor.rgb, vec3<f32>(0.393, 0.769, 0.189));
            sepia.g = dot(texColor.rgb, vec3<f32>(0.349, 0.686, 0.168));
            sepia.b = dot(texColor.rgb, vec3<f32>(0.272, 0.534, 0.131));
            return vec4<f32>(sepia, texColor.a) * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "sepia"
        return shader
    }

    /// Creates an invert colors shader.
    ///
    /// - Returns: A shader that inverts colors.
    public static func invert() -> Shader {
        let source = """
        // Invert shader
        // Inverts the RGB colors while preserving alpha
        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let texColor = textureSample(texture, textureSampler, uv);
            return vec4<f32>(1.0 - texColor.r, 1.0 - texColor.g, 1.0 - texColor.b, texColor.a) * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "invert"
        return shader
    }

    /// Creates a pixelate shader.
    ///
    /// - Parameter pixelSize: The size of pixels (higher = more pixelated).
    /// - Returns: A shader that pixelates the texture.
    public static func pixelate(pixelSize: Float = 8.0) -> Shader {
        let source = """
        // Pixelate shader
        // Reduces texture resolution for a retro effect
        @group(1) @binding(0) var<uniform> u_pixelSize: f32;
        @group(1) @binding(1) var<uniform> u_textureSize: vec2<f32>;

        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let pixelatedUV = floor(uv * u_textureSize / u_pixelSize) * u_pixelSize / u_textureSize;
            let texColor = textureSample(texture, textureSampler, pixelatedUV);
            return texColor * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "pixelate"
        shader.addUniform(Uniform(name: "u_pixelSize", float: pixelSize))
        shader.addUniform(Uniform(name: "u_textureSize", floatVector2: (256.0, 256.0)))
        return shader
    }

    /// Creates a blur shader.
    ///
    /// - Parameter radius: The blur radius.
    /// - Returns: A shader that applies a box blur.
    public static func blur(radius: Float = 2.0) -> Shader {
        let source = """
        // Box blur shader
        // Applies a simple box blur effect
        @group(1) @binding(0) var<uniform> u_radius: f32;
        @group(1) @binding(1) var<uniform> u_textureSize: vec2<f32>;

        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let texelSize = 1.0 / u_textureSize;
            var result = vec4<f32>(0.0);
            var samples = 0.0;

            for (var x = -u_radius; x <= u_radius; x += 1.0) {
                for (var y = -u_radius; y <= u_radius; y += 1.0) {
                    let offset = vec2<f32>(x, y) * texelSize;
                    result += textureSample(texture, textureSampler, uv + offset);
                    samples += 1.0;
                }
            }

            return (result / samples) * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "blur"
        shader.addUniform(Uniform(name: "u_radius", float: radius))
        shader.addUniform(Uniform(name: "u_textureSize", floatVector2: (256.0, 256.0)))
        return shader
    }

    /// Creates a chromatic aberration shader.
    ///
    /// - Parameter amount: The amount of color separation.
    /// - Returns: A shader that applies chromatic aberration.
    public static func chromaticAberration(amount: Float = 0.01) -> Shader {
        let source = """
        // Chromatic aberration shader
        // Separates RGB channels for a glitch effect
        @group(1) @binding(0) var<uniform> u_amount: f32;

        @fragment
        fn fragment_main(
            @location(0) uv: vec2<f32>,
            @location(1) color: vec4<f32>
        ) -> @location(0) vec4<f32> {
            let r = textureSample(texture, textureSampler, uv + vec2<f32>(u_amount, 0.0)).r;
            let g = textureSample(texture, textureSampler, uv).g;
            let b = textureSample(texture, textureSampler, uv - vec2<f32>(u_amount, 0.0)).b;
            let a = textureSample(texture, textureSampler, uv).a;
            return vec4<f32>(r, g, b, a) * color;
        }
        """
        let shader = Shader(source: source)
        shader.name = "chromaticAberration"
        shader.addUniform(Uniform(name: "u_amount", float: amount))
        return shader
    }
}
