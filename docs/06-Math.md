# Math Types

## Overview

Wisp provides minimal, Foundation-free math types optimized for 2D game development and WebAssembly compatibility.

All math types are:
- Value types (structs)
- `Sendable` for concurrency safety
- POD-style for efficient WASM transfer
- No Foundation dependencies

## Vec2

A 2D vector with x and y components.

### Definition

```swift
struct Vec2: Equatable, Hashable, Sendable {
    var x: Float
    var y: Float

    static let zero = Vec2(x: 0, y: 0)
    static let one = Vec2(x: 1, y: 1)
}
```

### Initialization

```swift
let v1 = Vec2(x: 10, y: 20)
let v2 = Vec2.zero
let v3 = Vec2.one
```

### Arithmetic Operations

```swift
// Addition
let sum = v1 + v2
v1 += v2

// Subtraction
let diff = v1 - v2
v1 -= v2

// Scalar multiplication
let scaled = v1 * 2.0
let scaled2 = 2.0 * v1
v1 *= 2.0

// Scalar division
let divided = v1 / 2.0
v1 /= 2.0

// Negation
let negated = -v1
```

### Vector Operations

```swift
// Dot product
let dot = v1.dot(v2)

// Cross product (returns scalar for 2D)
let cross = v1.cross(v2)

// Magnitude (length)
let length = v1.magnitude
let lengthSquared = v1.magnitudeSquared  // Faster, no sqrt

// Normalization
let normalized = v1.normalized
v1.normalize()  // In-place

// Distance
let dist = v1.distance(to: v2)
let distSquared = v1.distanceSquared(to: v2)  // Faster
```

### Interpolation

```swift
// Linear interpolation
let lerped = Vec2.lerp(from: v1, to: v2, t: 0.5)

// Equivalent to:
// v1 + (v2 - v1) * t
```

### Angle Operations

```swift
// Angle of vector (radians, from positive x-axis)
let angle = v1.angle

// Create from angle and magnitude
let v = Vec2.fromAngle(angle, magnitude: 10)

// Rotate vector
let rotated = v1.rotated(by: .pi / 4)  // 45 degrees
```

## Vec3

A 3D vector, primarily used internally for matrix operations.

```swift
struct Vec3: Equatable, Hashable, Sendable {
    var x: Float
    var y: Float
    var z: Float

    static let zero = Vec3(x: 0, y: 0, z: 0)
}
```

## Mat3

A 3x3 matrix for 2D transformations.

### Definition

```swift
struct Mat3: Equatable, Sendable {
    // Column-major storage (matches GPU conventions)
    var m: (Float, Float, Float,
            Float, Float, Float,
            Float, Float, Float)

    static let identity = Mat3(...)
}
```

### Creating Transform Matrices

```swift
// Identity (no transformation)
let identity = Mat3.identity

// Translation
let translate = Mat3.translation(x: 100, y: 50)
let translate2 = Mat3.translation(Vec2(x: 100, y: 50))

// Rotation (radians)
let rotate = Mat3.rotation(angle: .pi / 4)

// Scale
let scale = Mat3.scale(x: 2, y: 2)
let scale2 = Mat3.scale(Vec2(x: 2, y: 2))
```

### Matrix Operations

```swift
// Multiplication (combine transforms)
let combined = translate * rotate * scale

// Apply to vector
let transformed = matrix * point
let transformed2 = matrix.transform(point)

// Inverse
let inverse = matrix.inverse
```

### Transform Order

Matrix multiplication is right-to-left. To translate, then rotate, then scale:

```swift
// Read right-to-left: scale → rotate → translate
let transform = translate * rotate * scale
let result = transform * point

// Equivalent to:
// 1. Scale the point
// 2. Rotate the scaled point
// 3. Translate the rotated point
```

## Rect

A 2D rectangle defined by origin and size.

### Definition

```swift
struct Rect: Equatable, Hashable, Sendable {
    var origin: Vec2
    var size: Vec2

    var x: Float { get set }
    var y: Float { get set }
    var width: Float { get set }
    var height: Float { get set }

    static let zero = Rect(origin: .zero, size: .zero)
}
```

### Initialization

```swift
let rect1 = Rect(origin: Vec2(x: 10, y: 20), size: Vec2(x: 100, y: 50))
let rect2 = Rect(x: 10, y: 20, width: 100, height: 50)
```

### Properties

```swift
// Corners
rect.minX  // Left edge
rect.maxX  // Right edge
rect.minY  // Bottom edge
rect.maxY  // Top edge

rect.midX  // Horizontal center
rect.midY  // Vertical center

// Center point
rect.center

// Check if empty
rect.isEmpty
```

### Operations

```swift
// Contains point
rect.contains(point)

// Contains another rect
rect.contains(otherRect)

// Intersection test
rect.intersects(otherRect)

// Intersection rect
let intersection = rect.intersection(otherRect)

// Union (bounding rect)
let union = rect.union(otherRect)

// Inset (shrink/expand)
let smaller = rect.insetBy(dx: 10, dy: 10)
let larger = rect.insetBy(dx: -10, dy: -10)

// Offset (move)
let moved = rect.offsetBy(dx: 50, dy: 0)
```

## Color

An RGBA color with components in 0-1 range.

### Definition

```swift
struct Color: Equatable, Hashable, Sendable {
    var r: Float  // Red (0-1)
    var g: Float  // Green (0-1)
    var b: Float  // Blue (0-1)
    var a: Float  // Alpha (0-1)
}
```

### Predefined Colors

```swift
static let white = Color(r: 1, g: 1, b: 1, a: 1)
static let black = Color(r: 0, g: 0, b: 0, a: 1)
static let clear = Color(r: 0, g: 0, b: 0, a: 0)
static let red = Color(r: 1, g: 0, b: 0, a: 1)
static let green = Color(r: 0, g: 1, b: 0, a: 1)
static let blue = Color(r: 0, g: 0, b: 1, a: 1)
static let yellow = Color(r: 1, g: 1, b: 0, a: 1)
static let cyan = Color(r: 0, g: 1, b: 1, a: 1)
static let magenta = Color(r: 1, g: 0, b: 1, a: 1)
static let gray = Color(r: 0.5, g: 0.5, b: 0.5, a: 1)
```

### Creating Colors

```swift
// From components (0-1)
let color = Color(r: 0.2, g: 0.4, b: 0.8, a: 1.0)

// From hex (convenience)
let color = Color(hex: 0x3366CC)
let color = Color(hex: 0x3366CCFF)  // With alpha

// From 0-255 values
let color = Color(r255: 51, g255: 102, b255: 204)
```

### Operations

```swift
// Blend with another color
let blended = color1.blend(with: color2, factor: 0.5)

// Adjust alpha
let faded = color.withAlpha(0.5)

// Multiply (for tinting)
let tinted = color * tintColor
```

## Angle Utilities

### Constants

```swift
extension Float {
    static let pi: Float = 3.14159265358979323846
    static let twoPi: Float = pi * 2
    static let halfPi: Float = pi / 2
}
```

### Conversion

```swift
func degreesToRadians(_ degrees: Float) -> Float {
    degrees * .pi / 180
}

func radiansToDegrees(_ radians: Float) -> Float {
    radians * 180 / .pi
}
```

### Normalization

```swift
// Normalize angle to [0, 2π)
func normalizeAngle(_ angle: Float) -> Float

// Normalize angle to [-π, π)
func normalizeAngleSigned(_ angle: Float) -> Float

// Shortest angle difference
func angleDifference(from: Float, to: Float) -> Float
```

## Random

### Random Values

```swift
// Random float in range
let r = Float.random(in: 0...1)

// Random Vec2 in rect
let point = Vec2.random(in: rect)

// Random unit vector
let direction = Vec2.randomDirection()

// Random color
let color = Color.random()
let color = Color.random(alpha: 1.0)
```

## Design Notes

### Why Float instead of Double?

- WebGPU uses 32-bit floats
- Smaller memory footprint
- Sufficient precision for 2D games
- Faster on many platforms

### Why no SIMD?

- WASM SIMD support varies
- Complexity not justified for v0.1
- May add in future versions

### Why no Foundation?

- Foundation has WASM compatibility issues
- Minimizes binary size
- Ensures predictable behavior
- CGFloat not available in WASM
