/// Defines a custom attribute for shader programs.
///
/// `SNAttribute` specifies per-node data that can be passed to shaders.
/// Unlike uniforms which are shared across all nodes using a shader,
/// attributes can have different values for each node.
///
/// ## Usage
/// ```swift
/// // Define attributes for a custom shader
/// let colorAttribute = SNAttribute(name: "a_color", type: .float4)
/// let intensityAttribute = SNAttribute(name: "a_intensity", type: .float)
///
/// // Create a shader with these attributes
/// let shader = SNShader(source: shaderCode, attributes: [colorAttribute, intensityAttribute])
/// ```
public final class SNAttribute: Sendable {
    /// The name of the attribute as it appears in the shader.
    public let name: String

    /// The type of data this attribute holds.
    public let type: AttributeType

    /// Creates a shader attribute with the specified name and type.
    ///
    /// - Parameters:
    ///   - name: The attribute name in the shader.
    ///   - type: The data type of the attribute.
    public init(name: String, type: AttributeType) {
        self.name = name
        self.type = type
    }
}
