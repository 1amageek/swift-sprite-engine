/// A node that references content defined elsewhere.
///
/// `SNReferenceNode` is used to share nodes across different scenes without
/// duplicating their definition. Changes to the referenced content propagate
/// to all references.
///
/// Unlike SpriteKit's `SKReferenceNode` which loads from `.sks` files,
/// Wisp's `SNReferenceNode` uses factory closures for WebAssembly compatibility.
///
/// ## Usage
/// ```swift
/// // Define shared content
/// func createEnemyShip() -> SNNode {
///     let ship = SNSpriteNode(color: .red, size: Size(width: 32, height: 32))
///     ship.name = "enemy"
///     return ship
/// }
///
/// // Use in multiple scenes
/// let enemy1 = SNReferenceNode(factory: createEnemyShip)
/// let enemy2 = SNReferenceNode(factory: createEnemyShip)
///
/// scene1.addChild(enemy1)
/// scene2.addChild(enemy2)
/// ```
///
/// ## Regenerating Content
/// ```swift
/// // Reload the referenced content
/// referenceNode.resolve()
/// ```
open class SNReferenceNode: SNNode {
    // MARK: - Properties

    /// The factory closure that creates the referenced content.
    private let factory: (() -> SNNode?)?

    /// The URL for the referenced content (for future file-based loading).
    private let url: String?

    /// Whether the reference has been resolved.
    public private(set) var isResolved: Bool = false

    // MARK: - Initialization

    /// Creates a reference node with a factory closure.
    ///
    /// - Parameter factory: A closure that creates the referenced node.
    public init(factory: @escaping () -> SNNode?) {
        self.factory = factory
        self.url = nil
        super.init()
    }

    /// Creates a reference node with a URL.
    ///
    /// The URL is stored for potential future loading mechanisms.
    /// Currently, this initializer stores the URL but does not load content.
    ///
    /// - Parameter url: The URL to the referenced content.
    public init(url: String?) {
        self.factory = nil
        self.url = url
        super.init()
    }

    /// Creates a reference node with a file name.
    ///
    /// The file name is stored for potential future loading mechanisms.
    ///
    /// - Parameter fileNamed: The name of the file containing the referenced content.
    public convenience init(fileNamed: String?) {
        self.init(url: fileNamed)
    }

    // MARK: - Resolution

    /// Loads the reference node's content and adds it as a child.
    ///
    /// If content was previously loaded, it is removed before loading new content.
    /// After resolution, `didLoad(_:)` is called with the loaded node.
    public func resolve() {
        // Remove existing content
        removeAllChildren()

        // Load new content
        var loadedNode: SNNode?

        if let factory = factory {
            loadedNode = factory()
        }

        // Add the loaded content as a child
        if let node = loadedNode {
            addChild(node)
        }

        isResolved = true

        // Notify subclasses
        didLoad(loadedNode)
    }

    /// Called after the reference node's content is loaded.
    ///
    /// Override this method to configure the loaded content.
    ///
    /// - Parameter node: The node that was loaded, or `nil` if loading failed.
    open func didLoad(_ node: SNNode?) {
        // Override in subclasses
    }

    // MARK: - Auto-Resolution

    /// Automatically resolves when added to a scene if not already resolved.
    open override func didMoveToScene(_ scene: SNScene?) {
        super.didMoveToScene(scene)

        if !isResolved && scene != nil {
            resolve()
        }
    }

    // MARK: - CustomStringConvertible

    open override var description: String {
        let nameStr = name.map { "\"\($0)\"" } ?? "unnamed"
        let resolvedStr = isResolved ? "resolved" : "pending"
        return "SNReferenceNode(\(nameStr), \(resolvedStr), children: \(children.count))"
    }
}
