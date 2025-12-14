# SpriteNode

## Overview

`SpriteNode` is a node that displays a textured image or solid color. It is the primary way to render visual content in Wisp.

`SpriteNode` inherits from `Node`, gaining all spatial and hierarchy properties.

## Definition

```swift
class SpriteNode: Node {
    // MARK: - Texture
    var texture: Texture?
    var normalTexture: Texture?

    // MARK: - Size
    var size: Size
    var anchorPoint: Point = Point(x: 0.5, y: 0.5)

    // MARK: - Color and Blending
    var color: Color = .white
    var colorBlendFactor: Float = 0
    var blendMode: BlendMode = .alpha

    // MARK: - Nine-Part Scaling
    var centerRect: Rect = Rect(x: 0, y: 0, width: 1, height: 1)

    // MARK: - Lighting
    var lightingBitMask: UInt32 = 0
    var shadowCastBitMask: UInt32 = 0
    var shadowedBitMask: UInt32 = 0

    // MARK: - Shader
    var shader: Shader?
    var attributeValues: [String: ShaderAttributeValue] = [:]

    // MARK: - Warp
    var warpGeometry: WarpGeometry?
    var subdivisionLevels: Int = 0
}
```

## Creating Sprites

### From Image Name (Recommended)

```swift
init(imageNamed: String)
init(imageNamed: String, normalMapped: Bool)
```

Creates a sprite with the specified image file. Size is automatically set to the texture dimensions.

```swift
// SpriteKit-style creation
let player = SpriteNode(imageNamed: "player.png")
player.position = Point(x: 400, y: 300)
scene.addChild(player)

// With automatic normal map generation for lighting
let rock = SpriteNode(imageNamed: "rock.png", normalMapped: true)
```

### From Texture

```swift
init(texture: Texture)
init(texture: Texture, size: Size)
init(texture: Texture?, color: Color, size: Size)
init(texture: Texture, normalMap: Texture?)
```

Creates a sprite with an existing Texture object.

```swift
let texture = Texture(imageNamed: "enemy.png")
let enemy = SpriteNode(texture: texture)

// With explicit size
let bigEnemy = SpriteNode(texture: texture, size: Size(width: 128, height: 128))

// With color and size
let tintedSprite = SpriteNode(texture: texture, color: .red, size: Size(width: 64, height: 64))

// With pre-made normal map
let normalMap = Texture(imageNamed: "enemy_normal.png")
let litEnemy = SpriteNode(texture: texture, normalMap: normalMap)
```

### From Color

```swift
init(color: Color, size: Size)
```

Creates a solid-color sprite with the specified size.

```swift
let healthBar = SpriteNode(color: .red, size: Size(width: 100, height: 10))
```

### Default

```swift
init()
```

Creates an empty sprite with no texture and zero size.

## Texture

### texture

The texture used to draw the sprite.

```swift
var texture: Texture?
```

- When `nil`, the sprite draws as a solid color rectangle
- Textures are loaded automatically from the resource bundle
- Same texture can be shared by multiple sprites

### Texture Class

```swift
public final class Texture {
    let name: String
    var size: Size { get }  // Lazily loaded

    init(imageNamed: String)

    func preload()
    static func preload(_ textures: [Texture], completion: @escaping () -> Void)
}
```

### Texture Loading

Textures are loaded lazily when first accessed (similar to SpriteKit):

```swift
// Texture created but not loaded yet
let texture = Texture(imageNamed: "player.png")

// Accessing size triggers loading
let size = texture.size  // Now loaded

// Or explicitly preload
texture.preload()
```

### Platform-Specific Loading

```
Resource: "player.png"
    │
    ├─ Web (Production):
    │   fetch("assets/player.png") → GPUTexture → WebGPU rendering
    │
    └─ Swift (Preview):
        Bundle.main → CGImage → SwiftUI Canvas rendering
```

## Size and Anchor

### size

The dimensions of the sprite in points.

```swift
var size: Size
```

- When created from texture, defaults to texture dimensions
- Can be changed to scale the sprite independently of `scale` property

### anchorPoint

The point within the sprite that corresponds to its position.

```swift
var anchorPoint: Point
```

- Default: `Point(x: 0.5, y: 0.5)` (center)
- Range: `(0, 0)` to `(1, 1)`

| Anchor | Position Reference |
|--------|-------------------|
| `(0, 0)` | Bottom-left corner |
| `(0.5, 0.5)` | Center |
| `(1, 1)` | Top-right corner |
| `(0.5, 0)` | Bottom-center |

```swift
// Position sprite by its bottom-left corner
sprite.anchorPoint = Point(x: 0, y: 0)
sprite.position = Point(x: 100, y: 100)  // Bottom-left at (100, 100)

// Position sprite by its center (default)
sprite.anchorPoint = Point(x: 0.5, y: 0.5)
sprite.position = Point(x: 100, y: 100)  // Center at (100, 100)
```

## Color and Blending

### color

The sprite's tint color.

```swift
var color: Color
```

- Default: `Color.white`
- When no texture, draws as solid color
- When textured, used with `colorBlendFactor`

### colorBlendFactor

How much the color blends with the texture.

```swift
var colorBlendFactor: Float
```

- Default: `0` (texture only)
- Range: `0` (full texture) to `1` (full color)
- At `0.5`, texture and color are equally blended

```swift
// Create red-tinted sprite
sprite.color = Color(red: 1, green: 0, blue: 0, alpha: 1)
sprite.colorBlendFactor = 0.5  // 50% red tint

// Flash white when hit
sprite.colorBlendFactor = 1.0  // Fully white
```

### blendMode

The blend mode used to draw the sprite into the framebuffer.

```swift
var blendMode: BlendMode
```

- Default: `.alpha` (standard alpha blending)
- Use `.add` for glow effects, fire, and other additive lighting
- Use `.multiply` for shadows and darkening effects

```swift
// Additive blending for glow effect
sprite.blendMode = .add

// Multiply for shadows
shadowSprite.blendMode = .multiply
```

Available modes:
| Mode | Description |
|------|-------------|
| `.alpha` | Standard alpha blending (default) |
| `.add` | Additive blending for glow effects |
| `.subtract` | Subtracts source from destination |
| `.multiply` | Darkening effect |
| `.multiplyX2` | Double multiply |
| `.screen` | Lightening effect |
| `.replace` | No blending, overwrites destination |
| `.multiplyAlpha` | Multiply by destination alpha |

## Nine-Part Scaling

### centerRect

Enables 9-part stretching of the sprite's texture.

```swift
var centerRect: Rect
```

- Default: `Rect(x: 0, y: 0, width: 1, height: 1)` (no 9-part scaling)
- The texture is split into a 3x3 grid
- Corners maintain their original size
- Edges and center are stretched

```swift
// Create a button that stretches in the middle
let button = SpriteNode(imageNamed: "button.png")
button.centerRect = Rect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
button.size = Size(width: 200, height: 50)  // Corners won't stretch
```

## Methods

### scale(to:)

Scales the sprite to the specified size.

```swift
func scale(to targetSize: Size)
```

Adjusts `xScale` and `yScale` to render the sprite at the target size.

```swift
let sprite = SpriteNode(imageNamed: "icon.png")  // Original 32x32
sprite.scale(to: Size(width: 64, height: 64))    // Now renders at 64x64
```

## Usage Examples

### Basic Sprite

```swift
// Create from image (recommended)
let player = SpriteNode(imageNamed: "player.png")
player.position = Point(x: 400, y: 300)
scene.addChild(player)
```

### Colored Rectangle

```swift
// Create solid color sprite (useful for UI, debug)
let healthBar = SpriteNode(color: .red, size: Size(width: 100, height: 10))
healthBar.position = Point(x: 50, y: 550)
healthBar.anchorPoint = Point(x: 0, y: 0.5)  // Anchor left
scene.addChild(healthBar)

// Update health bar width
healthBar.size.width = playerHealth  // 0-100
```

### SpriteNode Animation with Actions

```swift
// Create texture array
let walkFrames = [
    Texture(imageNamed: "walk_1.png"),
    Texture(imageNamed: "walk_2.png"),
    Texture(imageNamed: "walk_3.png"),
    Texture(imageNamed: "walk_4.png")
]

// Animate with action
let walkAction = Action.animate(with: walkFrames, timePerFrame: 0.1)
let repeatAction = Action.repeatForever(walkAction)
player.run(repeatAction)
```

### Preloading Textures

```swift
// Preload textures before starting gameplay
let textures = [
    Texture(imageNamed: "player.png"),
    Texture(imageNamed: "enemy.png"),
    Texture(imageNamed: "background.png")
]

Texture.preload(textures) {
    // All textures ready - start gameplay
    presentGameScene()
}
```

### Flipping Sprites

```swift
// Flip horizontally using scale
sprite.scale.width = -1  // Facing left

// Flip vertically
sprite.scale.height = -1  // Upside down
```

## Design Notes

### Size vs Scale

Both `size` and `scale` affect visual dimensions:

| Property | Purpose |
|----------|---------|
| `size` | Base dimensions of the sprite |
| `scale` | Multiplier applied to size (inherited from Node) |

Final rendered size = `size * scale * parent.worldScale`

```swift
// These produce the same visual result:
sprite.size = Size(width: 100, height: 100)
sprite.scale = Size(width: 2, height: 2)
// Final: 200x200

sprite.size = Size(width: 200, height: 200)
sprite.scale = Size(width: 1, height: 1)
// Final: 200x200
```

Use `size` for the sprite's intrinsic dimensions, `scale` for animation or uniform scaling.

### SpriteKit Comparison

| SpriteKit | Wisp |
|-----------|------|
| `SKSpriteNode` | `SpriteNode` |
| `SKTexture` | `Texture` |
| `init(imageNamed:)` | `init(imageNamed:)` ✓ |
| `init(imageNamed:normalMapped:)` | `init(imageNamed:normalMapped:)` ✓ |
| `init(texture:)` | `init(texture:)` ✓ |
| `init(texture:size:)` | `init(texture:size:)` ✓ |
| `init(texture:color:size:)` | `init(texture:color:size:)` ✓ |
| `init(texture:normalMap:)` | `init(texture:normalMap:)` ✓ |
| `init(color:size:)` | `init(color:size:)` ✓ |
| `texture: SKTexture?` | `texture: Texture?` |
| `normalTexture: SKTexture?` | `normalTexture: Texture?` |
| `size: CGSize` | `size: Size` |
| `anchorPoint: CGPoint` | `anchorPoint: Point` |
| `color: UIColor` | `color: Color` |
| `colorBlendFactor: CGFloat` | `colorBlendFactor: Float` |
| `blendMode: SKBlendMode` | `blendMode: BlendMode` ✓ |
| `centerRect: CGRect` | `centerRect: Rect` ✓ |
| `lightingBitMask: UInt32` | `lightingBitMask: UInt32` ✓ |
| `shadowCastBitMask: UInt32` | `shadowCastBitMask: UInt32` ✓ |
| `shadowedBitMask: UInt32` | `shadowedBitMask: UInt32` ✓ |
| `shader: SKShader?` | `shader: Shader?` ✓ |
| `scale(to:)` | `scale(to:)` ✓ |
