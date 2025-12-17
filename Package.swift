// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-sprite-engine",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "SpriteEngine",
            targets: ["SpriteEngine"]
        ),
    ],
    dependencies: [
        // WASM dependencies - always included in manifest, conditionally used in code
        .package(url: "https://github.com/1amageek/swift-webgpu", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.22.0"),
        // CoreGraphics compatibility for WASM
        .package(url: "https://github.com/1amageek/OpenCoreGraphics", branch: "main"),
    ],
    targets: [
        .target(
            name: "SpriteEngine",
            dependencies: [
                .product(name: "SwiftWebGPU", package: "swift-webgpu", condition: .when(platforms: [.wasi])),
                .product(name: "JavaScriptKit", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
                .product(name: "OpenCoreGraphics", package: "OpenCoreGraphics", condition: .when(platforms: [.wasi])),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SpriteEngineTests",
            dependencies: ["SpriteEngine"]
        ),
    ]
)
