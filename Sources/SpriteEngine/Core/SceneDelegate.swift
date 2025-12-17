/// A protocol that allows any class to participate in the scene render loop callbacks.
///
/// `SNSceneDelegate` is used to implement a delegate that is called during the scene's
/// animation loop. Use a delegate when you want to use a scene without subclassing it.
///
/// When processing a scene, SpriteEngine runs a loop that processes and renders the scene:
/// ```
/// 1. update(_:for:)           ← Your game logic
/// 2. didEvaluateActions(for:) ← After actions are processed
/// 3. didSimulatePhysics(for:) ← After physics simulation
/// 4. didApplyConstraints(for:)← After constraints are applied
/// 5. didFinishUpdate(for:)    ← Final chance before rendering
/// ```
///
/// ## Usage
/// ```swift
/// class GameController: SNSceneDelegate {
///     func update(_ dt: Float, for scene: SNScene) {
///         // Game logic here
///     }
///
///     func didSimulatePhysics(for scene: SNScene) {
///         // Post-physics processing
///     }
/// }
///
/// let scene = SNScene(size: Size(width: 800, height: 600))
/// scene.delegate = gameController
/// ```
public protocol SNSceneDelegate: AnyObject {
    /// Called to perform game logic before actions are evaluated.
    ///
    /// - Parameters:
    ///   - dt: The time interval since the last update.
    ///   - scene: The scene being updated.
    func update(_ dt: CGFloat, for scene: SNScene)

    /// Called after scene actions have been evaluated.
    ///
    /// - Parameter scene: The scene that evaluated actions.
    func didEvaluateActions(for scene: SNScene)

    /// Called after physics simulations have been performed.
    ///
    /// - Parameter scene: The scene that simulated physics.
    func didSimulatePhysics(for scene: SNScene)

    /// Called after constraints have been applied.
    ///
    /// - Parameter scene: The scene that applied constraints.
    func didApplyConstraints(for scene: SNScene)

    /// Called after all update processing is complete.
    ///
    /// This is the last chance to modify nodes before rendering.
    ///
    /// - Parameter scene: The scene that finished updating.
    func didFinishUpdate(for scene: SNScene)

    /// Called when the scene's size has changed.
    ///
    /// - Parameters:
    ///   - oldSize: The previous size of the scene.
    ///   - scene: The scene whose size changed.
    func didChangeSize(_ oldSize: Size, for scene: SNScene)
}

// MARK: - Default Implementations

extension SNSceneDelegate {
    /// Default empty implementation.
    public func update(_ dt: CGFloat, for scene: SNScene) {}

    /// Default empty implementation.
    public func didEvaluateActions(for scene: SNScene) {}

    /// Default empty implementation.
    public func didSimulatePhysics(for scene: SNScene) {}

    /// Default empty implementation.
    public func didApplyConstraints(for scene: SNScene) {}

    /// Default empty implementation.
    public func didFinishUpdate(for scene: SNScene) {}

    /// Default empty implementation.
    public func didChangeSize(_ oldSize: Size, for scene: SNScene) {}
}
