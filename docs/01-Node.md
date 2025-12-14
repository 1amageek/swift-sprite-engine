# Node

## Overview

`Node` is the base class for all elements in the scene graph. It provides fundamental properties for positioning, rotation, scaling, and hierarchy management.

A `Node` by itself does not draw any content. Visual content is provided by subclasses such as `Sprite`.

## Definition

```swift
class Node {
    // MARK: - Spatial Properties
    var position: Vec2 = .zero
    var rotation: Float = 0  // radians
    var scale: Vec2 = Vec2(x: 1, y: 1)
    var zPosition: Float = 0

    // MARK: - Appearance
    var alpha: Float = 1
    var isHidden: Bool = false

    // MARK: - Hierarchy
    private(set) var children: [Node] = []
    private(set) weak var parent: Node?
    weak var scene: Scene?

    // MARK: - Identification
    var name: String?
}
```

## Spatial Properties

### position

The position of the node in its parent's coordinate system.

```swift
var position: Vec2
```

- Default: `Vec2.zero`
- Changing position moves the node and all its descendants

### rotation

The Euler rotation about the z-axis in radians.

```swift
var rotation: Float
```

- Default: `0`
- Positive values rotate counter-clockwise
- Affects the node and all its descendants

### scale

A scaling factor that multiplies the size of the node.

```swift
var scale: Vec2
```

- Default: `Vec2(x: 1, y: 1)`
- Affects the node and all its descendants
- Negative values flip the node

### zPosition

The height of the node relative to its parent, used for draw ordering.

```swift
var zPosition: Float
```

- Default: `0`
- Higher values are drawn on top of lower values
- Does not affect transform propagation

## Appearance Properties

### alpha

The transparency of the node.

```swift
var alpha: Float
```

- Default: `1` (fully opaque)
- Range: `0` (invisible) to `1` (fully opaque)
- Multiplied with parent's alpha for final opacity

### isHidden

Controls whether the node and its descendants are rendered.

```swift
var isHidden: Bool
```

- Default: `false`
- Hidden nodes still participate in update cycles

## Hierarchy Management

### Adding Children

```swift
func addChild(_ node: Node)
```

Adds a node to the end of the receiver's list of child nodes.

- The node must not have a parent
- The node's `parent` and `scene` properties are set automatically

### Inserting Children

```swift
func insertChild(_ node: Node, at index: Int)
```

Inserts a node at a specific position in the children array.

### Removing Nodes

```swift
func removeFromParent()
```

Removes the node from its parent.

```swift
func removeAllChildren()
```

Removes all children from this node.

### Accessing Related Nodes

```swift
var parent: Node? { get }
var children: [Node] { get }
var scene: Scene? { get }
```

## Searching by Name

```swift
func childNode(withName name: String) -> Node?
```

Searches children for a node with the specified name.

```swift
func enumerateChildNodes(withName name: String, using block: (Node) -> Void)
```

Enumerates all descendants matching the name pattern.

### Name Patterns

| Pattern | Matches |
|---------|---------|
| `"player"` | Direct child named "player" |
| `"//player"` | Any descendant named "player" |
| `"player/*"` | All children of "player" |
| `"*"` | All direct children |

## Transform Propagation

World transform is calculated by combining local transform with parent's world transform:

```
worldTransform = parent.worldTransform * localTransform
```

### Computed Properties

```swift
var worldPosition: Vec2 { get }
var worldRotation: Float { get }
var worldScale: Vec2 { get }
var worldAlpha: Float { get }
```

These properties are computed by traversing up the parent chain.

## Frame Calculation

```swift
var frame: CGRect { get }
```

Returns a rectangle in parent coordinates containing the node's content (excluding children).

```swift
func calculateAccumulatedFrame() -> CGRect
```

Returns a rectangle containing this node and all descendants.

## Coordinate Conversion

```swift
func convert(_ point: Vec2, from node: Node) -> Vec2
func convert(_ point: Vec2, to node: Node) -> Vec2
```

Convert points between different coordinate spaces.

## Update Cycle

Nodes participate in the scene's update cycle. Override in subclasses:

```swift
// Called each frame during scene.update(dt:)
// Base implementation does nothing
```

## Usage Example

```swift
// Create a container node
let container = Node()
container.position = Vec2(x: 100, y: 100)
container.name = "container"

// Add a sprite as child
let sprite = Sprite(textureID: playerTexture)
sprite.position = Vec2(x: 50, y: 0)  // Offset from container
container.addChild(sprite)

// Add to scene
scene.addChild(container)

// Moving container moves sprite too
container.position.x += 10  // Both move right
```

## Design Notes

### Why class instead of struct?

- Reference semantics required for parent-child relationships
- Nodes need identity for hierarchy management
- Subclassing required (Sprite, Camera, Scene)

### SpriteKit Comparison

| SpriteKit | Wisp |
|-----------|------|
| `SKNode` | `Node` |
| `position: CGPoint` | `position: Vec2` |
| `zRotation: CGFloat` | `rotation: Float` |
| `xScale, yScale` | `scale: Vec2` |
| `run(_:)` | Not in v0.1 |
