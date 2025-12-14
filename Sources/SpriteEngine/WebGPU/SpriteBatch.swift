#if arch(wasm32)
import SwiftWebGPU

/// A batch of sprites sharing the same texture.
///
/// Sprites are grouped by texture to minimize draw calls and texture binding changes.
struct SpriteBatch {
    /// The texture ID for this batch (0 = no texture / solid color).
    let textureID: UInt32

    /// The blend mode for this batch.
    let blendMode: BlendMode

    /// Instance data for all sprites in this batch.
    var instances: [SpriteInstance] = []

    /// Number of sprites in this batch.
    var count: Int { instances.count }
}

/// Per-instance data for a single sprite.
///
/// This struct is designed to match the GPU instance buffer layout.
/// Total size: 64 bytes (aligned).
struct SpriteInstance {
    // Position in world space (8 bytes)
    var positionX: Float
    var positionY: Float

    // Size in world units (8 bytes)
    var sizeWidth: Float
    var sizeHeight: Float

    // Rotation in radians (4 bytes)
    var rotation: Float

    // Padding for alignment (4 bytes)
    var _padding1: Float = 0

    // Anchor point 0-1 (8 bytes)
    var anchorX: Float
    var anchorY: Float

    // Texture rect in UV space (16 bytes)
    var texRectX: Float
    var texRectY: Float
    var texRectW: Float
    var texRectH: Float

    // Color RGBA (16 bytes)
    var colorR: Float
    var colorG: Float
    var colorB: Float
    var colorA: Float

    // Alpha (4 bytes)
    var alpha: Float

    // Padding for alignment (12 bytes to reach 64)
    var _padding2: Float = 0
    var _padding3: Float = 0
    var _padding4: Float = 0

    /// Creates instance data from a DrawCommand.
    init(from command: DrawCommand) {
        self.positionX = command.worldPosition.x
        self.positionY = command.worldPosition.y
        self.sizeWidth = command.size.width * command.worldScale.width
        self.sizeHeight = command.size.height * command.worldScale.height
        self.rotation = command.worldRotation
        self.anchorX = command.anchorPoint.x
        self.anchorY = command.anchorPoint.y
        self.texRectX = command.textureRect.origin.x
        self.texRectY = command.textureRect.origin.y
        self.texRectW = command.textureRect.size.width
        self.texRectH = command.textureRect.size.height
        self.colorR = command.color.red
        self.colorG = command.color.green
        self.colorB = command.color.blue
        self.colorA = command.color.alpha
        self.alpha = command.alpha
    }
}

/// Batches draw commands by texture and blend mode.
struct SpriteBatcher {
    /// Groups draw commands into batches.
    ///
    /// Commands are first sorted by z-position, then grouped by texture and blend mode
    /// to minimize state changes during rendering.
    ///
    /// - Parameter commands: The draw commands to batch.
    /// - Returns: An array of sprite batches ready for rendering.
    static func batch(_ commands: [DrawCommand]) -> [SpriteBatch] {
        guard !commands.isEmpty else { return [] }

        // Sort by z-position first
        let sorted = commands.sorted { $0.zPosition < $1.zPosition }

        var batches: [SpriteBatch] = []
        var currentBatch: SpriteBatch?

        for command in sorted {
            let textureID = command.textureID.rawValue
            let blendMode = command.blendMode

            // Check if we can add to current batch
            if let batch = currentBatch,
               batch.textureID == textureID,
               batch.blendMode == blendMode {
                // Add to existing batch
                currentBatch?.instances.append(SpriteInstance(from: command))
            } else {
                // Save current batch if exists
                if let batch = currentBatch {
                    batches.append(batch)
                }
                // Start new batch
                currentBatch = SpriteBatch(
                    textureID: textureID,
                    blendMode: blendMode,
                    instances: [SpriteInstance(from: command)]
                )
            }
        }

        // Don't forget the last batch
        if let batch = currentBatch {
            batches.append(batch)
        }

        return batches
    }
}
#endif
