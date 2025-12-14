// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SpriteEngineExample",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/1amageek/swift-webgpu", branch: "main"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.22.0"),
    ],
    targets: [
        .executableTarget(
            name: "SpriteEngineExample",
            dependencies: [
                "SpriteEngine",
                .product(name: "SwiftWebGPU", package: "swift-webgpu"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
