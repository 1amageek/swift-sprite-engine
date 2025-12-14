/// SpriteEngine - A Swift-native 2D game engine for WebAssembly and WebGPU
///
/// SpriteEngine is designed to prove that Swift can be used for real-time Web games.
/// It provides a SpriteKit-like API while targeting WebAssembly with WebGPU rendering.
///
/// ## Quick Start
/// ```swift
/// import SpriteEngine
///
/// class GameScene: SNScene {
///     override func sceneDidLoad() {
///         let player = SNSpriteNode(color: .green, size: Size(width: 40, height: 40))
///         player.position = Point(x: size.width / 2, y: size.height / 2)
///         addChild(player)
///     }
///
///     override func update(dt: Float) {
///         // Game logic here
///     }
/// }
///
/// // Entry point
/// Engine.run(GameScene(size: Size(width: 800, height: 600)))
/// ```
///
/// ## Core Types
/// - `Engine`: Entry point for starting the game
/// - `SNScene`: Root node and game world container
/// - `SNNode`: Base class for all scene graph elements
/// - `SNSpriteNode`: Displays textured images or solid colors
/// - `SNCamera`: Controls the viewport
///
/// ## Geometry Types
/// - `Point`: 2D coordinate (CGPoint equivalent)
/// - `Size`: Width and height dimensions (CGSize equivalent)
/// - `Rect`: Rectangle with origin and size (CGRect equivalent)
/// - `Vector2`: 2D direction and magnitude (CGVector equivalent)
/// - `AffineTransform`: 2D transformation matrix
/// - `Angle`: Type-safe angular values
/// - `Color`: RGBA color values

// All public types are automatically exported as part of the SpriteEngine module.
// No explicit re-exports needed since everything is in the same module.

#if arch(wasm32)
import JavaScriptEventLoop
#else
/// Game loop instance for native platforms (Preview).
nonisolated(unsafe) private var _nativeGameLoop: GameLoop = GameLoop()
#endif

/// Main entry point for SpriteEngine.
///
/// Use `Engine.run(_:configuration:)` to start your game with a scene.
///
/// ## Example
/// ```swift
/// import SpriteEngine
///
/// // Default configuration
/// Engine.run(GameScene(size: Size(width: 800, height: 600)))
///
/// // With custom asset path
/// let config = Engine.Configuration(assetPath: "assets")
/// Engine.run(GameScene(size: Size(width: 800, height: 600)), configuration: config)
/// ```
public enum Engine {

    // MARK: - Configuration

    /// Configuration for the SpriteEngine.
    ///
    /// Use this to specify asset paths and other engine settings.
    ///
    /// ## Asset Path Rules
    /// In browser environments, resources must be accessed via URL.
    /// The `assetPath` specifies the base directory for all assets.
    ///
    /// ```swift
    /// // Assets at "assets/player.png"
    /// let config = Engine.Configuration(assetPath: "assets")
    ///
    /// // Assets at root "player.png"
    /// let config = Engine.Configuration(assetPath: "")
    /// ```
    public struct Configuration: Sendable {
        /// Base path for assets.
        ///
        /// This path is prepended to all asset names when loading resources.
        /// - Empty string ("") means assets are at the root level
        /// - "assets" means assets are in the "assets/" directory
        public var assetPath: String

        /// Creates a configuration with the specified asset path.
        ///
        /// - Parameter assetPath: Base directory for assets. Default is empty (root).
        public init(assetPath: String = "") {
            self.assetPath = assetPath
        }

        /// Default configuration with assets at root.
        public static let `default` = Configuration()
    }

    /// Current engine configuration.
    ///
    /// Set by `Engine.run(_:configuration:)` and used by asset loading.
    /// Note: WASM is single-threaded, so this is safe.
    public nonisolated(unsafe) private(set) static var configuration: Configuration = .default

    // MARK: - Run

    /// Starts the SpriteEngine with the given scene.
    ///
    /// This handles all platform-specific initialization:
    /// - On WASM: Installs JavaScript event loop and initializes WebGPU
    /// - On other platforms: Prepares for SwiftUI preview rendering
    ///
    /// - Parameters:
    ///   - scene: The initial scene to present.
    ///   - configuration: Engine configuration including asset paths.
    public static func run(_ scene: SNScene, configuration: Configuration = .default) {
        self.configuration = configuration

        #if arch(wasm32)
        JavaScriptEventLoop.installGlobalExecutor()
        wisp_setScene(scene)
        wisp_initAsync()
        #else
        _nativeGameLoop.present(scene)
        scene.sceneDidLoad()
        #endif
    }
}
