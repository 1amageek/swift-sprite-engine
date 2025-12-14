# SpriteEngine

A Swift-native 2D game engine for WebAssembly + WebGPU.

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/1amageek/swift-sprite-engine", branch: "main"),
],
targets: [
    .target(name: "YourGame", dependencies: [
        .product(name: "SpriteEngine", package: "swift-sprite-engine")
    ])
]
```

## Quick Start

```swift
import SpriteEngine

class GameScene: SNScene {
    var player: SNSpriteNode!

    override func sceneDidLoad() {
        player = SNSpriteNode(imageNamed: "player.png")
        player.position = Point(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    override func update(dt: Float) {
        let speed: Float = 200 * dt
        if input.left { player.position.x -= speed }
        if input.right { player.position.x += speed }
        if input.up { player.position.y += speed }
        if input.down { player.position.y -= speed }
    }
}
```

### Run in Browser (WASM)

```swift
#if arch(wasm32)
Engine.run(GameScene(size: Size(width: 800, height: 600)))
#endif
```

### Preview in Xcode (SwiftUI)

```swift
#if canImport(SwiftUI)
import SwiftUI

#Preview {
    SpriteView(scene: GameScene(size: Size(width: 800, height: 600)))
}
#endif
```

## Sprites

```swift
// From image
let sprite = SNSpriteNode(imageNamed: "enemy.png")

// Solid color
let box = SNSpriteNode(color: .red, size: Size(width: 50, height: 50))

// From texture
let texture = SNTexture(imageNamed: "item.png")
let item = SNSpriteNode(texture: texture)

// Properties
sprite.position = Point(x: 100, y: 200)
sprite.rotation = 0.5  // radians
sprite.scale = Size(width: 2, height: 2)
sprite.alpha = 0.8
sprite.zPosition = 10
sprite.anchorPoint = Point(x: 0.5, y: 0)  // bottom-center

scene.addChild(sprite)
```

## Sprite Sheets

```swift
let sheet = SNTexture(imageNamed: "spritesheet.png")

// Extract frame by UV rect (0-1 normalized)
let frame = SNTexture(rect: Rect(x: 0, y: 0, width: 0.25, height: 0.25), in: sheet)
let sprite = SNSpriteNode(texture: frame)

// Animate
var frames: [SNTexture] = []
for i in 0..<4 {
    let rect = Rect(x: Float(i) * 0.25, y: 0, width: 0.25, height: 0.25)
    frames.append(SNTexture(rect: rect, in: sheet))
}
```

## Actions

```swift
// Move
sprite.run(SNAction.move(to: Point(x: 200, y: 100), duration: 1.0))
sprite.run(SNAction.moveBy(Vector2(dx: 50, dy: 0), duration: 0.5))

// Rotate & Scale
sprite.run(SNAction.rotate(by: .pi, duration: 1.0))
sprite.run(SNAction.scale(to: Size(width: 2, height: 2), duration: 0.5))

// Fade
sprite.run(SNAction.fadeOut(duration: 0.3))
sprite.run(SNAction.fadeIn(duration: 0.3))

// Sequence
sprite.run(SNAction.sequence([
    SNAction.move(to: Point(x: 200, y: 100), duration: 0.5),
    SNAction.fadeOut(duration: 0.3),
    SNAction.removeFromParent()
]))

// Repeat
sprite.run(SNAction.repeatForever(SNAction.rotate(by: .pi * 2, duration: 2.0)))

// With completion
sprite.run(SNAction.move(to: target, duration: 1.0)) {
    print("Done!")
}
```

## Camera

```swift
let camera = SNCamera()
scene.addChild(camera)
scene.camera = camera

override func update(dt: Float) {
    // Follow player
    camera.position = player.position

    // Or smooth follow
    camera.smoothFollow(target: player.position, smoothing: 5.0, dt: dt)

    // Clamp to level bounds
    camera.clampToBounds(levelBounds, sceneSize: size)
}

// HUD elements (attached to camera, always visible)
let scoreLabel = SNLabelNode(text: "Score: 0")
scoreLabel.position = Point(x: -350, y: 250)
camera.addChild(scoreLabel)
```

## Physics

```swift
override func sceneDidLoad() {
    physicsWorld.gravity = Vector2(dx: 0, dy: -980)
    physicsWorld.contactDelegate = self

    // Player with circle body
    player.physicsBody = SNPhysicsBody(circleOfRadius: 25)
    player.physicsBody?.categoryBitMask = 0x1
    player.physicsBody?.contactTestBitMask = 0x2

    // Ground with edge body
    let ground = SNNode()
    ground.physicsBody = SNPhysicsBody(edgeLoopFrom: Rect(x: 0, y: 0, width: 800, height: 50))
    ground.physicsBody?.isDynamic = false
    addChild(ground)
}

// Contact delegate
extension GameScene: SNPhysicsContactDelegate {
    func physicsContactDidBegin(_ contact: SNPhysicsContact) {
        // Handle collision
    }
}
```

## Input

```swift
override func update(dt: Float) {
    // Digital input
    if input.left { }
    if input.right { }
    if input.up { }
    if input.down { }
    if input.action { }
    if input.action2 { }
    if input.pause { }

    // Pointer (mouse/touch)
    if input.pointerDown {
        if let pos = input.pointerPosition {
            let scenePos = convertPoint(fromView: pos, viewSize: viewSize)
        }
    }
}
```

## Audio

```swift
// Sound effects
scene.audio.play(Sounds.explosion)
scene.audio.play(Sounds.coin, volume: 0.8)

// Background music
scene.audio.playMusic(Sounds.bgm)
scene.audio.stopMusic(fadeDuration: 1.0)

// Volume control
scene.audio.setMusicVolume(0.5, fadeDuration: 1.0)
```

## Labels

```swift
let label = SNLabelNode(text: "Hello World")
label.fontSize = 24
label.fontColor = .white
label.horizontalAlignment = .center
label.position = Point(x: 400, y: 300)
addChild(label)

label.text = "Updated!"
```

## Scene Transitions

```swift
let newScene = Level2Scene(size: size)
view?.presentScene(newScene, transition: .crossFade(duration: 1.0))

// Other transitions
.fade(duration: 1.0)
.push(direction: .left, duration: 0.5)
.moveIn(direction: .up, duration: 0.5)
```

## Build for WebAssembly

```bash
# Install Swift WASM SDK
swift sdk install swift-6.2.3-RELEASE_wasm

# Build
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js

# Run
cd .build/plugins/PackageToJS/outputs/Package
python3 -m http.server 8080
```

## Requirements

- Swift 6.2+
- WebGPU-capable browser (Chrome 113+, Edge 113+, Safari 18+)

## License

MIT
