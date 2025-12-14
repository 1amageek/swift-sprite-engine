# Wisp

A Swift-native 2D game engine for WebAssembly + WebGPU.

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
        if input.left { player.position.x -= 200 * dt }
        if input.right { player.position.x += 200 * dt }
    }
}

// One line to start
Engine.run(GameScene(size: Size(width: 800, height: 600)))
```

## Features

- **Swift-first**: Write game logic entirely in Swift
- **WebGPU rendering**: Hardware-accelerated graphics via [SwiftWebGPU](https://github.com/1amageek/swift-webgpu)
- **SpriteKit-like API**: Familiar scene graph, actions, and physics
- **Dual-backend**: WebGPU for production, SwiftUI Canvas for Xcode Preview

## Requirements

- Swift 6.2+
- [Swift WASM SDK](https://www.swift.org/documentation/articles/wasm-getting-started.html)
- WebGPU-capable browser (Chrome 113+, Edge 113+, Safari 18+)

## Installation

### As a dependency

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/1amageek/Wisp", branch: "main"),
]
```

### Build for WebAssembly

```bash
# Install Swift WASM SDK (if not already installed)
swift sdk install https://github.com/aspect-build/aspect-ios-sdk/releases/download/swift-wasm-6.2-RELEASE/swift-wasm-6.2-RELEASE_wasm.artifactbundle.zip

# Build
cd your-game
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js

# Run locally
cd .build/plugins/PackageToJS/outputs/Package
python3 -m http.server 8080
# Open http://localhost:8080
```

## Architecture

```
Engine.run(scene)
       │
       ▼
┌──────────────────────────────────────────────┐
│              Swift (WASM)                    │
│  Scene graph, Actions, Physics, Input        │
│                    │                         │
│                    ▼                         │
│  DrawCommand[] ─► WebGPURenderer             │
│                   (via SwiftWebGPU)          │
└──────────────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│              WebGPU                          │
│  GPUDevice, RenderPipeline, Buffers          │
└──────────────────────────────────────────────┘
```

## Core Types

| Type | Description |
|------|-------------|
| `Engine` | Entry point (`Engine.run(scene)`) |
| `Scene` | Root node, game world container |
| `Node` | Base class for scene graph elements |
| `SpriteNode` | Displays colored rectangles or textures |
| `Camera` | Controls viewport |
| `Action` | Animations and timed behaviors |

## Example

See the [example](./example) directory for a complete working game.

```bash
cd example
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js
cp -r .build/plugins/PackageToJS/outputs/Package/* WispExample/
cd WispExample && python3 -m http.server 8080
```

## Documentation

- [Overview](./docs/00-Overview.md)
- [Node](./docs/01-Node.md)
- [Scene](./docs/02-Scene.md)
- [SpriteNode](./docs/03-SpriteNode.md)
- [WebGPU Integration](./docs/09-WebGPU-Integration.md)
- [Build Pipeline](./docs/10-Build-Pipeline.md)

## Dependencies

- [SwiftWebGPU](https://github.com/1amageek/swift-webgpu) - Swift bindings for WebGPU
- [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit) - Swift-JavaScript interop

## License

MIT
