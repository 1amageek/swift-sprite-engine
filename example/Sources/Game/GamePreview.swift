#if canImport(SwiftUI) && !arch(wasm32)
import SwiftUI
import SpriteEngine

/// A preview-friendly view wrapper for GameScene.
/// Use this in Xcode's #Preview or PreviewProvider.
@available(macOS 12.0, iOS 15.0, *)
public struct GamePreview: View {
    public init() {}

    public var body: some View {
        SpriteView(scene: GameScene(size: Size(width: 800, height: 600)))
            .frame(width: 800, height: 600)
    }
}

// Note: To preview in Xcode, add this to a separate file in your Xcode project:
//
// import SwiftUI
// import Game
//
// #Preview("GameScene") {
//     GamePreview()
// }
//
// The #Preview macro requires Xcode and doesn't work with command-line builds.
#endif
