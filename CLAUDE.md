# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpriteEngine is a Swift-native Web game engine targeting WebAssembly + WebGPU. The goal is to prove Swift is viable for writing real-time games on the Web.

**Swift 6.2+ only** - Uses official WebAssembly SDK from swift.org

## Quick Start

```swift
import SpriteEngine

class GameScene: SNScene {
    override func sceneDidLoad() {
        let player = SNSpriteNode(color: .green, size: Size(width: 40, height: 40))
        player.position = Point(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    override func update(_ dt: Float) {
        // Game logic here
    }
}

// SwiftUI Preview
struct ContentView: View {
    var body: some View {
        SpriteView(scene: GameScene(size: Size(width: 800, height: 600)))
    }
}

// With debug options
SpriteView(
    scene: gameScene,
    debugOptions: [.showsFPS, .showsNodeCount]
)
```

## Build Commands

```bash
# Build the package (macOS)
swift build

# Run tests
swift test

# Run a single test
swift test --filter SpriteEngineTests.testName

# Build for WebAssembly (requires swift-6.2.3-RELEASE_wasm SDK)
cd example
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js

# Copy output to web directory
cp -r .build/plugins/PackageToJS/outputs/Package/* SpriteEngineExample/

# Start local server for testing
cd SpriteEngineExample && python3 -m http.server 8080
```

## Architecture

### Layer Separation

The codebase has a strict boundary between Swift and JavaScript:

- **Swift (WASM)**: Game logic, scene graph, transform propagation, WebGPU rendering (via SwiftWebGPU)
- **JavaScript**: WASM loading, input polling, audio playback, animation loop (requestAnimationFrame)
- **Boundary rule**: Swift ↔ JS communication uses numeric data only (no strings)

### Type Naming Convention

SpriteEngine uses the **SN prefix** for SpriteKit-equivalent types (similar to SK prefix in SpriteKit):

| SpriteKit | SpriteEngine | Description |
|-----------|--------------|-------------|
| `SKNode` | `SNNode` | Base node class |
| `SKScene` | `SNScene` | Scene container |
| `SKSpriteNode` | `SNSpriteNode` | Textured sprite |
| `SKView` | `SNView` | View logic (platform-agnostic) |
| `SpriteView` | `SpriteView` | SwiftUI integration |
| `SKCameraNode` | `SNCamera` | Camera node |
| `SKLabelNode` | `SNLabelNode` | Text label |
| `SKShapeNode` | `SNShapeNode` | Vector shapes |
| `SKAction` | `SNAction` | Animations |
| `SKTexture` | `SNTexture` | Texture resource |
| `SKPhysicsBody` | `SNPhysicsBody` | Physics body |
| `SKPhysicsWorld` | `SNPhysicsWorld` | Physics simulation |
| `SKConstraint` | `SNConstraint` | Node constraints |
| `SKTransition` | `SNTransition` | Scene transitions |
| `SKEmitterNode` | `SNEmitterNode` | Particle emitter |
| `SKEffectNode` | `SNEffectNode` | Effect container |
| `SKLightNode` | `SNLightNode` | 2D light |
| `SKFieldNode` | `SNFieldNode` | Physics field |
| `SKTileMapNode` | `SNTileMap` | Tile map |

**Geometry types do NOT use the SN prefix**: `Point`, `Size`, `Rect`, `Color`, `Vector2`, `Region`, `Range`

### Core Types

| Type | Purpose |
|------|---------|
| `SNScene` | Game world, owns `update(_:)` entry point |
| `SNNode` | Scene graph base element with spatial hierarchy |
| `SNSpriteNode` | Node subclass with size and texture |
| `SNView` | Platform-agnostic view logic (like SKView) |
| `SpriteView` | SwiftUI view for rendering scenes |
| `Point` / `Size` | 2D coordinates/dimensions, no Foundation dependency |
| `InputState` | Polled input (left/right/up/down/action booleans) |
| `DrawCommand` | Internal rendering instruction |
| `AudioCommand` | Audio playback instruction (soundID/channel/volume) |
| `AudioSystem` | Per-scene audio command queue |

### Design Constraints

1. **Fixed timestep only**: Variable dt is forbidden. Use accumulator-based stepping at 1/60s.
2. **Deterministic**: Same input must produce same output.
3. **Explicit**: No hidden schedulers or implicit actions. `update(_:)` drives everything.
4. **No Foundation**: Math types must be POD-style with no external dependencies.
5. **Minimalism**: APIs must earn their existence.

### API Design Principle

**SpriteKit-like interface, platform-optimized implementation.**

The developer-facing API should be familiar to SpriteKit users:
```swift
// Developer writes this (SpriteKit-style)
let sprite = SNSpriteNode(imageNamed: "player.png")
sprite.position = Point(x: 100, y: 200)
scene.addChild(sprite)
```

Internal implementation is optimized for each platform:
```
Resource: "player.png"
    │
    ├─ Web (Production):
    │   fetch("assets/player.png") → GPUTexture → WebGPU rendering
    │
    └─ Swift (Preview):
        Bundle.main → CGImage → SwiftUI Canvas rendering
```

**Key principles**:
- Same resource files used across all platforms
- Resource referenced by name (string), loaded differently per platform
- Runtime communication uses numeric IDs for efficiency
- Developer code is platform-agnostic

### Rendering Architecture

SpriteEngine uses a **dual-backend rendering** design:

| Environment | Renderer | Purpose |
|-------------|----------|---------|
| Browser (WASM) | WebGPURenderer (Swift via SwiftWebGPU) | Production runtime |
| Xcode | SwiftUI Canvas via `SpriteView` | `#Preview` during development |

```
SpriteView(scene: myScene)
       ↓
┌──────────────────────────────────────────────────────────────┐
│                    Game Loop (per frame)                     │
├──────────────────────────────────────────────────────────────┤
│  SNScene.update(dt) → Node tree traversal → DrawCommand[]    │
│                                                ↓             │
│              ┌─────────────────────────────────┴───────────┐ │
│              ↓                                             ↓ │
│       WebGPURenderer (Swift)                   SpriteView    │
│       via SwiftWebGPU                      (SwiftUI Canvas)  │
│       (Production/WASM)                      (Development)   │
└──────────────────────────────────────────────────────────────┘
```

**Key principle**: Swift produces platform-agnostic `DrawCommand[]`. Rendering backends consume these commands. Game logic remains identical across all environments.

### View Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  SpriteView (SwiftUI View)                                  │
│  - Matches SpriteKit's SpriteView API                       │
│  - Options: allowsTransparency, ignoresSiblingOrder, etc.   │
│  - DebugOptions: showsFPS, showsNodeCount, showsPhysics     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  SNView (Platform-agnostic)                                 │
│  - Scene presentation and transitions                       │
│  - Update cycle management                                  │
│  - Coordinate conversion                                    │
│  - Debug statistics (FPS, node count, draw count)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  SNScene                                                    │
│  - Scene graph root                                         │
│  - Game logic via update(_:)                                │
│  - Physics, constraints, actions                            │
└─────────────────────────────────────────────────────────────┘
```

### SpriteView API

```swift
// Basic usage
SpriteView(scene: myScene)

// Full options
SpriteView(
    scene: myScene,
    transition: .crossFade(duration: 1.0),
    isPaused: false,
    preferredFramesPerSecond: 60,
    options: [.allowsTransparency, .ignoresSiblingOrder],
    debugOptions: [.showsFPS, .showsNodeCount, .showsPhysics],
    shouldRender: { time in true }
)
```

**SpriteView.Options**:
- `.allowsTransparency` - Allow transparent background
- `.ignoresSiblingOrder` - May improve performance
- `.shouldCullNonVisibleNodes` - Cull off-screen nodes

**SpriteView.DebugOptions**:
- `.showsFPS` - Display frame rate
- `.showsNodeCount` - Display node count
- `.showsDrawCount` - Display draw calls
- `.showsQuadCount` - Display quad count
- `.showsPhysics` - Display physics bodies
- `.showsFields` - Display physics fields

### SNView API

```swift
let view = SNView()

// Present scene
view.presentScene(myScene)

// Present with transition
view.presentScene(newScene, transition: .crossFade(duration: 1.0))

// Configuration
view.isPaused = false
view.preferredFramesPerSecond = 60
view.ignoresSiblingOrder = true
view.shouldCullNonVisibleNodes = true

// Debug options
view.showsFPS = true
view.showsNodeCount = true
view.showsPhysics = true

// Coordinate conversion
let scenePoint = view.convert(viewPoint, to: scene)
let viewPoint = view.convert(scenePoint, from: scene)

// Statistics
print(view.currentFPS)
print(view.nodeCount)
print(view.drawCount)
```

### Swift ↔ WebGPU Integration

SpriteEngine uses **SwiftWebGPU** to call WebGPU APIs directly from Swift via JavaScriptKit:

```
Swift (Wasm)
   ↓  (JavaScriptKit bindings)
SwiftWebGPU (Swift wrapper for WebGPU)
   ↓
WebGPU (GPUDevice, CommandEncoder, Pipeline)
```

**SwiftWebGPU provides**:
- Type-safe Swift API for WebGPU
- Async/await support for GPU operations
- Direct access to GPUDevice, GPURenderPipeline, GPUBuffer, etc.

### Responsibility Assignment

| Layer | Responsibility |
|-------|---------------|
| **Swift** | Scene state, Transform calculation, WebGPU rendering, camera/input logic |
| **JavaScript** | WASM loading, requestAnimationFrame loop, input polling, texture loading |
| **WebGPU** | GPU rendering via Swift's WebGPURenderer |
| **WebAudio** | Sound effects, music (JS-side) |

### WASM Export Functions

Swift exports functions to JavaScript using `@_expose(wasm)`:

```swift
@_expose(wasm, "wisp_initAsync")
@_cdecl("wisp_initAsync")
public func wisp_initAsync() { ... }

@_expose(wasm, "wisp_tick")
@_cdecl("wisp_tick")
public func wisp_tick(_ deltaTime: Float) { ... }
```

### Known Constraints

- **Safari**: WebGPU implementation may lag behind Chrome/Firefox
- **Debugging**: GPU errors should be logged via `consoleLog()` helper
- **Texture loading**: Images loaded via JavaScript, then passed to Swift

---

## Detailed Architecture (SpriteKit-inspired)

### Node Hierarchy

```
SNNode (base class)
├── position: Point
├── rotation: Float
├── scale: Size
├── zPosition: Float
├── alpha: Float
├── isHidden: Bool
├── children: [SNNode]
├── parent: SNNode?
│
├── SNSpriteNode : SNNode
│   ├── size: Size
│   ├── texture: SNTexture?
│   ├── anchorPoint: Point
│   └── color: Color
│
├── SNCamera : SNNode
│   └── (position/scale from Node controls viewport)
│
├── SNEffectNode : SNNode (for shaders and effects)
│   ├── shader: Shader?
│   ├── blendMode: BlendMode
│   ├── warpGeometry: WarpGeometry?
│   ├── shouldRasterize: Bool
│   └── shouldEnableEffects: Bool
│
├── SNEmitterNode : SNNode (particles)
│   └── (particle emission properties)
│
├── SNLightNode : SNNode (2D lighting)
│   └── (light color, falloff, etc.)
│
└── SNScene : SNEffectNode (root node, inherits effect capabilities)
    ├── size: Size
    ├── scaleMode: ScaleMode
    ├── camera: SNCamera?
    ├── backgroundColor: Color
    ├── audio: AudioSystem
    ├── physicsWorld: SNPhysicsWorld
    └── update(_:) → frame cycle entry
```

**Design notes**:
- SNScene inherits from SNEffectNode (like SpriteKit's SKScene inherits SKEffectNode)
  - This allows applying shaders and warp effects to the entire scene
- SNCamera IS a SNNode (position/rotation controls what's visible)
- SNEmitterNode and SNLightNode inherit directly from SNNode (matching SpriteKit)
- All spatial properties propagate to children

### Frame Cycle

```
┌─────────────────────────────────────────────────────────────┐
│                    Frame Cycle (1/60s)                      │
├─────────────────────────────────────────────────────────────┤
│  1. audio.beginFrame()       ← Clear audio buffer           │
│  2. scene.update(dt)         ← User game logic              │
│  3. evaluateActions()        ← Process running actions      │
│  4. didEvaluateActions()     ← Post-action hook             │
│  5. physicsWorld.simulate()  ← Physics simulation           │
│  6. didSimulatePhysics()     ← Post-physics hook            │
│  7. applyConstraints()       ← Apply node constraints       │
│  8. didApplyConstraints()    ← Post-constraints hook        │
│  9. didFinishUpdate()        ← Final user hook              │
│ 10. generateDrawCommands()   ← Traverse tree, emit commands │
│ 11. render()                 ← Backend consumes commands    │
│ 12. processAudio()           ← Runtime plays audio commands │
└─────────────────────────────────────────────────────────────┘
```

### Scene Configuration

```swift
enum ScaleMode {
    case fill           // Stretch to fill view (aspect ratio ignored)
    case aspectFit      // Scale to fit, letterbox if needed
    case aspectFill     // Scale to fill, crop if needed
    case resizeFill     // Resize scene to match view
}
```

**anchorPoint**: Point (0,0)-(1,1) defines where scene origin maps to view
- (0, 0) = bottom-left
- (0.5, 0.5) = center
- (1, 1) = top-right

### Transform Propagation

World transform = parent.worldTransform * localTransform

```swift
// SNNode computes world position for rendering:
var worldPosition: Point {
    guard let parent else { return position }
    return parent.worldTransform * position
}
```

### DrawCommand Structure

`DrawCommand` is an **internal** type used for rendering communication:

```swift
internal struct DrawCommand {
    var worldPosition: Point
    var worldRotation: Float
    var worldScale: Size
    var size: Size
    var anchorPoint: Point
    var textureID: TextureID  // Internal type
    var color: Color
    var alpha: Float
    var zPosition: Float
}
```

Commands are sorted by `zPosition` before rendering. Game developers never interact with `DrawCommand` directly—it's an implementation detail of the rendering pipeline.

### Texture Management

Textures use a **SpriteKit-like public API** with internal ID management:

```swift
// Public API (developer-facing)
public final class SNTexture {
    public let name: String
    public var size: Size { get }  // Lazily loaded

    public init(imageNamed: String)
    public func preload()
    public static func preload(_ textures: [SNTexture], completion: @escaping () -> Void)
}

// Internal (hidden from developers)
internal struct TextureID: RawRepresentable {
    let rawValue: UInt32
}
```

**Developer usage** (SpriteKit-style):
```swift
let sprite = SNSpriteNode(imageNamed: "player.png")
// or
let texture = SNTexture(imageNamed: "player.png")
let sprite = SNSpriteNode(texture: texture)
```

**Flow**:
1. Developer creates `SNTexture(imageNamed: "player.png")`
2. `TextureRegistry` assigns internal `TextureID`
3. Platform-specific loading:
   - Web: JS `fetch()` → GPUTexture
   - Preview: `Bundle.main` → CGImage
4. `DrawCommand` carries internal `TextureID`
5. Renderer looks up texture by ID

### Camera System

```swift
class SNCamera: SNNode {
    // Inherits position, rotation, scale from SNNode
    var zoom: Float  // Controls viewport size

    func viewport(for sceneSize: Size) -> Rect
    func contains(_ node: SNNode, sceneSize: Size) -> Bool
    func containedNodeSet() -> Set<SNNode>
    func smoothFollow(target: Point, smoothing: Float, dt: Float)
    func clampToBounds(_ bounds: Rect, sceneSize: Size)
}

class SNScene: SNEffectNode {
    var camera: SNCamera?

    func convertPoint(fromView point: Point, viewSize: Size) -> Point
    func convertPoint(toView point: Point, viewSize: Size) -> Point
}
```

**Viewport calculation**:
- If camera is set: viewport centered on camera.worldPosition
- If no camera: use scene.anchorPoint

### Input Handling

```swift
struct InputState {
    // Digital inputs
    var left: Bool
    var right: Bool
    var up: Bool
    var down: Bool
    var action: Bool
    var action2: Bool
    var pause: Bool

    // Pointer (mouse/touch)
    var pointerPosition: Point
    var pointerDown: Bool
}

// Polled each frame from JS
// No events, just state
```

### Color

```swift
struct Color {
    var red: Float    // 0-1
    var green: Float
    var blue: Float
    var alpha: Float

    static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
    static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)
    static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
    static let red = Color(red: 1, green: 0, blue: 0, alpha: 1)
    static let green = Color(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue = Color(red: 0, green: 0, blue: 1, alpha: 1)
}
```

### Audio System

Audio uses a **command-based architecture**:

```swift
// Play sound effect (channel 0, overlapping)
scene.audio.play(SoundIDs.explosion, volume: 0.8, pan: -0.5)

// Play background music (channel 1, exclusive)
scene.audio.playMusic(SoundIDs.bgmLevel1, fadeDuration: 2.0)

// Stop music with fade
scene.audio.stopMusic(fadeDuration: 1.0)
```

**Key design principles**:
- **Swift describes, runtime plays** - No actual audio playback in Swift
- **Commands are POD** - Plain Old Data with UInt16 soundID, no strings
- **Per-frame buffer** - Commands collected each frame, consumed by runtime
- **Deterministic** - Audio timing doesn't affect game logic

```swift
struct AudioCommand {
    var type: AudioCommandType    // play, stop, setVolume, stopAll
    var soundID: UInt16           // index into preloaded sound array
    var channel: UInt8            // 0=SFX (overlap), 1+=exclusive
    var volume: Float             // 0.0 to 1.0
    var pitch: Float              // playback speed
    var pan: Float                // -1.0 to 1.0
    var loops: Bool
    var fadeDuration: Float
}
```

---

## Current Scope

**Included**: SNScene, SNNode, SNSpriteNode, SNCamera, SNLabelNode, SNShapeNode, SNAction, SNTexture, SNTextureAtlas, SNPhysicsWorld, SNPhysicsBody, SNPhysicsJoint, SNConstraint, SNTileMap, TileSet, SNEmitterNode, SNEffectNode, SNLightNode, SNFieldNode, SNCropNode, SNReferenceNode, SNTransition, SNView, SpriteView, Point, Size, Color, InputState, DrawCommand, AudioCommand, AudioSystem, Shader, WarpGeometry, fixed-timestep loop, SwiftUI Canvas rendering, ScaleMode

**Architecture**: Audio and rendering are command-based (Swift describes intent, runtime executes)

---

## Future Considerations

- Asset pipeline automation
- Editor tooling
- Serialization/deserialization
- Networking/multiplayer support
