import SpriteEngine
import Game

// MARK: - WASM Entry Point

#if arch(wasm32)
let config = Engine.Configuration(assetPath: "")
Engine.run(GameScene(size: Size(width: 800, height: 600)), configuration: config)
#endif
