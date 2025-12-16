/// A texture that can be applied to a sprite or other visual element.
///
/// `SNTexture` provides a SpriteKit-like interface for working with textures.
/// You create textures by specifying the name of an image resource, and Wisp
/// handles the platform-specific loading internally.
///
/// ## Creating Textures
/// ```swift
/// // From an image file
/// let playerTexture = SNTexture(imageNamed: "player.png")
///
/// // Use with a sprite
/// let sprite = SNSpriteNode(texture: playerTexture)
///
/// // Create a sub-texture from a sprite sheet
/// let sheet = SNTexture(imageNamed: "spritesheet.png")
/// let frame = SNTexture(rect: Rect(x: 0, y: 0, width: 0.25, height: 0.25), in: sheet)
/// ```
///
/// ## Platform Behavior
/// - **WASM**: JavaScript loads the image, assigns ID, and manages GPU texture
/// - **Native**: Loads from Bundle.main for SwiftUI Preview rendering

#if arch(wasm32)
import JavaScriptKit
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(ImageIO)
import ImageIO
#endif

#if canImport(Foundation)
import Foundation
#endif

public final class SNTexture: @unchecked Sendable {
    // MARK: - Properties

    /// The name of the image resource.
    public let name: String

    /// The internal texture identifier used by the rendering pipeline.
    internal private(set) var textureID: TextureID = .none

    /// Cached size of the texture.
    internal var _size: Size?

    /// The filtering mode used when rendering at non-native size.
    public var filteringMode: TextureFilteringMode = .linear

    /// Whether the texture uses mipmaps.
    public var usesMipmaps: Bool = false

    /// The rectangle within the source texture (normalized 0-1).
    private var _textureRect: Rect = Rect(x: 0, y: 0, width: 1, height: 1)

    /// The source texture for sub-textures.
    private var sourceTexture: SNTexture?

    #if canImport(CoreGraphics) && !arch(wasm32)
    /// Cached CGImage for native rendering.
    internal var _cgImage: CGImage?
    #endif

    // MARK: - Initialization

    /// Creates a texture from an image resource.
    ///
    /// The asset path from `Engine.configuration` is automatically prepended.
    ///
    /// - Parameter imageNamed: The name of the image file (e.g., "player.png").
    public init(imageNamed: String) {
        self.name = imageNamed

        #if arch(wasm32)
        // WASM: Build full path using Engine configuration
        let assetPath = Engine.shared.assetPath
        let fullPath = assetPath.isEmpty ? imageNamed : "\(assetPath)/\(imageNamed)"

        // Request JavaScript to load the texture
        let loadTexture = JSObject.global.loadTexture.function!
        let result = loadTexture(fullPath)
        self.textureID = TextureID(rawValue: UInt32(result.number ?? 0))
        #else
        // Native: Assign ID and load immediately
        self.textureID = TextureID(rawValue: SNTexture.getAndIncrementNativeID())
        // Load the image immediately so it's available in the cache for PreviewRenderer
        loadFromBundleIfNeeded()
        #endif
    }

    /// Creates a sub-texture from a portion of an existing texture.
    ///
    /// - Parameters:
    ///   - rect: Rectangle in unit coordinate space [0, 1].
    ///   - texture: The source texture.
    public convenience init(rect: Rect, in texture: SNTexture) {
        #if arch(wasm32)
        // WASM: Use the source texture's ID and rely on textureRect for UV cropping.
        // The GPU already has the full texture loaded, so we just reference it with different UVs.
        self.init(name: "\(texture.name)#\(rect.x),\(rect.y)", textureID: texture.textureID)
        self._textureRect = rect
        self.sourceTexture = texture
        self.filteringMode = texture.filteringMode
        self.usesMipmaps = texture.usesMipmaps

        // Calculate size from source texture size and rect
        if let sourceSize = texture._size {
            self._size = Size(
                width: sourceSize.width * rect.width,
                height: sourceSize.height * rect.height
            )
        }
        #else
        // Native: Generate new texture ID for cropped CGImage
        let newID = TextureID(rawValue: SNTexture.getAndIncrementNativeID())

        self.init(name: "\(texture.name)#\(rect.x),\(rect.y)", textureID: newID)
        self._textureRect = rect
        self.sourceTexture = texture
        self.filteringMode = texture.filteringMode
        self.usesMipmaps = texture.usesMipmaps

        #if canImport(CoreGraphics)
        // Force load source texture if needed
        texture.loadFromBundleIfNeeded()

        // Crop the CGImage for native rendering
        if let sourceCGImage = texture._cgImage {
            let imgWidth = CGFloat(sourceCGImage.width)
            let imgHeight = CGFloat(sourceCGImage.height)
            let cropRect = CGRect(
                x: CGFloat(rect.x) * imgWidth,
                y: CGFloat(rect.y) * imgHeight,
                width: CGFloat(rect.width) * imgWidth,
                height: CGFloat(rect.height) * imgHeight
            )
            if let cropped = sourceCGImage.cropping(to: cropRect) {
                self._cgImage = cropped
                self._size = Size(width: Float(cropped.width), height: Float(cropped.height))
                // Register in cache for PreviewRenderer (thread-safe)
                SNTexture.setCachedImage(cropped, for: newID)
            }
        }
        #endif
        #endif
    }

    /// Internal initializer with pre-assigned ID.
    internal init(name: String, textureID: TextureID) {
        self.name = name
        self.textureID = textureID
    }

    #if canImport(CoreGraphics) && !arch(wasm32)
    /// Creates a texture from a CGImage.
    public convenience init(cgImage: CGImage) {
        let id = TextureID(rawValue: SNTexture.getAndIncrementNativeID())
        self.init(name: "cgimage-\(id.rawValue)", textureID: id)
        self._cgImage = cgImage
        self._size = Size(width: Float(cgImage.width), height: Float(cgImage.height))
        // Store in cache for Preview rendering lookup (thread-safe)
        SNTexture.setCachedImage(cgImage, for: id)
    }
    #endif

    // MARK: - Size

    #if arch(wasm32)
    /// WASM: Global cache for texture sizes (textureID → Size).
    /// Updated by `wisp_onTextureLoaded` when JS finishes loading.
    nonisolated(unsafe) internal static var sizeCache: [TextureID: Size] = [:]

    /// Updates the size cache for a texture ID (called from WASM bridge).
    internal static func updateSizeCache(textureID: TextureID, size: Size) {
        sizeCache[textureID] = size
    }
    #endif

    /// The size of the texture in points.
    public var size: Size {
        if let cached = _size {
            return cached
        }

        #if arch(wasm32)
        // WASM: Check global size cache (populated by wisp_onTextureLoaded)
        if let cachedSize = SNTexture.sizeCache[textureID] {
            // For sub-textures, scale by textureRect
            if sourceTexture != nil {
                return Size(
                    width: cachedSize.width * _textureRect.width,
                    height: cachedSize.height * _textureRect.height
                )
            }
            return cachedSize
        }
        return .zero
        #else
        // Native: Load from bundle if needed
        loadFromBundleIfNeeded()
        let fullSize = _size ?? .zero

        if sourceTexture != nil {
            return Size(
                width: fullSize.width * _textureRect.width,
                height: fullSize.height * _textureRect.height
            )
        }
        return fullSize
        #endif
    }

    /// Gets the texture rect (portion of texture used).
    public func textureRect() -> Rect {
        return _textureRect
    }

    // MARK: - Preloading

    /// Preloads the texture data.
    public func preload() {
        _ = size
    }

    /// Preloads multiple textures.
    public static func preload(_ textures: [SNTexture], completion: @escaping () -> Void) {
        for texture in textures {
            texture.preload()
        }
        completion()
    }

    // MARK: - Sampling

    /// Samples the color at a normalized UV coordinate.
    ///
    /// Used for texture-based effects like velocity fields (flow maps).
    /// UV coordinates are in the range [0, 1], where (0, 0) is bottom-left.
    ///
    /// - Parameters:
    ///   - u: The horizontal coordinate (0-1).
    ///   - v: The vertical coordinate (0-1).
    /// - Returns: The color at the specified coordinate as (r, g, b, a) in range [0, 1].
    public func sampleColor(u: Float, v: Float) -> (r: Float, g: Float, b: Float, a: Float) {
        #if arch(wasm32)
        // WASM: Return neutral value (JavaScript handles actual sampling)
        return (0.5, 0.5, 0, 1)
        #elseif canImport(CoreGraphics)
        return sampleColorFromCGImage(u: u, v: v)
        #else
        return (0.5, 0.5, 0, 1)
        #endif
    }

    // MARK: - Normal Map Generation

    /// Creates a normal map texture by analyzing this texture's contents.
    ///
    /// Normal maps are used for per-pixel lighting effects.
    /// - Note: Currently returns self as a placeholder. Full implementation pending.
    ///
    /// - Returns: A new texture containing the normal map.
    public func generatingNormalMap() -> SNTexture {
        generatingNormalMap(withSmoothness: 1.0, contrast: 1.0)
    }

    /// Creates a normal map texture with adjustable parameters.
    ///
    /// - Parameters:
    ///   - smoothness: Controls the smoothness of the normal map (0 to 1).
    ///   - contrast: Controls the contrast of height differences.
    /// - Returns: A new texture containing the normal map.
    public func generatingNormalMap(withSmoothness smoothness: Float, contrast: Float) -> SNTexture {
        // Placeholder implementation - returns self
        // Full normal map generation would require image processing
        return self
    }

    #if canImport(CoreGraphics) && !arch(wasm32)
    /// Samples color from CGImage at UV coordinate.
    private func sampleColorFromCGImage(u: Float, v: Float) -> (r: Float, g: Float, b: Float, a: Float) {
        // Ensure image is loaded
        loadFromBundleIfNeeded()

        guard let cgImage = _cgImage else {
            return (0.5, 0.5, 0, 1)  // Neutral gray for missing texture
        }

        let width = cgImage.width
        let height = cgImage.height

        // Clamp UV coordinates
        let clampedU = max(0, min(1, u))
        let clampedV = max(0, min(1, v))

        // Convert UV to pixel coordinates (flip V for bottom-left origin)
        let pixelX = Int(clampedU * Float(width - 1))
        let pixelY = Int((1 - clampedV) * Float(height - 1))

        // Create a bitmap context to read pixel data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0.5, 0.5, 0, 1)
        }

        // Draw the single pixel
        context.draw(cgImage, in: CGRect(x: -CGFloat(pixelX), y: -CGFloat(pixelY), width: CGFloat(width), height: CGFloat(height)))

        // Convert to normalized values
        let r = Float(pixelData[0]) / 255.0
        let g = Float(pixelData[1]) / 255.0
        let b = Float(pixelData[2]) / 255.0
        let a = Float(pixelData[3]) / 255.0

        // Unpremultiply if alpha is not zero
        if a > 0 {
            return (r / a, g / a, b / a, a)
        }
        return (r, g, b, a)
    }
    #endif

    // MARK: - Native Loading

    #if !arch(wasm32)
    /// Lock for thread-safe access to static caches.
    /// Prevents race conditions when textures are created/destroyed during rendering.
    private static let cacheLock = NSLock()

    /// Counter for native texture IDs.
    /// Protected by cacheLock - use getAndIncrementNativeID() for access.
    private nonisolated(unsafe) static var _nextNativeID: UInt32 = 1

    /// Atomically gets and increments the next native ID.
    private static func getAndIncrementNativeID() -> UInt32 {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        let id = _nextNativeID
        _nextNativeID += 1
        return id
    }

    /// Cache for looking up CGImage by textureID (for Preview rendering).
    /// Protected by cacheLock - use setCachedImage() and cachedImage(for:) for access.
    private nonisolated(unsafe) static var _imageCache: [TextureID: CGImage] = [:]

    /// Thread-safe setter for image cache.
    private static func setCachedImage(_ image: CGImage, for id: TextureID) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        _imageCache[id] = image
    }

    /// Returns cached CGImage for a texture ID (thread-safe).
    internal static func cachedImage(for id: TextureID) -> CGImage? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return _imageCache[id]
    }

    #if canImport(ImageIO) && canImport(Foundation)
    /// Loads image from bundle if not already loaded.
    internal func loadFromBundleIfNeeded() {
        guard _cgImage == nil, !name.isEmpty else { return }

        guard let url = findImageURL(name: name),
              let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return
        }

        _cgImage = image
        _size = Size(width: Float(image.width), height: Float(image.height))

        // Store in cache for Preview rendering lookup (thread-safe)
        SNTexture.setCachedImage(image, for: textureID)
    }

    /// Finds the image URL in the bundle.
    private func findImageURL(name: String) -> URL? {
        let bundle = Engine.shared.resourceBundle

        // Try exact path
        if let url = bundle.url(forResource: name, withExtension: nil) {
            return url
        }

        // Try without extension
        let nameWithoutExt = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension

        if !ext.isEmpty,
           let url = bundle.url(forResource: nameWithoutExt, withExtension: ext) {
            return url
        }

        // Try common extensions
        for ext in ["png", "jpg", "jpeg"] {
            if let url = bundle.url(forResource: nameWithoutExt, withExtension: ext) {
                return url
            }
        }

        // Try Resources subdirectory (for SwiftPM packages)
        if let resourceURL = bundle.resourceURL {
            // Try with Resources prefix
            let resourcesPath = resourceURL.appendingPathComponent("Resources").appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: resourcesPath.path) {
                return resourcesPath
            }

            // Try direct path
            let directURL = resourceURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: directURL.path) {
                return directURL
            }
        }

        return nil
    }
    #else
    internal func loadFromBundleIfNeeded() {}
    #endif
    #endif
}

// MARK: - Hashable & Equatable

extension SNTexture: Hashable {
    public static func == (lhs: SNTexture, rhs: SNTexture) -> Bool {
        lhs.name == rhs.name && lhs._textureRect == rhs._textureRect
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(_textureRect.x)
        hasher.combine(_textureRect.y)
    }
}

// MARK: - CustomStringConvertible

extension SNTexture: CustomStringConvertible {
    public var description: String {
        "SNTexture(\"\(name)\")"
    }
}

// MARK: - Factory Methods

extension SNTexture {
    /// A texture representing no image (transparent).
    public static let empty = SNTexture(name: "", textureID: .none)
}

// MARK: - Platform Image Initializers

#if canImport(UIKit) && !arch(wasm32)
import UIKit

extension SNTexture {
    /// Creates a texture from a UIImage.
    public convenience init(image: UIImage) {
        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage)
        } else {
            self.init(name: "", textureID: .none)
        }
    }
}
#elseif canImport(AppKit) && !targetEnvironment(macCatalyst) && !arch(wasm32)
import AppKit

extension SNTexture {
    /// Creates a texture from an NSImage.
    public convenience init(image: NSImage) {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            self.init(cgImage: cgImage)
        } else {
            self.init(name: "", textureID: .none)
        }
    }
}
#endif
