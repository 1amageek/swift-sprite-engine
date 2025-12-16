# Rendering

## Overview

SpriteEngine uses a **dual-backend rendering** architecture:
- **WebGPU** (JavaScript): Production runtime in browsers
- **SwiftUI Canvas**: Development preview in Xcode

Swift generates platform-agnostic `DrawCommand` arrays. Rendering backends consume these commands independently.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Scene Graph                             │
│              (Node tree with Sprites)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 DrawCommand Generation                      │
│        Traverse tree → Transform → Sort by zPosition        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    DrawCommand[]                            │
│           Platform-agnostic rendering data                  │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│     WebGPURenderer      │     │    CanvasRenderer       │
│     (JavaScript)        │     │      (internal)         │
│                         │     │                         │
│  - GPUDevice            │     │  - 9-slice rendering    │
│  - RenderPipeline       │     │  - Sprite rendering     │
│  - Texture atlas        │     │  - Label rendering      │
│  - Instanced batching   │     │  - Shape rendering      │
└─────────────────────────┘     └─────────────────────────┘
                                              ▲
                                              │
                                ┌─────────────────────────┐
                                │       SpriteView        │
                                │    (public SwiftUI)     │
                                │                         │
                                │  - Input handling       │
                                │  - Debug overlays       │
                                │  - Scene transitions    │
                                └─────────────────────────┘
```

## DrawCommand

The fundamental unit of rendering data.

```swift
struct DrawCommand {
    // Transform (world space)
    var worldPosition: Point
    var worldRotation: Float
    var worldScale: Size

    // Sprite data
    var size: Size
    var anchorPoint: Point
    var textureID: TextureID      // .none = no texture (solid color)

    // Appearance
    var color: Color
    var alpha: Float
    var zPosition: Float

    // 9-slice rendering
    var centerRect: Rect          // Default: (0, 0, 1, 1) = no 9-slice
}
```

### Memory Layout

For efficient transfer to WebGPU, DrawCommand is designed as a POD (Plain Old Data) struct:

```swift
// Packed for GPU buffer transfer
struct DrawCommand {
    var worldPosition: Point       // 8 bytes (2 × Float)
    var worldRotation: Float       // 4 bytes
    var worldScale: Size           // 8 bytes
    var size: Size                 // 8 bytes
    var anchorPoint: Point         // 8 bytes
    var textureID: TextureID       // 4 bytes
    var color: Color               // 16 bytes (4 × Float)
    var alpha: Float               // 4 bytes
    var zPosition: Float           // 4 bytes
    var centerRect: Rect           // 16 bytes (4 × Float)
}
```

## Command Generation

### Process

```swift
func generateDrawCommands() -> [DrawCommand] {
    var commands: [DrawCommand] = []

    func traverse(_ node: SNNode) {
        // Skip hidden nodes
        guard !node.isHidden else { return }

        // Generate command for drawable nodes
        if let sprite = node as? SNSpriteNode {
            commands.append(sprite.makeDrawCommand())
        }

        // Recurse children
        for child in node.children {
            traverse(child)
        }
    }

    traverse(self)

    // Sort by zPosition for correct layering
    commands.sort { $0.zPosition < $1.zPosition }

    return commands
}
```

### Sprite Command Generation

```swift
extension SNSpriteNode {
    func makeDrawCommand() -> DrawCommand {
        DrawCommand(
            worldPosition: worldPosition,
            worldRotation: worldRotation,
            worldScale: worldScale,
            size: size,
            anchorPoint: anchorPoint,
            textureID: texture?.textureID ?? .none,
            color: color,
            alpha: worldAlpha,
            zPosition: zPosition,
            centerRect: centerRect
        )
    }
}
```

## WebGPU Renderer (JavaScript)

The production renderer runs in JavaScript, using WebGPU for hardware-accelerated rendering.

### Responsibilities

| Task | Description |
|------|-------------|
| Pipeline setup | Create GPUDevice, shaders, pipeline |
| Texture management | Load images, create GPUTextures, manage atlas |
| Buffer management | Create vertex/instance buffers |
| Command processing | Read DrawCommands from WASM memory |
| Batching | Group commands by texture for efficiency |
| Frame submission | Encode and submit render pass |

### Data Transfer

Swift arrays cannot be passed directly to JavaScript. Use shared linear memory:

```javascript
// JavaScript side
function readDrawCommands(wasmMemory, offset, count) {
    const view = new DataView(wasmMemory.buffer);
    const commands = [];

    for (let i = 0; i < count; i++) {
        const base = offset + i * COMMAND_SIZE;
        commands.push({
            worldPosition: {
                x: view.getFloat32(base + 0, true),
                y: view.getFloat32(base + 4, true)
            },
            worldRotation: view.getFloat32(base + 8, true),
            // ... rest of fields
        });
    }

    return commands;
}
```

### Instanced Rendering

For efficiency, sprites with the same texture are batched:

```javascript
// Group by texture
const batches = new Map();
for (const cmd of commands) {
    const key = cmd.textureID;
    if (!batches.has(key)) batches.set(key, []);
    batches.get(key).push(cmd);
}

// Render each batch with instancing
for (const [textureID, batch] of batches) {
    bindTexture(textureID);
    uploadInstanceData(batch);
    drawInstanced(batch.length);
}
```

## SwiftUI Preview Renderer

For development, a SwiftUI-based renderer enables `#Preview` workflow.

### Architecture

The preview rendering system consists of two components:

| Component | Visibility | Purpose |
|-----------|------------|---------|
| `CanvasRenderer` | internal | Core rendering logic (sprites, labels, shapes, 9-slice) |
| `SpriteView` | public | SwiftUI View with input handling and debug overlays |

### CanvasRenderer

The internal renderer handles all drawing operations:

```swift
internal final class CanvasRenderer {
    func render(
        scene: SNScene,
        commands: [DrawCommand],
        labelCommands: [LabelDrawCommand],
        in context: inout GraphicsContext,
        size: CGSize,
        showAudioIndicator: Bool = true
    )

    func renderCommand(_ command: DrawCommand, ...)
    func renderNineSlice(cgImage:, centerRect:, destRect:, context:)
    func renderLabelCommand(_ command: LabelDrawCommand, ...)
    func renderShapeNodes(from node: SNNode, ...)
    func renderAudioIndicator(context:, size:)
}
```

### SpriteView

The public SwiftUI View for displaying scenes:

```swift
public struct SpriteView: View {
    public init(
        scene: SNScene,
        transition: SNTransition? = nil,
        isPaused: Binding<Bool>? = nil,
        preferredFramesPerSecond: Int = 60,
        options: Options = [],
        debugOptions: DebugOptions = []
    )
}
```

### Usage

```swift
#Preview {
    SpriteView(
        scene: GameScene(size: Size(width: 398, height: 224)),
        debugOptions: [.showsFPS, .showsNodeCount]
    )
}
```

### Debug Options

```swift
public struct DebugOptions: OptionSet {
    public static let showsFPS = DebugOptions(rawValue: 1 << 0)
    public static let showsNodeCount = DebugOptions(rawValue: 1 << 1)
    public static let showsDrawCount = DebugOptions(rawValue: 1 << 2)
    public static let showsQuadCount = DebugOptions(rawValue: 1 << 3)
    public static let showsPhysics = DebugOptions(rawValue: 1 << 4)
    public static let showsFields = DebugOptions(rawValue: 1 << 5)
}
```

## 9-Slice (NinePatch) Rendering

9-slice rendering allows textures to be scaled while preserving corners and edges.

### centerRect Property

The `centerRect` property defines the stretchable region in normalized coordinates [0, 1]:

```swift
sprite.centerRect = Rect(
    x: 0,                    // Left edge (fixed)
    y: 0.773,                // Bottom margin (fixed)
    width: 1.0,              // Full width stretches
    height: 0.045            // Center region stretches
)
```

### Coordinate System

SpriteEngine uses SpriteKit-compatible coordinates (Y=0 at bottom):

```
Texture (14x22px)           centerRect
┌────────────────┐          ┌────────────────┐
│  Top (fixed)   │ 4px      │ y+h = 0.818    │
├────────────────┤          ├────────────────┤
│ Center(stretch)│ 1px      │ y = 0.773      │
├────────────────┤          │ height = 0.045 │
│ Bottom (fixed) │ 17px     │                │
└────────────────┘          └────────────────┘
     Y=0 at bottom
```

### Example: HP Bar Frame

```swift
// Boss_bar.png: 14x22 pixels
// Top 4px fixed, center 1px stretches, bottom 17px fixed
let barFrame = SNSpriteNode(texture: SNTexture(imageNamed: "Boss_bar.png"))
barFrame.size = Size(width: 14, height: 84)  // Stretched height
barFrame.centerRect = Rect(
    x: 0,
    y: 17.0 / 22.0,       // 0.773 - bottom margin
    width: 1.0,
    height: 1.0 / 22.0    // 0.045 - center region
)
```

### 9-Slice Regions

```
┌─────┬───────────┬─────┐
│ TL  │    Top    │ TR  │  Fixed height
├─────┼───────────┼─────┤
│Left │  Center   │Right│  Stretches vertically
├─────┼───────────┼─────┤
│ BL  │  Bottom   │ BR  │  Fixed height
└─────┴───────────┴─────┘
  │         │         │
  Fixed    Stretches  Fixed
  width   horizontally width
```

## Texture Management

### TextureID

Textures are referenced by opaque IDs:

```swift
public struct TextureID: RawRepresentable, Hashable, Sendable {
    public let rawValue: UInt32
    public static let none = TextureID(rawValue: 0)
}
```

### Loading Flow

```
1. Native: SNTexture(imageNamed: "player.png")
   └── Load CGImage from bundle
   └── Store in imageCache[id]
   └── Assign unique TextureID

2. WASM: JS loadTexture("player.png")
   └── fetch() → createImageBitmap() → device.createTexture()
   └── Store in textureMap[id]
   └── Return id to Swift via callback

3. Sprite: sprite.texture = texture

4. Render: DrawCommand includes textureID
```

### Texture Atlas

For performance, multiple sprites can share a texture atlas:

```javascript
// Atlas contains multiple sprites
const atlas = {
    texture: gpuTexture,
    regions: {
        "player_idle_0": { x: 0, y: 0, w: 64, h: 64 },
        "player_idle_1": { x: 64, y: 0, w: 64, h: 64 },
        // ...
    }
};
```

## Z-Ordering

Sprites are sorted by `zPosition` before rendering:

```swift
commands.sort { $0.zPosition < $1.zPosition }
```

- Lower values render first (background)
- Higher values render on top (foreground)
- Equal values: order is undefined (use different zPositions)

```swift
background.zPosition = -100
ground.zPosition = 0
player.zPosition = 10
effects.zPosition = 50
hud.zPosition = 100
```

## Performance Considerations

### Batch Optimization

Group sprites by texture to minimize state changes:
- Use texture atlases
- Assign same textureID to related sprites
- WebGPU renderer batches automatically

### Command Count

Keep draw command count reasonable:
- Cull off-screen sprites
- Use `isHidden` for inactive objects
- Consider LOD for complex scenes

### Memory Transfer

DrawCommand buffer is copied to GPU each frame:
- Keep struct size minimal
- Avoid unnecessary fields
- Use appropriate data types (Float32 not Float64)

### 9-Slice Performance

9-slice rendering draws 9 separate images per sprite:
- Use only when necessary (UI elements, HP bars)
- Regular sprites are more efficient
- Consider pre-rendering stretched versions for static elements
