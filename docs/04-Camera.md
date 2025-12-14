# Camera

## Overview

`Camera` is a node that determines which portion of the scene is visible in the view. By moving, rotating, or scaling the camera, you control what the player sees.

`Camera` inherits from `Node`. Its position, rotation, and scale properties directly control the viewport.

## Definition

```swift
class Camera: Node {
    // Inherits from Node:
    // - position: Vec2
    // - rotation: Float
    // - scale: Vec2
    // - All hierarchy properties

    // Camera-specific (computed)
    func contains(_ node: Node) -> Bool
    func containedNodes() -> [Node]
}
```

## Using a Camera

### Setup

```swift
// Create camera
let camera = Camera()

// Add to scene (required!)
scene.addChild(camera)

// Assign as scene's camera
scene.camera = camera
```

**Important**: The camera must be added to the scene's node tree before being assigned as the scene's camera.

### Viewport Control

The camera's inherited properties control the viewport:

| Property | Effect |
|----------|--------|
| `position` | Center of the viewport |
| `rotation` | Rotates the entire view |
| `scale` | Zooms in (>1) or out (<1) |

```swift
// Move viewport
camera.position = Vec2(x: 500, y: 300)

// Rotate view 45 degrees
camera.rotation = .pi / 4

// Zoom in 2x
camera.scale = Vec2(x: 2, y: 2)

// Zoom out to see more
camera.scale = Vec2(x: 0.5, y: 0.5)
```

## Camera Behaviors

### Following a Target

```swift
class GameScene: Scene {
    var player: Sprite!

    override func update(dt: Float) {
        // Simple follow
        camera?.position = player.position
    }
}
```

### Smooth Following

```swift
override func update(dt: Float) {
    guard let camera = camera else { return }

    let target = player.position
    let current = camera.position

    // Lerp toward target
    let smoothing: Float = 5.0
    camera.position = Vec2(
        x: current.x + (target.x - current.x) * smoothing * dt,
        y: current.y + (target.y - current.y) * smoothing * dt
    )
}
```

### Bounded Camera

```swift
override func update(dt: Float) {
    guard let camera = camera else { return }

    // Follow player
    camera.position = player.position

    // Clamp to level bounds
    let halfWidth = size.x / 2
    let halfHeight = size.y / 2

    camera.position.x = max(halfWidth, min(levelWidth - halfWidth, camera.position.x))
    camera.position.y = max(halfHeight, min(levelHeight - halfHeight, camera.position.y))
}
```

### Camera Shake

```swift
var shakeIntensity: Float = 0
var shakeDecay: Float = 5.0

func shake(intensity: Float) {
    shakeIntensity = intensity
}

override func update(dt: Float) {
    // Apply shake offset
    if shakeIntensity > 0 {
        let offsetX = Float.random(in: -shakeIntensity...shakeIntensity)
        let offsetY = Float.random(in: -shakeIntensity...shakeIntensity)
        camera?.position = player.position + Vec2(x: offsetX, y: offsetY)

        // Decay shake
        shakeIntensity = max(0, shakeIntensity - shakeDecay * dt)
    } else {
        camera?.position = player.position
    }
}
```

### Zoom Animation

```swift
var targetZoom: Float = 1.0
var zoomSpeed: Float = 2.0

func zoomTo(_ zoom: Float) {
    targetZoom = zoom
}

override func update(dt: Float) {
    guard let camera = camera else { return }

    let currentZoom = camera.scale.x
    let newZoom = currentZoom + (targetZoom - currentZoom) * zoomSpeed * dt
    camera.scale = Vec2(x: newZoom, y: newZoom)
}
```

## Node Visibility

### contains(_:)

Check if a node is visible in the camera's viewport.

```swift
func contains(_ node: Node) -> Bool
```

```swift
if camera.contains(enemy) {
    // Enemy is on screen
    enemy.isActive = true
}
```

### containedNodes()

Get all nodes currently visible in the viewport.

```swift
func containedNodes() -> [Node]
```

```swift
// Only update visible enemies
let visibleEnemies = camera.containedNodes().compactMap { $0 as? Enemy }
for enemy in visibleEnemies {
    enemy.updateAI(dt: dt)
}
```

## Without a Camera

When no camera is assigned, the scene uses `anchorPoint` to position the viewport:

```swift
// No camera - viewport controlled by anchorPoint
scene.camera = nil
scene.anchorPoint = Vec2(x: 0, y: 0)  // Origin at bottom-left
scene.anchorPoint = Vec2(x: 0.5, y: 0.5)  // Origin at center
```

## HUD and UI Layers

Nodes added as children of the camera move with the viewport, creating a HUD effect:

```swift
// Create HUD elements as camera children
let scoreLabel = Label(text: "Score: 0")
scoreLabel.position = Vec2(x: -350, y: 250)  // Relative to camera
camera.addChild(scoreLabel)

let healthBar = Sprite(color: .red, size: Vec2(x: 100, y: 10))
healthBar.position = Vec2(x: -350, y: 230)
camera.addChild(healthBar)

// These stay fixed on screen regardless of camera movement
```

## Coordinate Conversion

Convert between screen and world coordinates:

```swift
// Touch position (view coords) to world position
let touchInView = Vec2(x: touchX, y: touchY)
let touchInScene = scene.convertPoint(fromView: touchInView)

// World position to screen position
let enemyScreenPos = scene.convertPoint(toView: enemy.worldPosition)
```

## Design Notes

### Camera as Node

Making Camera a Node subclass provides:
- Natural transform inheritance
- Children become HUD elements
- Consistent API with other nodes
- Position/rotation/scale reuse

### SpriteKit Comparison

| SpriteKit | Wisp |
|-----------|------|
| `SKCameraNode` | `Camera` |
| `containedNodeSet()` | `containedNodes()` |
| `contains(_:)` | `contains(_:)` |
| Position controls viewport | Same |
| Scale controls zoom | Same |

### Multiple Cameras

While only one camera can be the scene's active camera, you can:
- Create multiple cameras
- Switch between them
- Animate transitions

```swift
let mainCamera = Camera()
let cinemaCamera = Camera()

// Switch cameras
func showCutscene() {
    scene.camera = cinemaCamera
}

func resumeGameplay() {
    scene.camera = mainCamera
}
```
