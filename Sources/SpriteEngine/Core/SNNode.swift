/// The base class for all elements in the scene graph.
///
/// `SNNode` provides fundamental properties for positioning, rotation, scaling,
/// and hierarchy management. A `SNNode` by itself does not draw any content.
/// Visual content is provided by subclasses such as `SNSpriteNode`.
///
/// ## Coordinate System
/// - Position is relative to the parent node
/// - Positive Y is up, positive X is right
/// - Rotation is counter-clockwise in radians
///
/// ## Example
/// ```swift
/// let container = SNNode()
/// container.position = Point(x: 100, y: 100)
///
/// let sprite = SNSpriteNode(color: .red, size: Size(width: 50, height: 50))
/// sprite.position = Point(x: 50, y: 0)  // Offset from container
/// container.addChild(sprite)
///
/// scene.addChild(container)
/// ```
open class SNNode {
    // MARK: - Static Action Counter (for deterministic key generation)

    /// Global monotonic counter for generating deterministic action keys.
    /// Using nonisolated(unsafe) as actions are typically managed on main thread.
    nonisolated(unsafe) private static var actionCounter: UInt64 = 0

    /// Generates the next deterministic action key.
    private static func nextActionKey() -> String {
        actionCounter += 1
        return "action_\(actionCounter)"
    }
    // MARK: - Identification

    /// An optional name for identifying the node.
    public var name: String?

    // MARK: - Spatial Properties

    /// The position of the node in its parent's coordinate system.
    public var position: Point = .zero

    /// The rotation about the z-axis in radians.
    /// Positive values rotate counter-clockwise.
    public var rotation: Float = 0

    /// A scaling factor that multiplies the size of the node and its descendants.
    /// Negative values flip the node.
    public var scale: Size = Size(width: 1, height: 1)

    /// The height of the node relative to its parent, used for draw ordering.
    /// Higher values are drawn on top of lower values.
    public var zPosition: Float = 0

    // MARK: - Appearance

    /// The transparency of the node.
    /// Range: 0 (invisible) to 1 (fully opaque).
    /// Multiplied with parent's alpha for final opacity.
    public var alpha: Float = 1

    /// Controls whether the node and its descendants are rendered.
    /// Hidden nodes still participate in update cycles.
    public var isHidden: Bool = false

    // MARK: - Hierarchy

    /// The child nodes of this node.
    public private(set) var children: [SNNode] = []

    /// The parent node in the hierarchy.
    public private(set) weak var parent: SNNode?

    /// The scene that contains this node.
    public internal(set) weak var scene: SNScene?

    // MARK: - Physics

    /// The physics body attached to this node.
    /// Set this to enable physics simulation and collision detection.
    public var physicsBody: SNPhysicsBody? {
        didSet {
            oldValue?.node = nil
            physicsBody?.node = self

            // Register/unregister with physics world
            if let oldBody = oldValue {
                scene?.physicsWorld.removeBody(oldBody)
            }
            if let newBody = physicsBody {
                scene?.physicsWorld.addBody(newBody)
            }
        }
    }

    // MARK: - Constraints

    /// The constraints applied to this node.
    ///
    /// Constraints are evaluated each frame after actions and physics.
    public var constraints: [SNConstraint]?

    /// The reach constraints for inverse kinematics.
    public var reachConstraints: ReachConstraints?

    // MARK: - Actions

    /// The actions currently running on this node.
    /// Using an array of tuples to maintain insertion order for deterministic evaluation.
    internal var actions: [(key: String, action: SNAction)] = []

    /// A speed modifier applied to all actions executed by the node and its descendants.
    ///
    /// The default value is 1.0, which means actions run at normal speed.
    /// A value of 2.0 runs actions twice as fast, while 0.5 runs at half speed.
    /// Setting to 0 effectively pauses all actions on this node.
    public var speed: Float = 1.0

    /// Whether this node has any running actions.
    public var hasActions: Bool {
        !actions.isEmpty
    }

    /// Runs an action on this node.
    ///
    /// - Parameter action: The action to run.
    public func run(_ action: SNAction) {
        // Generate a unique key using monotonic counter for determinism
        let key = SNNode.nextActionKey()
        actions.append((key: key, action: action.copy()))
    }

    /// Runs an action with a key for later reference.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - key: A unique key to identify this action.
    public func run(_ action: SNAction, withKey key: String) {
        // Remove existing action with same key if present
        actions.removeAll { $0.key == key }
        actions.append((key: key, action: action.copy()))
    }

    /// Runs an action with a completion handler.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - completion: A closure called when the action completes.
    public func run(_ action: SNAction, completion: @escaping () -> Void) {
        let sequence = SNAction.sequence([action, SNAction.run(completion)])
        run(sequence)
    }

    /// Runs an action on a child node with the specified name.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - name: The name of the child node to run the action on.
    ///
    /// ## Name Patterns
    /// | Pattern | Matches |
    /// |---------|---------|
    /// | `"player"` | Direct child named "player" |
    /// | `"//player"` | Any descendant named "player" |
    public func run(_ action: SNAction, onChildWithName name: String) {
        if name.hasPrefix("//") {
            // Search all descendants
            let searchName = String(name.dropFirst(2))
            enumerateChildNodes(withName: "//" + searchName) { node in
                node.run(action.copy())
            }
        } else {
            // Search direct children
            if let child = childNode(withName: name) {
                child.run(action)
            }
        }
    }

    /// Removes an action with the specified key.
    ///
    /// - Parameter key: The key of the action to remove.
    public func removeAction(forKey key: String) {
        actions.removeAll { $0.key == key }
    }

    /// Removes all actions from this node.
    public func removeAllActions() {
        actions.removeAll()
    }

    /// Returns the action with the specified key.
    ///
    /// - Parameter key: The key of the action.
    /// - Returns: The action, or `nil` if not found.
    public func action(forKey key: String) -> SNAction? {
        actions.first { $0.key == key }?.action
    }

    // MARK: - Initialization

    /// Creates an empty node.
    public init() {}

    // MARK: - Hierarchy Management

    /// Adds a node to the end of the receiver's list of child nodes.
    ///
    /// - Parameter node: The node to add. Must not have a parent.
    /// - Precondition: The node must not already have a parent.
    public func addChild(_ node: SNNode) {
        precondition(node.parent == nil, "Node already has a parent")
        children.append(node)
        node.parent = self
        node.propagateScene(scene)
    }

    /// Inserts a node at a specific position in the children array.
    ///
    /// - Parameters:
    ///   - node: The node to insert. Must not have a parent.
    ///   - index: The position at which to insert the node.
    /// - Precondition: The node must not already have a parent.
    public func insertChild(_ node: SNNode, at index: Int) {
        precondition(node.parent == nil, "Node already has a parent")
        children.insert(node, at: index)
        node.parent = self
        node.propagateScene(scene)
    }

    /// Removes this node from its parent.
    public func removeFromParent() {
        guard let parent = parent else { return }
        parent.children.removeAll { $0 === self }
        self.parent = nil
        propagateScene(nil)
    }

    /// Removes all children from this node.
    public func removeAllChildren() {
        for child in children {
            child.parent = nil
            child.propagateScene(nil)
        }
        children.removeAll()
    }

    /// Propagates the scene reference through the subtree.
    internal func propagateScene(_ scene: SNScene?) {
        let oldScene = self.scene
        self.scene = scene

        // Handle physics body registration/removal when scene changes
        if oldScene !== scene {
            if let body = physicsBody {
                oldScene?.physicsWorld.removeBody(body)
                scene?.physicsWorld.addBody(body)
            }
            didMoveToScene(scene)
        }

        for child in children {
            child.propagateScene(scene)
        }
    }

    /// Called when the node is added to or removed from a scene.
    ///
    /// Override this method to perform setup when the node becomes part of a scene,
    /// or cleanup when removed. The base implementation does nothing.
    ///
    /// - Parameter scene: The scene the node was added to, or `nil` if removed.
    open func didMoveToScene(_ scene: SNScene?) {
        // Override in subclasses
    }

    // MARK: - Searching

    /// Searches immediate children for a node with the specified name.
    ///
    /// - Parameter name: The name to search for.
    /// - Returns: The first child node with the matching name, or `nil`.
    public func childNode(withName name: String) -> SNNode? {
        children.first { $0.name == name }
    }

    /// Enumerates all descendants matching the name pattern.
    ///
    /// - Parameters:
    ///   - name: The name pattern to match.
    ///   - block: A closure called for each matching node.
    ///
    /// ## Name Patterns
    /// | Pattern | Matches |
    /// |---------|---------|
    /// | `"player"` | Direct child named "player" |
    /// | `"//player"` | Any descendant named "player" |
    /// | `"*"` | All direct children |
    public func enumerateChildNodes(withName name: String, using block: (SNNode) -> Void) {
        if name == "*" {
            // Match all direct children
            for child in children {
                block(child)
            }
        } else if name.hasPrefix("//") {
            // Match any descendant
            let searchName = String(name.dropFirst(2))
            enumerateDescendants { node in
                if node.name == searchName {
                    block(node)
                }
            }
        } else {
            // Match direct child
            for child in children where child.name == name {
                block(child)
            }
        }
    }

    /// Enumerates all descendants of this node.
    private func enumerateDescendants(using block: (SNNode) -> Void) {
        for child in children {
            block(child)
            child.enumerateDescendants(using: block)
        }
    }

    // MARK: - World Transform

    /// The position in world coordinates.
    public var worldPosition: Point {
        guard let parent = parent else { return position }
        let parentWorld = parent.worldTransform
        return parentWorld.transform(position)
    }

    /// The rotation in world coordinates (accumulated from all ancestors).
    public var worldRotation: Float {
        guard let parent = parent else { return rotation }
        return parent.worldRotation + rotation
    }

    /// The scale in world coordinates (accumulated from all ancestors).
    public var worldScale: Size {
        guard let parent = parent else { return scale }
        let parentScale = parent.worldScale
        return Size(
            width: parentScale.width * scale.width,
            height: parentScale.height * scale.height
        )
    }

    /// The alpha in world coordinates (multiplied through the hierarchy).
    public var worldAlpha: Float {
        guard let parent = parent else { return alpha }
        return parent.worldAlpha * alpha
    }

    /// The local transform matrix.
    public var localTransform: AffineTransform {
        var transform = AffineTransform.identity
        transform = transform.translated(x: position.x, y: position.y)
        transform = transform.rotated(by: rotation)
        transform = transform.scaled(x: scale.width, y: scale.height)
        return transform
    }

    /// The world transform matrix (combined with all ancestors).
    public var worldTransform: AffineTransform {
        guard let parent = parent else { return localTransform }
        return parent.worldTransform.concatenated(with: localTransform)
    }

    // MARK: - Frame Calculation

    /// Returns a rectangle in parent coordinates containing the node's content.
    ///
    /// The base implementation returns a zero-sized rectangle at the node's position.
    /// Subclasses like `SNSpriteNode` override this to return their actual bounds.
    open var frame: Rect {
        Rect(origin: position, size: .zero)
    }

    /// Returns a rectangle containing this node and all descendants.
    public func calculateAccumulatedFrame() -> Rect {
        var result = frame

        for child in children {
            let childFrame = child.calculateAccumulatedFrame()
            // Transform child frame to parent coordinates
            let transformedOrigin = Point(
                x: position.x + childFrame.origin.x,
                y: position.y + childFrame.origin.y
            )
            let transformedFrame = Rect(origin: transformedOrigin, size: childFrame.size)
            result = result.union(transformedFrame)
        }

        return result
    }

    // MARK: - Coordinate Conversion

    /// Converts a point from another node's coordinate space to this node's coordinate space.
    ///
    /// - Parameters:
    ///   - point: The point to convert.
    ///   - node: The node whose coordinate space the point is in.
    /// - Returns: The point in this node's coordinate space.
    public func convert(_ point: Point, from node: SNNode) -> Point {
        // Convert to world, then to local
        let worldPoint = node.worldTransform.transform(point)
        guard let inverse = worldTransform.inverted() else { return worldPoint }
        return inverse.transform(worldPoint)
    }

    /// Converts a point from this node's coordinate space to another node's coordinate space.
    ///
    /// - Parameters:
    ///   - point: The point to convert.
    ///   - node: The target node's coordinate space.
    /// - Returns: The point in the target node's coordinate space.
    public func convert(_ point: Point, to node: SNNode) -> Point {
        node.convert(point, from: self)
    }

    // MARK: - Update Cycle

    /// Called each frame during the scene's update cycle.
    ///
    /// Override this method to implement per-frame logic for your node.
    /// The base implementation does nothing.
    ///
    /// - Parameter dt: The fixed timestep interval (typically 1/60 second).
    open func update(dt: Float) {
        // Base implementation does nothing
    }

    /// Recursively updates this node and all descendants.
    internal func updateRecursive(dt: Float) {
        update(dt: dt)
        for child in children {
            child.updateRecursive(dt: dt)
        }
    }

    // MARK: - CustomStringConvertible

    /// A textual representation of this node.
    open var description: String {
        let nameStr = name.map { "\"\($0)\"" } ?? "unnamed"
        return "\(type(of: self))(\(nameStr), pos: \(position), children: \(children.count))"
    }
}

extension SNNode: CustomStringConvertible {}

// MARK: - Hashable

extension SNNode: Hashable {
    public static func == (lhs: SNNode, rhs: SNNode) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
