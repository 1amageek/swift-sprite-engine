# Wisp Documentation

Swift-native Web Game Engine

## Quick Start

```swift
import Wisp

class GameScene: Scene {
    override func sceneDidLoad() {
        let player = SpriteNode(color: .green, size: Size(width: 40, height: 40))
        player.position = Point(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    override func update(dt: Float) {
        // Game logic here
    }
}

// Entry point - one line to start the engine
Engine.run(GameScene(size: Size(width: 800, height: 600)))
```

## Documentation

1. [Overview](00-Overview.md) - What is Wisp and why does it exist?

## Core Concepts

2. [Node](01-Node.md) - Base class for all scene graph elements
3. [Scene](02-Scene.md) - Root node and game world container
4. [SpriteNode](03-SpriteNode.md) - Textured image display
5. [Camera](04-Camera.md) - Viewport control

## Systems

6. [Rendering](05-Rendering.md) - Dual-backend architecture (WebGPU + SwiftUI)
7. [Math Types](06-Math.md) - Vec2, Mat3, Rect, Color
8. [Input](07-Input.md) - Polling-based input system
9. [Frame Cycle](08-FrameCycle.md) - Fixed timestep game loop
10. [Audio](11-Audio.md) - Command-based audio system

## Integration

11. [WebGPU Integration](09-WebGPU-Integration.md) - JavaScript bridge and GPU rendering
12. [Build Pipeline](10-Build-Pipeline.md) - WASM compilation and asset bundling

## API Summary

### Core Types

| Type | Description |
|------|-------------|
| `Engine` | Entry point, `Engine.run(scene)` starts the game |
| `Node` | Base scene graph element |
| `Scene` | Root node, owns update loop |
| `SpriteNode` | Textured/colored rectangle |
| `Camera` | Viewport controller |

### Data Types

| Type | Description |
|------|-------------|
| `Vec2` | 2D vector (x, y) |
| `Vec3` | 3D vector (x, y, z) |
| `Mat3` | 3x3 transformation matrix |
| `Rect` | Rectangle (origin, size) |
| `Color` | RGBA color (0-1 range) |
| `TextureID` | Opaque texture reference |
| `DrawCommand` | Rendering instruction |
| `InputState` | Current input state |
| `AudioCommand` | Audio playback instruction |
| `AudioSystem` | Audio command queue |

### Enums

| Type | Values |
|------|--------|
| `ScaleMode` | `fill`, `aspectFit`, `aspectFill`, `resizeFill` |

## Design Principles

1. **Swift-first**: Game logic in Swift, not JavaScript
2. **Web-first**: WASM + WebGPU are primary targets
3. **Deterministic**: Fixed timestep, reproducible behavior
4. **Explicit**: No hidden schedulers or magic
5. **Minimalist**: Every API must earn its existence

## Version Scope

### Current

**Included:**
- Engine entry point (`Engine.run(scene)`)
- Scene graph (Node, Scene, SpriteNode, Camera, Label)
- Transform propagation
- Fixed timestep update loop
- DrawCommand-based rendering
- Dual renderer (WebGPU via SwiftWebGPU + SwiftUI Preview)
- Polling input system
- Action system (animations)
- Constraints system
- Physics (PhysicsWorld, PhysicsBody, PhysicsJoint)
- Audio command system
- Tile maps (TileMap, TileSet, TileGroup)
- Particle system (EmitterNode)
- Effects (EffectNode, LightNode, ShapeNode)
- Shader support
- Warp geometry

**Architecture:**
- Audio is command-based (Swift describes, runtime plays)
- No strings across Swift/JS boundary (numeric IDs only)
- Deterministic simulation (audio doesn't affect game state)

## Requirements

- Swift 6.2+
- WebGPU-capable browser (Chrome 113+, Safari 18+)
- Xcode 16+ for `#Preview` development
