# WebGPU Integration

## Overview

Wisp uses **SwiftWebGPU** to render directly from Swift via WebGPU. This eliminates the need for JavaScript-based rendering.

```
Swift (WASM)
   ↓  (JavaScriptKit bindings)
SwiftWebGPU
   ↓
WebGPU (GPUDevice, CommandEncoder, Pipeline)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Swift (WASM)                            │
│  - Scene graph management                                   │
│  - Transform calculations                                   │
│  - DrawCommand generation                                   │
│  - WebGPU rendering via SwiftWebGPU                        │
└─────────────────────────────────────────────────────────────┘
                              │
                    JavaScriptKit bindings
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       WebGPU                                │
│  - GPUDevice, GPUQueue                                      │
│  - Render pipeline                                          │
│  - Texture management                                       │
│  - Vertex/instance buffers                                  │
└─────────────────────────────────────────────────────────────┘
```

## Dependencies

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/swift-webgpu", branch: "main"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.22.0"),
],
targets: [
    .target(
        name: "Wisp",
        dependencies: [
            .product(name: "SwiftWebGPU", package: "swift-webgpu", condition: .when(platforms: [.wasi])),
            .product(name: "JavaScriptKit", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
            .product(name: "JavaScriptEventLoop", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
        ]
    ),
]
```

## SwiftWebGPU Features

SwiftWebGPU provides:
- Type-safe Swift API for WebGPU
- Async/await support for GPU operations
- Direct access to GPUDevice, GPURenderPipeline, GPUBuffer, etc.

### Example Usage

```swift
import SwiftWebGPU

// Get GPU adapter and device
guard let gpu = GPU.shared else { throw WebGPUError.notSupported }
guard let adapter = try await gpu.requestAdapter() else { throw WebGPUError.noAdapter }
let device = try await adapter.requestDevice()

// Create render pipeline
let shaderModule = device.createShaderModule(descriptor: GPUShaderModuleDescriptor(
    code: shaderSource,
    label: "SpriteShader"
))

let pipeline = device.createRenderPipeline(descriptor: GPURenderPipelineDescriptor(
    vertex: GPUVertexState(module: shaderModule, entryPoint: "vs_main"),
    fragment: GPUFragmentState(module: shaderModule, entryPoint: "fs_main", targets: [...]),
    ...
))
```

## WebGPU Renderer

Wisp's `WebGPURenderer` handles all GPU operations:

```swift
public final class WebGPURenderer {
    let device: GPUDevice
    let context: GPUCanvasContext
    let textureManager: WebGPUTextureManager

    private var renderPipeline: GPURenderPipeline!
    private var instanceBuffer: GPUBuffer!
    private var uniformBuffer: GPUBuffer!

    public static func create(canvas: JSObject) async throws -> WebGPURenderer
    func render(commands: [DrawCommand], backgroundColor: Color)
    func resize(width: UInt32, height: UInt32)
}
```

## WASM Export Functions

Swift exports functions to JavaScript using `@_expose(wasm)`:

```swift
@_expose(wasm, "wisp_initAsync")
@_cdecl("wisp_initAsync")
public func wisp_initAsync() {
    Task {
        renderer = try await WebGPURenderer.create(canvas: canvas)
        // Notify JavaScript
        if let onReady = JSObject.global.onWispReady.function {
            _ = onReady()
        }
    }
}

@_expose(wasm, "wisp_tick")
@_cdecl("wisp_tick")
public func wisp_tick(_ deltaTime: Float) {
    guard let renderer = renderer else { return }

    let input = readInputFromJS()
    gameLoop.tick(realDeltaTime: deltaTime, input: input)
    let commands = gameLoop.generateDrawCommands()
    renderer.render(commands: commands, backgroundColor: scene.backgroundColor)
}

@_expose(wasm, "wisp_resize")
@_cdecl("wisp_resize")
public func wisp_resize(_ width: Int32, _ height: Int32) {
    renderer?.resize(width: UInt32(width), height: UInt32(height))
}
```

## Shader (WGSL)

```wgsl
struct Uniforms {
    viewProjection: mat4x4<f32>,
    screenSize: vec2<f32>,
}

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var textureSampler: sampler;
@group(0) @binding(2) var spriteTexture: texture_2d<f32>;

struct InstanceInput {
    @location(1) instancePosition: vec2<f32>,
    @location(2) instanceSize: vec2<f32>,
    @location(3) instanceRotation: f32,
    @location(4) instanceAnchor: vec2<f32>,
    @location(5) instanceTexRect: vec4<f32>,
    @location(6) instanceColor: vec4<f32>,
    @location(7) instanceAlpha: f32,
}

@vertex
fn vs_main(vertex: VertexInput, instance: InstanceInput) -> VertexOutput {
    // Transform vertex by instance data
    let anchoredPos = vertex.position - instance.instanceAnchor;
    let scaledPos = anchoredPos * instance.instanceSize;

    // Apply rotation
    let cosR = cos(instance.instanceRotation);
    let sinR = sin(instance.instanceRotation);
    let rotatedPos = vec2<f32>(
        scaledPos.x * cosR - scaledPos.y * sinR,
        scaledPos.x * sinR + scaledPos.y * cosR
    );

    let worldPos = rotatedPos + instance.instancePosition;
    out.position = uniforms.viewProjection * vec4<f32>(worldPos, 0.0, 1.0);

    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let texColor = textureSample(spriteTexture, textureSampler, in.texCoord);
    return texColor * in.color;
}
```

## Instance Buffer Layout

```
Offset  Size  Field
──────────────────────────
0       8     position (vec2<f32>)
8       8     size (vec2<f32>)
16      4     rotation (f32)
20      4     padding
24      8     anchor (vec2<f32>)
32      16    texRect (vec4<f32>)
48      16    color (vec4<f32>)
64      4     alpha (f32)
68      12    padding
──────────────────────────
Total:  80 bytes per instance
```

## JavaScript Side

JavaScript's role is minimal:
- Load and initialize WASM
- Drive animation loop with `requestAnimationFrame`
- Poll input state
- Load textures (images)

```javascript
// Minimal JavaScript setup
const canvas = document.getElementById('game-canvas');

// Input state (read by Swift)
window.inputState = {
    up: false, down: false, left: false, right: false,
    action: false, pointerDown: false,
    pointerX: 0, pointerY: 0
};

// Callbacks from Swift
window.onWispReady = () => {
    requestAnimationFrame(gameLoop);
};

let lastTime = 0;
function gameLoop(time) {
    const dt = (time - lastTime) / 1000;
    lastTime = time;

    swiftExports.wisp_tick(dt);
    requestAnimationFrame(gameLoop);
}
```

## Texture Loading

Textures are loaded via JavaScript and passed to Swift:

```javascript
// JavaScript side
window.loadTexture = (path) => {
    const id = nextTextureID++;

    createImageBitmap(await fetch(path).then(r => r.blob()))
        .then(bitmap => {
            window.loadedTextures[id] = bitmap;
            swiftExports.wisp_onTextureLoaded(id, bitmap.width, bitmap.height);
        });

    return id;
};
```

```swift
// Swift side
@_expose(wasm, "wisp_onTextureLoaded")
@_cdecl("wisp_onTextureLoaded")
public func wisp_onTextureLoaded(_ textureId: UInt32, _ width: Int32, _ height: Int32) {
    let imageBitmaps = JSObject.global.loadedTextures
    if let imageBitmap = imageBitmaps[Int(textureId)].object {
        renderer?.textureManager.createTextureFromImage(
            textureID: textureId,
            imageBitmap: imageBitmap,
            width: UInt32(width),
            height: UInt32(height)
        )
    }
}
```

## Browser Compatibility

| Browser | Support |
|---------|---------|
| Chrome 113+ | Full |
| Edge 113+ | Full |
| Safari 18+ | Full |
| Firefox | Behind flag |

## Debugging

### Console Logging

```swift
public func consoleLog(_ message: String) {
    _ = JSObject.global.console.log.function!(message)
}
```

### GPU Errors

WebGPU validation errors appear in browser console automatically.

### Performance

Use Chrome DevTools → Performance tab with "WebGPU" enabled to profile GPU timing.
