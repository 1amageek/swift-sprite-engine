/// A node that renders its children into a buffer, optionally applying effects.
///
/// `SNEffectNode` is a container that renders its children into a private framebuffer,
/// applies optional effects (shaders), and then composites the result into the scene.
/// It's also useful for caching static content for performance.
///
/// ## Usage
/// ```swift
/// // Apply a blur effect to children
/// let effectNode = SNEffectNode()
/// effectNode.shader = Shader.blur(radius: 4)
/// effectNode.shouldEnableEffects = true
/// effectNode.addChild(sprite1)
/// effectNode.addChild(sprite2)
/// scene.addChild(effectNode)
///
/// // Cache static content
/// let cachedNode = SNEffectNode()
/// cachedNode.shouldRasterize = true
/// cachedNode.addChild(staticBackground)
/// ```
open class SNEffectNode: SNNode, SNWarpable {
    // MARK: - Effect Properties

    /// Whether effects should be applied when rendering children.
    /// When `false`, children are rendered normally without effects.
    public var shouldEnableEffects: Bool = true

    /// A custom shader applied to the rendered children.
    /// The shader processes the combined output of all children.
    public var shader: SNShader?

    /// Per-node attribute values for the shader.
    public var attributeValues: [String: SNAttributeValue] = [:]

    // MARK: - Caching

    /// Whether to cache the rendered result.
    /// When `true`, children are rendered once and cached until invalidated.
    /// This improves performance for static content.
    public var shouldRasterize: Bool = false

    /// Indicates whether the cached content needs to be re-rendered.
    private var needsRedraw: Bool = true

    // MARK: - Blending

    /// The blend mode used when compositing into the parent framebuffer.
    public var blendMode: SNBlendMode = .alpha

    // MARK: - SNWarpable

    /// The warp geometry applied to this effect node.
    public var warpGeometry: SNWarpGeometry?

    /// The number of subdivision levels for warp smoothing.
    public var subdivisionLevels: Int = 0

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Cache Invalidation

    /// Marks the cached content as needing to be re-rendered.
    /// Call this when child content has changed.
    public func invalidateCache() {
        needsRedraw = true
    }

    /// Whether the node needs to re-render its content.
    public var needsRender: Bool {
        !shouldRasterize || needsRedraw
    }

    /// Called after rendering to mark cache as valid.
    public func didRender() {
        needsRedraw = false
    }

    // MARK: - Shader Attributes

    /// Sets a shader attribute value.
    public func setValue(_ value: SNAttributeValue, forAttribute name: String) {
        attributeValues[name] = value
    }

    /// Returns the shader attribute value for the given name.
    public func value(forAttribute name: String) -> SNAttributeValue? {
        attributeValues[name]
    }

    // MARK: - Child Modification Overrides

    public override func addChild(_ node: SNNode) {
        super.addChild(node)
        invalidateCache()
    }

    public override func insertChild(_ node: SNNode, at index: Int) {
        super.insertChild(node, at: index)
        invalidateCache()
    }

    public override func removeAllChildren() {
        super.removeAllChildren()
        invalidateCache()
    }
}
