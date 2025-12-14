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
import Foundation
/// Game loop instance for native platforms (Preview).
nonisolated(unsafe) private var _nativeGameLoop: GameLoop = GameLoop()
#endif

/// Main entry point for SpriteEngine (Singleton).
///
/// Use `Engine.shared` to access the engine instance, or `Engine.run(_:)` for convenience.
///
/// ## Example
/// ```swift
/// import SpriteEngine
///
/// // Configure and run
/// Engine.shared.assetPath = "assets"
/// Engine.shared.run(GameScene(size: Size(width: 800, height: 600)))
///
/// // Or use the static convenience method
/// Engine.run(GameScene(size: Size(width: 800, height: 600)))
/// ```
public final class Engine: @unchecked Sendable {

    // MARK: - Singleton

    /// The shared engine instance.
    public static let shared = Engine()

    /// Private initializer to enforce singleton pattern.
    private init() {}

    // MARK: - Configuration

    /// Base path for assets.
    ///
    /// This path is prepended to all asset names when loading resources.
    /// - Empty string ("") means assets are at the root level
    /// - "assets" means assets are in the "assets/" directory
    ///
    /// ## Asset Path Rules
    /// In browser environments, resources must be accessed via URL.
    ///
    /// ```swift
    /// // Assets at "assets/player.png"
    /// Engine.shared.assetPath = "assets"
    ///
    /// // Assets at root "player.png"
    /// Engine.shared.assetPath = ""
    /// ```
    public var assetPath: String = ""

    #if !arch(wasm32)
    /// The bundle to load resources from.
    ///
    /// For SwiftPM packages, pass `Bundle.module` to load resources from the package.
    /// On WASM, this property is ignored (resources are loaded via URL).
    public var resourceBundle: Bundle = .main
    #endif

    // MARK: - Run

    /// Starts the SpriteEngine with the given scene.
    ///
    /// This handles all platform-specific initialization:
    /// - On WASM: Installs JavaScript event loop and initializes WebGPU
    /// - On other platforms: Prepares for SwiftUI preview rendering
    ///
    /// - Parameter scene: The initial scene to present.
    public func run(_ scene: SNScene) {
        #if arch(wasm32)
        JavaScriptEventLoop.installGlobalExecutor()
        wisp_setScene(scene)
        wisp_initAsync()
        #else
        _nativeGameLoop.present(scene)
        scene.sceneDidLoad()
        #endif
    }

    #if !arch(wasm32)
    /// Convenience static method to start the engine with a scene.
    ///
    /// - Parameters:
    ///   - scene: The initial scene to present.
    ///   - assetPath: Base directory for assets. Default is empty (root).
    ///   - resourceBundle: Bundle to load resources from. Default is Bundle.main.
    public static func run(_ scene: SNScene, assetPath: String = "", resourceBundle: Bundle = .main) {
        shared.assetPath = assetPath
        shared.resourceBundle = resourceBundle
        shared.run(scene)
    }

    // MARK: - Reset (for testing)

    /// Resets the engine configuration to defaults.
    internal func reset() {
        assetPath = ""
        resourceBundle = .main
    }
    #else
    /// Convenience static method to start the engine with a scene (WASM).
    ///
    /// - Parameters:
    ///   - scene: The initial scene to present.
    ///   - assetPath: Base directory for assets. Default is empty (root).
    public static func run(_ scene: SNScene, assetPath: String = "") {
        shared.assetPath = assetPath
        shared.run(scene)
    }

    /// Resets the engine configuration to defaults.
    internal func reset() {
        assetPath = ""
    }
    #endif
}
