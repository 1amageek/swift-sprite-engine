#if arch(wasm32)
import SwiftWebGPU
import JavaScriptKit

/// Manages GPU textures for the WebGPU renderer.
///
/// Handles loading textures from images and caching them for efficient reuse.
final class WebGPUTextureManager {
    /// The GPU device used to create textures.
    private let device: GPUDevice

    /// Cache of loaded textures by ID.
    private var textureCache: [UInt32: GPUTexture] = [:]

    /// Cache of texture views by ID.
    private var viewCache: [UInt32: GPUTextureView] = [:]

    /// A 1x1 white texture for solid color rendering.
    private(set) var whiteTexture: GPUTexture!
    private(set) var whiteTextureView: GPUTextureView!

    /// The default sampler for texture sampling.
    private(set) var defaultSampler: GPUSampler!

    /// Creates a texture manager.
    ///
    /// - Parameter device: The GPU device to use for texture creation.
    init(device: GPUDevice) {
        self.device = device
        createDefaultResources()
    }

    /// Creates default resources (white texture, sampler).
    private func createDefaultResources() {
        // Create 1x1 white texture for solid color sprites
        whiteTexture = device.createTexture(descriptor: GPUTextureDescriptor(
            size: GPUExtent3D(width: 1, height: 1),
            format: .rgba8unorm,
            usage: [.textureBinding, .copyDst]
        ))

        // Upload white pixel data
        let whitePixel: [UInt8] = [255, 255, 255, 255]
        whitePixel.withUnsafeBytes { bytes in
            let uint8Array = JSObject.global.Uint8Array.function!.new(4)
            for i in 0..<4 {
                uint8Array[i] = .number(Double(bytes[i]))
            }

            device.queue.writeTexture(
                destination: GPUImageCopyTexture(texture: whiteTexture),
                data: uint8Array,
                dataLayout: GPUImageDataLayout(bytesPerRow: 4, rowsPerImage: 1),
                size: GPUExtent3D(width: 1, height: 1)
            )
        }

        whiteTextureView = whiteTexture.createView()

        // Create default sampler with linear filtering
        defaultSampler = device.createSampler(descriptor: GPUSamplerDescriptor(
            addressModeU: .clampToEdge,
            addressModeV: .clampToEdge,
            magFilter: .linear,
            minFilter: .linear,
            mipmapFilter: .linear
        ))
    }

    /// Gets the texture view for a texture ID.
    ///
    /// - Parameter textureID: The texture ID.
    /// - Returns: The texture view, or the white texture view if not found.
    func getTextureView(for textureID: UInt32) -> GPUTextureView {
        if textureID == 0 {
            return whiteTextureView
        }
        return viewCache[textureID] ?? whiteTextureView
    }

    /// Creates a texture from image data.
    ///
    /// - Parameters:
    ///   - textureID: The texture ID to assign.
    ///   - imageBitmap: The ImageBitmap from JavaScript.
    ///   - width: The texture width.
    ///   - height: The texture height.
    func createTextureFromImage(
        textureID: UInt32,
        imageBitmap: JSObject,
        width: UInt32,
        height: UInt32
    ) {
        let texture = device.createTexture(descriptor: GPUTextureDescriptor(
            size: GPUExtent3D(width: width, height: height),
            format: .rgba8unorm,
            usage: [.textureBinding, .copyDst, .renderAttachment]
        ))

        // Copy image to texture (flipY to match WebGPU's bottom-left origin)
        device.queue.copyExternalImageToTexture(
            source: GPUImageCopyExternalImage(source: imageBitmap, flipY: true),
            destination: GPUImageCopyTextureTagged(texture: texture),
            copySize: GPUExtent3D(width: width, height: height)
        )

        textureCache[textureID] = texture
        viewCache[textureID] = texture.createView()
    }

    /// Removes a texture from the cache.
    ///
    /// - Parameter textureID: The texture ID to remove.
    func removeTexture(textureID: UInt32) {
        if let texture = textureCache.removeValue(forKey: textureID) {
            texture.destroy()
        }
        viewCache.removeValue(forKey: textureID)
    }

    /// Clears all cached textures.
    func clearCache() {
        for texture in textureCache.values {
            texture.destroy()
        }
        textureCache.removeAll()
        viewCache.removeAll()
    }
}
#endif
