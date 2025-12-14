# Rendering

## Overview

Wisp uses a **dual-backend rendering** architecture:
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
│     WebGPURenderer      │     │    PreviewRenderer      │
│     (JavaScript)        │     │    (SwiftUI Canvas)     │
│                         │     │                         │
│  - GPUDevice            │     │  - Canvas context       │
│  - RenderPipeline       │     │  - Path drawing         │
│  - Texture atlas        │     │  - Image rendering      │
│  - Instanced batching   │     │  - Debug overlays       │
└─────────────────────────┘     └─────────────────────────┘
```

## DrawCommand

The fundamental unit of rendering data.

```swift
struct DrawCommand {
    // Transform (world space)
    var worldPosition: Vec2
    var worldRotation: Float
    var worldScale: Vec2

    // Sprite data
    var size: Vec2
    var anchorPoint: Vec2
    var textureID: UInt32      // 0 = no texture (solid color)

    // Appearance
    var color: Color
    var alpha: Float
    var zPosition: Float
}
```

### Memory Layout

For efficient transfer to WebGPU, DrawCommand is designed as a POD (Plain Old Data) struct:

```swift
// Packed for GPU buffer transfer
// Total: 52 bytes per command
struct DrawCommand {
    var worldPosition: Vec2    // 8 bytes (2 × Float)
    var worldRotation: Float   // 4 bytes
    var worldScale: Vec2       // 8 bytes
    var size: Vec2             // 8 bytes
    var anchorPoint: Vec2      // 8 bytes
    var textureID: UInt32      // 4 bytes
    var color: Color           // 16 bytes (4 × Float)
    var alpha: Float           // 4 bytes
    var zPosition: Float       // 4 bytes
    // Padding: 4 bytes for 16-byte alignment
}
```

## Command Generation

### Process

```swift
func generateDrawCommands() -> [DrawCommand] {
    var commands: [DrawCommand] = []

    func traverse(_ node: Node) {
        // Skip hidden nodes
        guard !node.isHidden else { return }

        // Generate command for drawable nodes
        if let sprite = node as? Sprite {
            commands.append(sprite.makeDrawCommand())
        }

        // Recurse children
        for child in node.children {
            traverse(child)
        }
    }

    traverse(scene)

    // Sort by zPosition for correct layering
    commands.sort { $0.zPosition < $1.zPosition }

    return commands
}
```

### Sprite Command Generation

```swift
extension Sprite {
    func makeDrawCommand() -> DrawCommand {
        DrawCommand(
            worldPosition: worldPosition,
            worldRotation: worldRotation,
            worldScale: worldScale,
            size: size,
            anchorPoint: anchorPoint,
            textureID: texture?.rawValue ?? 0,
            color: color,
            alpha: worldAlpha,
            zPosition: zPosition
        )
    }
}
```

## Renderer Protocol

```swift
protocol Renderer {
    func render(commands: [DrawCommand], viewport: Rect)
    func clear(color: Color)
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

## Preview Renderer (SwiftUI)

For development, a SwiftUI-based renderer enables `#Preview` workflow.

### Implementation

```swift
struct PreviewRenderer: Renderer {
    func render(commands: [DrawCommand], viewport: Rect) -> some View {
        Canvas { context, size in
            // Clear background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(backgroundColor)
            )

            // Draw each command
            for command in commands {
                drawCommand(command, in: &context, size: size)
            }
        }
    }

    private func drawCommand(_ cmd: DrawCommand, in context: inout GraphicsContext, size: CGSize) {
        // Calculate screen position
        let screenPos = worldToScreen(cmd.worldPosition, viewport: viewport, size: size)

        // Apply transforms
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: screenPos.x, y: screenPos.y)
        transform = transform.rotated(by: CGFloat(cmd.worldRotation))
        transform = transform.scaledBy(x: CGFloat(cmd.worldScale.x), y: CGFloat(cmd.worldScale.y))

        context.transform = transform

        // Draw sprite
        let rect = CGRect(
            x: -CGFloat(cmd.size.x * cmd.anchorPoint.x),
            y: -CGFloat(cmd.size.y * cmd.anchorPoint.y),
            width: CGFloat(cmd.size.x),
            height: CGFloat(cmd.size.y)
        )

        if cmd.textureID != 0, let image = textureCache[cmd.textureID] {
            context.draw(image, in: rect)
        } else {
            context.fill(Path(rect), with: .color(cmd.color.cgColor))
        }
    }
}
```

### Preview Usage

```swift
#Preview {
    GameScenePreview()
}

struct GameScenePreview: View {
    @State private var scene = GameScene(size: Vec2(x: 800, y: 600))

    var body: some View {
        TimelineView(.animation) { timeline in
            PreviewRenderer().render(
                commands: scene.generateDrawCommands(),
                viewport: scene.calculateViewport()
            )
        }
        .onAppear {
            scene.sceneDidLoad()
        }
    }
}
```

## Texture Management

### TextureID

Textures are referenced by opaque IDs, managed by the JavaScript layer:

```swift
struct TextureID: RawRepresentable, Hashable, Sendable {
    let rawValue: UInt32

    static let none = TextureID(rawValue: 0)
}
```

### Loading Flow

```
1. JS: loadTexture("player.png")
   └── fetch() → createImageBitmap() → device.createTexture()
   └── Store in textureMap[id] = gpuTexture
   └── Return id to Swift via callback

2. Swift: sprite.texture = TextureID(rawValue: id)

3. Render: DrawCommand includes textureID

4. JS: Look up GPUTexture by ID, bind to shader
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
