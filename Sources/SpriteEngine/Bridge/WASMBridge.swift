/// WASM Bridge for Wisp
///
/// This module provides the interface between Swift/WASM and JavaScript.
/// Swift handles WebGPU rendering directly via SwiftWebGPU.
/// JavaScript handles:
/// - Input polling
/// - Texture loading (images)
/// - Audio playback
///
/// Swift exports functions that JavaScript calls each frame.
/// Swift imports functions to request resources from JavaScript.

#if arch(wasm32)
import SwiftWebGPU
import JavaScriptKit
import JavaScriptEventLoop

// MARK: - Global State
// Note: WASM is single-threaded, so nonisolated(unsafe) is safe here

/// Global game loop instance.
nonisolated(unsafe) public var gameLoop: GameLoop = GameLoop()

/// Global WebGPU renderer (initialized asynchronously).
nonisolated(unsafe) public var renderer: WebGPURenderer?

/// Whether the engine has been initialized.
nonisolated(unsafe) private var isInitialized = false

// MARK: - Initialization

/// Initialize the Wisp engine with WebGPU.
///
/// This must be called before any rendering can occur.
/// Call from JavaScript: `await wasmExports.wisp_initAsync()`
@_expose(wasm, "wisp_initAsync")
@_cdecl("wisp_initAsync")
public func wisp_initAsync() {
    Task {
        do {
            // Get canvas element
            let canvas = JSObject.global.document.getElementById("game-canvas").object!

            // Create WebGPU renderer
            renderer = try await WebGPURenderer.create(canvas: canvas)

            isInitialized = true
            consoleLog("Wisp: WebGPU renderer initialized successfully")

            // Notify JavaScript that initialization is complete
            if let onReady = JSObject.global.onWispReady.function {
                _ = onReady()
            }
        } catch {
            consoleLog("Wisp: Failed to initialize WebGPU renderer: \(error)")

            // Notify JavaScript of failure
            if let onError = JSObject.global.onWispError.function {
                _ = onError("Failed to initialize WebGPU: \(error)")
            }
        }
    }
}

/// Set the current scene.
///
/// - Parameter scene: The scene to present.
public func wisp_setScene(_ scene: SNScene) {
    gameLoop.present(scene)
    scene.sceneDidLoad()
}

// MARK: - Frame Loop

/// Process one frame: update game logic and render.
///
/// Called from JavaScript's requestAnimationFrame.
///
/// - Parameter deltaTime: Real elapsed time since last frame (seconds).
@_expose(wasm, "wisp_tick")
@_cdecl("wisp_tick")
public func wisp_tick(_ deltaTime: Float) {
    guard isInitialized, let renderer = renderer else {
        return
    }

    // Read input from JavaScript
    let input = readInputFromJS()

    // Update game logic
    gameLoop.tick(realDeltaTime: deltaTime, input: input)

    // Generate draw commands
    let commands = gameLoop.generateDrawCommands()

    // Debug: log command count every 60 frames (deterministic)
    if gameLoop.frameCount % 60 == 0 {
        consoleLog("Wisp: commands=\(commands.count), children=\(gameLoop.scene?.children.count ?? 0)")
    }

    // Get background color
    let backgroundColor = gameLoop.scene?.backgroundColor ?? .black

    // Render frame
    renderer.render(commands: commands, backgroundColor: backgroundColor)
}

/// Resize the renderer to match canvas size.
///
/// - Parameters:
///   - width: New width in pixels.
///   - height: New height in pixels.
@_expose(wasm, "wisp_resize")
@_cdecl("wisp_resize")
public func wisp_resize(_ width: Int32, _ height: Int32) {
    renderer?.resize(width: UInt32(width), height: UInt32(height))
}

// MARK: - Scene Info

/// Get scene size.
@_expose(wasm, "wisp_getSceneWidth")
@_cdecl("wisp_getSceneWidth")
public func wisp_getSceneWidth() -> Float {
    return gameLoop.scene?.size.width ?? 0
}

@_expose(wasm, "wisp_getSceneHeight")
@_cdecl("wisp_getSceneHeight")
public func wisp_getSceneHeight() -> Float {
    return gameLoop.scene?.size.height ?? 0
}

/// Pause/unpause the game.
@_expose(wasm, "wisp_setPaused")
@_cdecl("wisp_setPaused")
public func wisp_setPaused(_ paused: Bool) {
    gameLoop.scene?.isPaused = paused
}

@_expose(wasm, "wisp_isPaused")
@_cdecl("wisp_isPaused")
public func wisp_isPaused() -> Bool {
    return gameLoop.scene?.isPaused ?? false
}

// MARK: - Input Reading

/// Read input state from JavaScript.
private func readInputFromJS() -> InputState {
    var input = InputState()

    // Read from JavaScript global inputState object
    let jsInput = JSObject.global.inputState

    input.up = jsInput.up.boolean ?? false
    input.down = jsInput.down.boolean ?? false
    input.left = jsInput.left.boolean ?? false
    input.right = jsInput.right.boolean ?? false
    input.action = jsInput.action.boolean ?? false
    input.action2 = jsInput.action2.boolean ?? false
    input.pause = jsInput.pause.boolean ?? false
    input.pointerDown = jsInput.pointerDown.boolean ?? false

    if let px = jsInput.pointerX.number, let py = jsInput.pointerY.number {
        input.pointerPosition = Point(x: Float(px), y: Float(py))
    }

    input.pointerJustPressed = jsInput.pointerJustPressed.boolean ?? false
    input.pointerJustReleased = jsInput.pointerJustReleased.boolean ?? false

    return input
}

// MARK: - Texture Loading

/// Called from JavaScript when a texture finishes loading.
///
/// - Parameters:
///   - textureId: The assigned texture ID.
///   - imageBitmap: The loaded ImageBitmap object.
///   - width: Texture width in pixels.
///   - height: Texture height in pixels.
@_expose(wasm, "wisp_onTextureLoaded")
@_cdecl("wisp_onTextureLoaded")
public func wisp_onTextureLoaded(_ textureId: UInt32, _ width: Int32, _ height: Int32) {
    // Update SNTexture size cache so that SNTexture.size returns correct value
    let textureID = TextureID(rawValue: textureId)
    let size = Size(width: Float(width), height: Float(height))
    SNTexture.updateSizeCache(textureID: textureID, size: size)

    // Get the ImageBitmap from JavaScript
    let imageBitmaps = JSObject.global.loadedTextures
    if let imageBitmap = imageBitmaps[Int(textureId)].object {
        renderer?.textureManager.createTextureFromImage(
            textureID: textureId,
            imageBitmap: imageBitmap,
            width: UInt32(width),
            height: UInt32(height)
        )
        // Invalidate bind group cache for this texture
        renderer?.invalidateBindGroup(for: textureId)
    }
}

// MARK: - Audio

/// Request JavaScript to play a sound.
///
/// - Parameters:
///   - soundId: The sound identifier.
///   - volume: Volume level (0-1).
///   - loop: Whether to loop the sound.
public func playSound(soundId: String, volume: Float = 1.0, loop: Bool = false) {
    let playSound = JSObject.global.playSound.function!
    _ = playSound(soundId, volume, loop)
}

/// Request JavaScript to stop a sound.
public func stopSound(soundId: String) {
    let stopSound = JSObject.global.stopSound.function!
    _ = stopSound(soundId)
}

// MARK: - Logging

/// Log a message to the browser console.
public func consoleLog(_ message: String) {
    _ = JSObject.global.console.log.function!(message)
}

#endif

// MARK: - Draw Command Buffer (Legacy)

/// A C-compatible struct for passing draw commands to JavaScript.
///
/// This struct is kept for compatibility but is no longer the primary
/// rendering path. WebGPU rendering is now handled directly in Swift.
public struct DrawCommandBuffer {
    // Transform
    public var worldPositionX: Float
    public var worldPositionY: Float
    public var worldRotation: Float
    public var worldScaleX: Float
    public var worldScaleY: Float

    // Sprite data
    public var sizeWidth: Float
    public var sizeHeight: Float
    public var anchorPointX: Float
    public var anchorPointY: Float
    public var textureID: UInt32

    // Texture rect (for sub-textures/atlases)
    public var textureRectX: Float
    public var textureRectY: Float
    public var textureRectW: Float
    public var textureRectH: Float

    // Texture settings
    public var filteringMode: UInt32
    public var usesMipmaps: UInt32

    // Appearance
    public var colorR: Float
    public var colorG: Float
    public var colorB: Float
    public var colorA: Float
    public var alpha: Float
    public var zPosition: Float

    internal init(from command: DrawCommand) {
        self.worldPositionX = command.worldPosition.x
        self.worldPositionY = command.worldPosition.y
        self.worldRotation = command.worldRotation
        self.worldScaleX = command.worldScale.width
        self.worldScaleY = command.worldScale.height
        self.sizeWidth = command.size.width
        self.sizeHeight = command.size.height
        self.anchorPointX = command.anchorPoint.x
        self.anchorPointY = command.anchorPoint.y
        self.textureID = command.textureID.rawValue
        self.textureRectX = command.textureRect.origin.x
        self.textureRectY = command.textureRect.origin.y
        self.textureRectW = command.textureRect.size.width
        self.textureRectH = command.textureRect.size.height
        self.filteringMode = UInt32(command.filteringMode.rawValue)
        self.usesMipmaps = command.usesMipmaps ? 1 : 0
        self.colorR = command.color.red
        self.colorG = command.color.green
        self.colorB = command.color.blue
        self.colorA = command.color.alpha
        self.alpha = command.alpha
        self.zPosition = command.zPosition
    }
}
