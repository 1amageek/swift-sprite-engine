#if arch(wasm32)
/// WGSL shader source for sprite rendering.
///
/// This shader supports:
/// - Instanced rendering of quads
/// - Per-instance transform (position, rotation, scale, anchor)
/// - Texture sampling with UV coordinates
/// - Color tinting and alpha blending
enum SpriteShader {
    /// The WGSL shader source code.
    static let source = """
    // Uniform buffer containing view-projection matrix
    struct Uniforms {
        viewProjection: mat4x4<f32>,
        screenSize: vec2<f32>,
        _padding: vec2<f32>,
    }

    @group(0) @binding(0) var<uniform> uniforms: Uniforms;
    @group(0) @binding(1) var textureSampler: sampler;
    @group(0) @binding(2) var spriteTexture: texture_2d<f32>;

    // Per-instance data passed as vertex attributes
    struct InstanceInput {
        // Instance attributes (location 1-7)
        @location(1) instancePosition: vec2<f32>,
        @location(2) instanceSize: vec2<f32>,
        @location(3) instanceRotation: f32,
        @location(4) instanceAnchor: vec2<f32>,
        @location(5) instanceTexRect: vec4<f32>,  // x, y, width, height in UV space
        @location(6) instanceColor: vec4<f32>,
        @location(7) instanceAlpha: f32,
    }

    struct VertexInput {
        @location(0) position: vec2<f32>,  // Quad vertex (0-1 range)
        @builtin(instance_index) instanceIndex: u32,
    }

    struct VertexOutput {
        @builtin(position) position: vec4<f32>,
        @location(0) texCoord: vec2<f32>,
        @location(1) color: vec4<f32>,
    }

    @vertex
    fn vs_main(vertex: VertexInput, instance: InstanceInput) -> VertexOutput {
        var out: VertexOutput;

        // Calculate vertex position relative to anchor point
        let anchoredPos = vertex.position - instance.instanceAnchor;

        // Apply scale (size)
        let scaledPos = anchoredPos * instance.instanceSize;

        // Apply rotation
        let cosR = cos(instance.instanceRotation);
        let sinR = sin(instance.instanceRotation);
        let rotatedPos = vec2<f32>(
            scaledPos.x * cosR - scaledPos.y * sinR,
            scaledPos.x * sinR + scaledPos.y * cosR
        );

        // Apply translation
        let worldPos = rotatedPos + instance.instancePosition;

        // Apply view-projection matrix
        out.position = uniforms.viewProjection * vec4<f32>(worldPos, 0.0, 1.0);

        // Calculate texture coordinates from texture rect
        out.texCoord = instance.instanceTexRect.xy + vertex.position * instance.instanceTexRect.zw;

        // Pass color with alpha
        out.color = vec4<f32>(
            instance.instanceColor.rgb,
            instance.instanceColor.a * instance.instanceAlpha
        );

        return out;
    }

    @fragment
    fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
        let texColor = textureSample(spriteTexture, textureSampler, in.texCoord);
        return texColor * in.color;
    }

    // Fragment shader for solid color (no texture)
    @fragment
    fn fs_solid(in: VertexOutput) -> @location(0) vec4<f32> {
        return in.color;
    }
    """

    /// Vertex buffer layout for the quad vertices.
    static let quadVertices: [CGFloat] = [
        // Triangle 1
        0.0, 0.0,  // bottom-left
        1.0, 0.0,  // bottom-right
        0.0, 1.0,  // top-left
        // Triangle 2
        1.0, 0.0,  // bottom-right
        1.0, 1.0,  // top-right
        0.0, 1.0,  // top-left
    ]

    /// Number of vertices per quad.
    static let verticesPerQuad: UInt32 = 6

    /// Size of instance data in bytes (aligned to 16 bytes).
    /// Layout: pos(8) + size(8) + rot(4) + pad(4) + anchor(8) + texRect(16) + color(16) + alpha(4) + pad(12) = 80
    static let instanceStride: UInt64 = 80
}
#endif
