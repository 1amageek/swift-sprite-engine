# Build Pipeline

## Overview

Wisp uses Swift's official WASM SDK with the JavaScriptKit SwiftPM plugin for building and packaging.

## Quick Start

```bash
# Build for WebAssembly
cd example
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js

# Copy output to web directory
cp -r .build/plugins/PackageToJS/outputs/Package/* WispExample/

# Start local server
cd WispExample && python3 -m http.server 8080
```

## Tool Landscape (2025)

| Tool | Status | Purpose |
|------|--------|---------|
| **carton** | Deprecated (Nov 2025) | Dev server, bundling |
| **JavaScriptKit SwiftPM Plugin** | Replacement | Build & package |
| **Swift 6.2+ SDK** | Official | WASM compilation |
| **wasm-opt** | Recommended | Binary optimization |

## Project Structure

```
MyGame/
├── Package.swift
├── Sources/
│   └── MyGame/
│       ├── main.swift          # Entry point: Engine.run(scene)
│       └── Scenes/
│           └── GameScene.swift
├── WispExample/                # Web output directory
│   ├── index.html
│   └── app.js
└── .build/                     # Build output (gitignore)
```

## Package.swift

### Game Project

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyGame",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(path: "path/to/Wisp"),
        .package(url: "https://github.com/1amageek/swift-webgpu", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.22.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyGame",
            dependencies: [
                "Wisp",
                .product(name: "SwiftWebGPU", package: "swift-webgpu"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ]
        )
    ]
)
```

### Wisp Library

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wisp",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [
        .library(name: "Wisp", targets: ["Wisp"]),
    ],
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
        .testTarget(name: "WispTests", dependencies: ["Wisp"]),
    ]
)
```

## Build Commands

### Development Build

```bash
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js
```

### Release Build

```bash
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js -c release
```

### Build Output

```
.build/plugins/PackageToJS/outputs/Package/
├── MyGame.wasm              # Compiled WASM binary
├── index.js                 # Entry point
├── instantiate.js           # WASM instantiation
├── runtime.js               # JavaScriptKit runtime
├── platforms/
│   ├── browser.js           # Browser-specific code
│   └── node.js              # Node.js support
└── package.json
```

## Entry Point

```swift
// main.swift
import Wisp

class GameScene: Scene {
    override func sceneDidLoad() {
        let player = SpriteNode(color: .green, size: Size(width: 40, height: 40))
        player.position = Point(x: size.width / 2, y: size.height / 2)
        addChild(player)
    }

    override func update(dt: Float) {
        // Game logic
    }
}

// Single line entry point
Engine.run(GameScene(size: Size(width: 800, height: 600)))
```

## HTML Template

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Wisp Game</title>
    <style>
        * { margin: 0; padding: 0; }
        body {
            background: #1a1a2e;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        #game-canvas {
            border: 1px solid #333;
        }
        #status {
            color: #888;
            margin-top: 16px;
            font-family: system-ui;
        }
    </style>
</head>
<body>
    <canvas id="game-canvas" width="800" height="600"></canvas>
    <div id="status">Loading...</div>
    <script type="module" src="app.js"></script>
</body>
</html>
```

## JavaScript Bootstrap (app.js)

```javascript
import { instantiate } from './instantiate.js';

// Input state (read by Swift)
window.inputState = {
    up: false, down: false, left: false, right: false,
    action: false, action2: false, pause: false,
    pointerDown: false, pointerX: 0, pointerY: 0,
    pointerJustPressed: false, pointerJustReleased: false
};

// Texture loading
window.loadedTextures = {};
let nextTextureID = 1;

window.loadTexture = async (path) => {
    const id = nextTextureID++;
    const response = await fetch(path);
    const blob = await response.blob();
    const bitmap = await createImageBitmap(blob);
    window.loadedTextures[id] = bitmap;
    return id;
};

// Audio (placeholder)
window.playSound = (id, volume, loop) => { /* TODO */ };
window.stopSound = (id) => { /* TODO */ };

// Status display
const status = document.getElementById('status');

// Ready callback
window.onWispReady = () => {
    status.textContent = 'Running';
    requestAnimationFrame(gameLoop);
};

window.onWispError = (msg) => {
    status.textContent = `Error: ${msg}`;
};

// Game loop
let swiftExports;
let lastTime = 0;

function gameLoop(time) {
    const dt = Math.min((time - lastTime) / 1000, 0.1);
    lastTime = time;

    swiftExports.wisp_tick(dt);

    // Reset just-pressed flags
    window.inputState.pointerJustPressed = false;
    window.inputState.pointerJustReleased = false;

    requestAnimationFrame(gameLoop);
}

// Input handling
const canvas = document.getElementById('game-canvas');

document.addEventListener('keydown', (e) => {
    switch(e.code) {
        case 'ArrowUp': case 'KeyW': inputState.up = true; break;
        case 'ArrowDown': case 'KeyS': inputState.down = true; break;
        case 'ArrowLeft': case 'KeyA': inputState.left = true; break;
        case 'ArrowRight': case 'KeyD': inputState.right = true; break;
        case 'Space': inputState.action = true; break;
        case 'Escape': inputState.pause = true; break;
    }
});

document.addEventListener('keyup', (e) => {
    switch(e.code) {
        case 'ArrowUp': case 'KeyW': inputState.up = false; break;
        case 'ArrowDown': case 'KeyS': inputState.down = false; break;
        case 'ArrowLeft': case 'KeyA': inputState.left = false; break;
        case 'ArrowRight': case 'KeyD': inputState.right = false; break;
        case 'Space': inputState.action = false; break;
        case 'Escape': inputState.pause = false; break;
    }
});

canvas.addEventListener('mousedown', (e) => {
    inputState.pointerDown = true;
    inputState.pointerJustPressed = true;
    updatePointer(e);
});

canvas.addEventListener('mouseup', () => {
    inputState.pointerDown = false;
    inputState.pointerJustReleased = true;
});

canvas.addEventListener('mousemove', updatePointer);

function updatePointer(e) {
    const rect = canvas.getBoundingClientRect();
    inputState.pointerX = e.clientX - rect.left;
    inputState.pointerY = canvas.height - (e.clientY - rect.top);
}

// Initialize
status.textContent = 'Initializing WebGPU...';

const { exports } = await instantiate();
swiftExports = exports;
```

## WASM Optimization

### Install wasm-opt

```bash
# macOS
brew install binaryen

# Ubuntu
apt-get install binaryen
```

### Optimize Binary

```bash
wasm-opt -Os MyGame.wasm -o MyGame.wasm
```

### Size Comparison

| Build | Typical Size |
|-------|-------------|
| Debug | 15-20 MB |
| Release | 5-8 MB |
| Release + wasm-opt | 3-5 MB |

## Conditional Compilation

```swift
#if arch(wasm32)
// WASM-specific code
import JavaScriptKit
import SwiftWebGPU
#else
// macOS/iOS code (for Preview)
import SwiftUI
#endif
```

## CI/CD (GitHub Actions)

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Swift
        uses: swift-actions/setup-swift@v2
        with:
          swift-version: '6.2'

      - name: Install WASM SDK
        run: |
          swift sdk install https://github.com/aspect-build/aspect-ios-sdk/releases/download/swift-wasm-6.2-RELEASE/swift-wasm-6.2-RELEASE_wasm.artifactbundle.zip

      - name: Build
        run: |
          cd example
          swift package --swift-sdk swift-6.2.3-RELEASE_wasm js -c release

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./example/.build/plugins/PackageToJS/outputs/Package
```

## Troubleshooting

### WebGPU not available

```javascript
if (!navigator.gpu) {
    document.body.innerHTML = '<p>WebGPU not supported. Use Chrome 113+, Edge 113+, or Safari 18+.</p>';
}
```

### WASM functions not exported

Make sure to use both attributes:

```swift
@_expose(wasm, "function_name")
@_cdecl("function_name")
public func function_name() { ... }
```

### Build cache issues

```bash
rm -rf .build
swift package --swift-sdk swift-6.2.3-RELEASE_wasm js
```
