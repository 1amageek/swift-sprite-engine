# Scene

## Overview

`Scene` is the root node of all Wisp content. It represents a single screen or level in your game. A scene manages the update cycle, provides the coordinate system, and optionally uses a camera to control the viewport.

`Scene` inherits from `Node`, meaning it has all the same spatial and hierarchy properties.

## Definition

```swift
class Scene: Node {
    // MARK: - Scene Configuration
    var size: Size
    var scaleMode: ScaleMode = .aspectFit
    var anchorPoint: Point = Point(x: 0.5, y: 0.5)
    var backgroundColor: Color = .black

    // MARK: - Camera
    var camera: Camera?

    // MARK: - Audio
    var audio: AudioSystem
    var audioEngine: AudioEngine
    var listener: Node?

    // MARK: - Physics
    var physicsWorld: PhysicsWorld

    // MARK: - Lifecycle
    func sceneDidLoad()
    func didMove(to view: View)
    func willMove(from view: View)

    // MARK: - Frame Cycle
    func update(dt: Float)
    func didEvaluateActions()
    func didSimulatePhysics()
    func didApplyConstraints()
    func didFinishUpdate()
}
```

## Scene Configuration

### size

The dimensions of the scene in points.

```swift
var size: Vec2
```

- Defines the scene's coordinate space
- How this maps to the view depends on `scaleMode`

### scaleMode

Determines how the scene is scaled to fit the view.

```swift
var scaleMode: ScaleMode
```

```swift
enum ScaleMode {
    case fill         // Stretch to fill, ignores aspect ratio
    case aspectFit    // Scale to fit, may letterbox
    case aspectFill   // Scale to fill, may crop
    case resizeFill   // Resize scene to match view exactly
}
```

| Mode | Behavior |
|------|----------|
| `fill` | Stretches scene to exactly match view dimensions. Content may appear distorted. |
| `aspectFit` | Scales scene uniformly to fit within view. Black bars may appear. |
| `aspectFill` | Scales scene uniformly to fill view. Content may be cropped. |
| `resizeFill` | Scene size changes to match view size. No scaling applied. |

### anchorPoint

The point in the view that corresponds to the scene's origin.

```swift
var anchorPoint: Vec2
```

- Default: `Vec2(x: 0.5, y: 0.5)` (center)
- Range: `(0, 0)` to `(1, 1)`

| Anchor | Origin Location |
|--------|-----------------|
| `(0, 0)` | Bottom-left of view |
| `(0.5, 0.5)` | Center of view |
| `(1, 1)` | Top-right of view |
| `(0.5, 0)` | Bottom-center of view |

### backgroundColor

The background color of the scene.

```swift
var backgroundColor: Color
```

- Default: `Color.black`
- Rendered before all nodes
- Set to `Color.clear` for transparent backgrounds

### Creating a Transparent Background

To overlay SpriteKit content on top of other views:

1. Set the scene's `backgroundColor` to clear
2. Enable `allowsTransparency` on the view
3. Set the view's background to clear

```swift
// Configure scene with transparent background
scene.backgroundColor = .clear

// Configure view for transparency
view.allowsTransparency = true
```

This is useful for overlaying game content on top of other UI elements or for creating AR-style experiences.

## Camera

### camera

The camera node that determines what portion of the scene is visible.

```swift
var camera: Camera?
```

- When `nil`, the scene uses `anchorPoint` for viewport positioning
- When set, the camera's position determines the viewport center
- Camera must be added to the scene's node tree

```swift
// Setup camera
let camera = Camera()
camera.position = Point(x: 400, y: 300)
scene.addChild(camera)
scene.camera = camera

// Camera follows player
scene.camera?.position = player.position
```

## Audio

### audio

The audio system for queueing sound playback commands.

```swift
var audio: AudioSystem
```

- Audio is a SIDE EFFECT of simulation - it does not affect game state
- Swift only describes WHAT sound should play and WHEN
- Runtime (JavaScript/Native) handles HOW to play
- Commands are collected per frame and consumed by the runtime

```swift
// Play a sound effect
scene.audio.play(SoundIDs.explosion, volume: 0.8, pan: -0.5)

// Play background music with fade
scene.audio.playMusic(SoundIDs.bgmLevel1, fadeDuration: 2.0)

// Stop music
scene.audio.stopMusic(fadeDuration: 1.0)
```

### audioEngine

The audio engine used to play audio from audio nodes contained in the scene.

```swift
var audioEngine: AudioEngine
```

The audio engine provides master control over all audio playback:

```swift
// Reduce overall volume
scene.audioEngine.mainMixerNode.outputVolume = 0.5

// Pause all audio
scene.audioEngine.pause()

// Resume audio
scene.audioEngine.start()

// Stop all audio
scene.audioEngine.stop()
```

### listener

A node used to determine the position of the listener for positional audio.

```swift
var listener: Node?
```

When set, audio is mixed with 2D positional characteristics. Audio from nodes further from the listener will be quieter.

```swift
// Set camera as listener for positional audio
scene.listener = scene.camera

// Or use the player node
scene.listener = player
```

See [Audio](11-Audio.md) for detailed documentation.

## Lifecycle Methods

### sceneDidLoad()

Called immediately after the scene is initialized.

```swift
func sceneDidLoad()
```

- Override to perform one-time setup
- Called before the scene is presented

### didMove(to:)

Called when the scene is presented in a view.

```swift
func didMove(to view: View)
```

- Override to start gameplay
- Called after `sceneDidLoad()`

### willMove(from:)

Called when the scene is about to be removed from a view.

```swift
func willMove(from view: View)
```

- Override to clean up resources
- Called before scene is deallocated

## Frame Cycle

### update(dt:)

Called every frame to update game logic.

```swift
func update(dt: Float)
```

- `dt` is the fixed timestep (typically 1/60 second)
- Primary location for game logic
- Override to implement gameplay

### didFinishUpdate()

Called after all update processing is complete.

```swift
func didFinishUpdate()
```

- Override for post-processing
- Called after actions (v0.2) and constraints are applied
- Last chance to modify nodes before rendering

## Frame Cycle Order

```
┌─────────────────────────────────────┐
│  1. audio.beginFrame()              │  ← Clear audio buffer
│  2. update(dt:)                     │  ← Your game logic
│  3. evaluateActions()               │  ← Process running actions
│  4. didEvaluateActions()            │  ← Post-action hook
│  5. physicsWorld.simulate()         │  ← Physics simulation
│  6. didSimulatePhysics()            │  ← Post-physics hook
│  7. applyConstraints()              │  ← Apply node constraints
│  8. didApplyConstraints()           │  ← Post-constraints hook
│  9. didFinishUpdate()               │  ← Final pre-render hook
│ 10. generateDrawCommands()          │  ← Internal: traverse tree
│ 11. render()                        │  ← Internal: draw commands
│ 12. audio.commands consumed         │  ← Runtime plays sounds
└─────────────────────────────────────┘
         Repeats every 1/60 second
```

## Coordinate Conversion

### View to Scene

```swift
func convertPoint(fromView point: Vec2) -> Vec2
```

Converts a point from view coordinates to scene coordinates.

### Scene to View

```swift
func convertPoint(toView point: Vec2) -> Vec2
```

Converts a point from scene coordinates to view coordinates.

## Usage Example

```swift
class GameScene: Scene {
    var player: Sprite!

    override func sceneDidLoad() {
        // Create player
        player = Sprite(textureID: playerTexture)
        player.position = Vec2(x: size.x / 2, y: size.y / 2)
        addChild(player)

        // Setup camera
        let camera = Camera()
        addChild(camera)
        self.camera = camera
    }

    override func update(dt: Float) {
        // Move player based on input
        if input.right {
            player.position.x += 200 * dt
        }
        if input.left {
            player.position.x -= 200 * dt
        }

        // Camera follows player
        camera?.position = player.position
    }
}

// Create and present scene
let scene = GameScene(size: Vec2(x: 800, y: 600))
scene.scaleMode = .aspectFit
view.presentScene(scene)
```

## Design Notes

### Scene as Node

Scene inherits from Node, allowing:
- Scenes to have their own transform (rarely used)
- Consistent API for adding children
- Scene can be treated as any other node

### Fixed Timestep

The `dt` parameter is always the fixed timestep value (1/60s), never the actual elapsed time. This ensures deterministic behavior:

```swift
// Always the same regardless of frame rate
func update(dt: Float) {
    // dt == 0.01666... (1/60)
    position.x += velocity.x * dt
}
```

### SpriteKit Comparison

| SpriteKit | Wisp |
|-----------|------|
| `SKScene` | `Scene` |
| `size: CGSize` | `size: Size` |
| `scaleMode: SKSceneScaleMode` | `scaleMode: ScaleMode` |
| `anchorPoint: CGPoint` | `anchorPoint: Point` |
| `backgroundColor: UIColor` | `backgroundColor: Color` |
| `camera: SKCameraNode?` | `camera: Camera?` |
| `update(_:)` with TimeInterval | `update(dt:)` with Float |
| `physicsWorld: SKPhysicsWorld` | `physicsWorld: PhysicsWorld` |
| `audioEngine: AVAudioEngine` | `audioEngine: AudioEngine` ✓ |
| `listener: SKNode?` | `listener: Node?` ✓ |
| `SKAudioNode` | `audio: AudioSystem` |
| Transparent background support | `allowsTransparency` + `Color.clear` ✓ |
