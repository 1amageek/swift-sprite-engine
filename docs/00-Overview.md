# Wisp Overview

## What is Wisp?

Wisp is a Swift-native 2D game engine targeting WebAssembly + WebGPU. It proves that Swift is a viable language for writing real-time games on the Web.

## Design Philosophy

### Swift-first
Users write game logic in Swift. Swift is the source of truth for all gameplay code.

### Web-first
WebAssembly + WebGPU are first-class targets. Desktop or native ports are secondary considerations.

### Deterministic
Same input produces same output. Fixed timestep simulation ensures reproducible gameplay.

### Explicit
No hidden schedulers or implicit behaviors. The `update(dt:)` method drives everything.

### Minimalist
Every API must earn its existence. Removing features is preferred over adding them.

## Quick Start

```swift
import Wisp

Engine.run(GameScene(size: Size(width: 800, height: 600)))
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Game Code (Swift)                   │
│                   Scene, Node, SpriteNode, etc.             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Wisp Core (Swift)                       │
│        Update loop, Transform propagation, Commands         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Rendering Abstraction                      │
│                      DrawCommand[]                          │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│  WebGPURenderer (Swift) │     │   SwiftUI Canvas        │
│   via SwiftWebGPU       │     │   Development Preview   │
└─────────────────────────┘     └─────────────────────────┘
```

## Layer Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **Swift (WASM)** | Game logic, scene graph, transform propagation, WebGPU rendering via SwiftWebGPU |
| **JavaScript** | WASM loading, input polling, texture loading, audio playback, animation loop |
| **Boundary** | Numeric data only (no objects, no strings across boundary) |

## Requirements

- **Swift 6.2+** with official WebAssembly SDK
- Modern browser with WebGPU support (Chrome 113+, Edge 113+, Safari 18+)
- Xcode 16+ for `#Preview` development workflow

## Comparison with SpriteKit

| Aspect | SpriteKit | Wisp |
|--------|-----------|------|
| Platform | Apple only | Web (any browser) |
| Language | Swift/ObjC | Swift |
| Rendering | Metal/OpenGL | WebGPU via SwiftWebGPU |
| Scene Graph | SKNode tree | Node tree (similar) |
| Actions | SKAction | Action (implemented) |
| Physics | SKPhysicsBody | PhysicsBody (implemented) |
| Audio | SKAudioNode | AudioSystem (command-based) |
| Editor | Xcode Scene Editor | None (code-only) |

## What Wisp is NOT

- Not a SpriteKit reimplementation
- Not Apple API compatible
- Not a full-featured AAA engine
- Not a visual editor or tooling suite
- Not a cross-platform abstraction layer
