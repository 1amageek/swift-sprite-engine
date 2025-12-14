import SpriteEngine

/// Example game scene with animated sprite
public class GameScene: SNScene {

    private var player: SNSpriteNode!
    private var baseTexture: SNTexture!
    private var frameIndex: Int = 0
    private var animationTimer: Float = 0
    private var walkFrames: [Rect] = []

    // Sprite sheet info
    private let sheetWidth: Float = 832
    private let sheetHeight: Float = 728
    private let frameWidth: Float = 64
    private let frameHeight: Float = 56
    private let framesPerRow: Int = 13

    public override init(size: Size) {
        super.init(size: size)
    }

    public override func sceneDidLoad() {
        backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)

        // Create walk animation frames (frames 52-63 from sprite sheet)
        for i in 52...63 {
            let col = i % framesPerRow
            let row = i / framesPerRow

            // Calculate UV rect (normalized 0-1)
            let x = Float(col) * frameWidth / sheetWidth
            let y = Float(row) * frameHeight / sheetHeight
            let w = frameWidth / sheetWidth
            let h = frameHeight / sheetHeight

            walkFrames.append(Rect(x: x, y: y, width: w, height: h))
        }

        // Load sprite sheet texture
        baseTexture = SNTexture(imageNamed: "x.png")

        // Create player sprite with first walk frame
        let firstFrame = SNTexture(rect: walkFrames[0], in: baseTexture)
        player = SNSpriteNode(texture: firstFrame, size: Size(width: frameWidth * 3, height: frameHeight * 3))
        player.position = Point(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    public override func update(dt: Float) {
        // Animate walk cycle
        animationTimer += dt
        let frameDuration: Float = 0.08 // ~12 FPS animation

        if animationTimer >= frameDuration {
            animationTimer -= frameDuration
            frameIndex = (frameIndex + 1) % walkFrames.count

            // Update texture rect to show current frame
            let frameRect = walkFrames[frameIndex]
            let frameTexture = SNTexture(rect: frameRect, in: baseTexture)
            player.texture = frameTexture
        }

        // Move with input
        let speed: Float = 200 * dt

        if input.left {
            player.position.x -= speed
            player.scale = Size(width: -1, height: 1) // Flip horizontally
        }
        if input.right {
            player.position.x += speed
            player.scale = Size(width: 1, height: 1)
        }
        if input.up { player.position.y += speed }
        if input.down { player.position.y -= speed }

        // Keep in bounds
        player.position.x = max(frameWidth, min(size.width - frameWidth, player.position.x))
        player.position.y = max(frameHeight, min(size.height - frameHeight, player.position.y))
    }
}

// MARK: - SwiftUI Preview (Xcode only)
// Note: #Preview macro only works in Xcode, not command-line builds.
// Use `swift build` for WASM builds, open in Xcode for previews.
