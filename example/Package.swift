// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SpriteEngineExample",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/swift-sprite-engine", branch: "main"),
        .package(url: "https://github.com/1amageek/swift-webgpu", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.22.0"),
    ],
    targets: [
        // Game logic library (for previews)
        .target(
            name: "Game",
            dependencies: [
                .product(name: "SpriteEngine", package: "swift-sprite-engine"),
            ],
            path: "Sources/Game",
            resources: [
                .copy("Resources")
            ]
        ),
        // WASM executable
        .executableTarget(
            name: "SpriteEngineExample",
            dependencies: [
                "Game",
                .product(name: "SpriteEngine", package: "swift-sprite-engine"),
                .product(name: "SwiftWebGPU", package: "swift-webgpu"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            path: "Sources/SpriteEngineExample"
        )
    ]
)
