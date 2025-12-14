#if canImport(Foundation)
import Foundation
#endif

/// A collection of textures optimized for efficient rendering.
///
/// `TextureAtlas` combines multiple images into a single texture sheet,
/// reducing draw calls and improving performance when sprites share
/// the same atlas.
///
/// ## Platform Mapping
/// ```
/// Wisp                         SpriteKit
/// ─────────────────────────    ─────────────────────────
/// TextureAtlas                 SKTextureAtlas
/// init(named:)                 init(named:)
/// init(dictionary:)            init(dictionary:)
/// textureNamed(_:)             textureNamed(_:)
/// textureNames                 textureNames
/// preload()                    preload(completionHandler:)
/// ```
///
/// ## Creating Atlases
///
/// ### From a folder in the bundle
/// Place images in a folder with `.atlas` extension:
/// ```
/// Assets/
///   Characters.atlas/
///     player-idle.png
///     player-walk1.png
///     player-walk2.png
///     enemy.png
/// ```
///
/// Then load in code:
/// ```swift
/// let atlas = TextureAtlas(named: "Characters")
/// let playerIdle = atlas.textureNamed("player-idle")
/// let walkFrames = atlas.textures(named: ["player-walk1", "player-walk2"])
/// ```
///
/// ### From a dictionary at runtime
/// ```swift
/// let atlas = TextureAtlas(dictionary: [
///     "player": playerTexture,
///     "enemy": enemyTexture,
///     "bullet": bulletTexture
/// ])
/// ```
///
/// ## Preloading
/// ```swift
/// let atlases = [
///     TextureAtlas(named: "Characters"),
///     TextureAtlas(named: "Environment"),
///     TextureAtlas(named: "UI")
/// ]
/// TextureAtlas.preload(atlases) {
///     // All atlases are ready
///     startGame()
/// }
/// ```
public final class SNTextureAtlas: @unchecked Sendable {
    // MARK: - Properties

    /// The name of the atlas.
    public let name: String

    /// Maps texture names to their sub-textures.
    private var textures: [String: SNTexture] = [:]

    /// The backing texture that contains all sub-images (if atlas is packed).
    private var backingTexture: SNTexture?

    /// Whether the atlas has been loaded.
    private var isLoaded: Bool = false

    // MARK: - Initialization

    /// Creates a texture atlas from a named folder in the bundle.
    ///
    /// The atlas folder should have an `.atlas` extension and contain
    /// individual image files. Xcode/the build system packs these into
    /// an optimized texture sheet.
    ///
    /// - Parameter named: The name of the atlas folder (without extension).
    public init(named: String) {
        self.name = named
        loadAtlas()
    }

    /// Creates a texture atlas from a dictionary of textures.
    ///
    /// Use this initializer to create atlases at runtime from existing textures.
    /// Note: This creates a logical atlas without physical packing.
    ///
    /// - Parameter dictionary: A dictionary mapping names to textures.
    public init(dictionary: [String: SNTexture]) {
        self.name = "RuntimeAtlas"
        for (name, texture) in dictionary {
            textures[name] = texture
        }
        isLoaded = true
    }

    // MARK: - Texture Access

    /// Returns the texture with the specified name.
    ///
    /// - Parameter name: The name of the texture (without path or extension).
    /// - Returns: The texture, or nil if not found.
    public func textureNamed(_ name: String) -> SNTexture? {
        // Try exact match first
        if let texture = textures[name] {
            return texture
        }

        // Try without extension
        let nameWithoutExt = deletePathExtension(from: name)
        if let texture = textures[nameWithoutExt] {
            return texture
        }

        // Try with common extensions
        for ext in ["png", "jpg", "jpeg"] {
            if let texture = textures["\(nameWithoutExt).\(ext)"] {
                return texture
            }
        }

        return nil
    }

    /// Removes the file extension from a path string.
    private func deletePathExtension(from name: String) -> String {
        #if canImport(Foundation)
        return (name as NSString).deletingPathExtension
        #else
        // Simple implementation without Foundation
        guard let lastDotIndex = name.lastIndex(of: ".") else {
            return name
        }
        // Only treat as extension if there's no path separator after the dot
        let afterDot = name[lastDotIndex...]
        if afterDot.contains("/") || afterDot.contains("\\") {
            return name
        }
        return String(name[..<lastDotIndex])
        #endif
    }

    /// Returns textures for the specified names.
    ///
    /// - Parameter names: An array of texture names.
    /// - Returns: An array of textures (skipping any not found).
    public func textures(named names: [String]) -> [SNTexture] {
        names.compactMap { textureNamed($0) }
    }

    /// Returns all texture names in this atlas.
    public var textureNames: [String] {
        Array(textures.keys).sorted()
    }

    /// Returns all textures in this atlas.
    public var allTextures: [SNTexture] {
        Array(textures.values)
    }

    // MARK: - Preloading

    /// Preloads the atlas textures.
    ///
    /// Call this to ensure textures are loaded before they're needed.
    public func preload() {
        for texture in textures.values {
            texture.preload()
        }
    }

    /// Preloads multiple atlases.
    ///
    /// - Parameters:
    ///   - atlases: The atlases to preload.
    ///   - completion: Called when all atlases are loaded.
    public static func preload(_ atlases: [SNTextureAtlas], completion: @escaping () -> Void) {
        for atlas in atlases {
            atlas.preload()
        }
        completion()
    }

    // MARK: - Atlas Loading

    /// Loads the atlas from the bundle.
    private func loadAtlas() {
        #if canImport(Foundation)
        // Try to find the atlas folder
        let bundle = Bundle.main

        // Look for .atlas folder
        guard let atlasURL = findAtlasURL(bundle: bundle) else {
            // Atlas not found, but we don't fail - textures will be empty
            isLoaded = true
            return
        }

        // Load all images from the atlas folder
        loadImagesFromFolder(atlasURL)
        isLoaded = true
        #else
        // On WASM, atlas loading is handled by JavaScript runtime
        isLoaded = true
        #endif
    }

    #if canImport(Foundation)
    /// Finds the atlas folder URL in the bundle.
    private func findAtlasURL(bundle: Bundle) -> URL? {
        // Try direct path
        if let url = bundle.url(forResource: name, withExtension: "atlas") {
            return url
        }

        // Try in Resources
        if let resourceURL = bundle.resourceURL {
            let atlasURL = resourceURL.appendingPathComponent("\(name).atlas")
            if FileManager.default.fileExists(atPath: atlasURL.path) {
                return atlasURL
            }
        }

        return nil
    }

    /// Loads all images from an atlas folder.
    private func loadImagesFromFolder(_ folderURL: URL) {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let imageExtensions = Set(["png", "jpg", "jpeg", "gif", "webp"])

        for fileURL in contents {
            let ext = fileURL.pathExtension.lowercased()
            guard imageExtensions.contains(ext) else { continue }

            let fileName = fileURL.lastPathComponent
            let nameWithoutExt = (fileName as NSString).deletingPathExtension

            // Create texture for this image
            let texture = SNTexture(atlasName: name, imageName: nameWithoutExt)
            textures[nameWithoutExt] = texture
            textures[fileName] = texture  // Also store with extension
        }
    }
    #endif
}

// MARK: - Hashable & Equatable

extension SNTextureAtlas: Hashable {
    public static func == (lhs: SNTextureAtlas, rhs: SNTextureAtlas) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - CustomStringConvertible

extension SNTextureAtlas: CustomStringConvertible {
    public var description: String {
        "TextureAtlas(\"\(name)\", \(textures.count) textures)"
    }
}

// MARK: - Texture Extension for Atlas Support

extension SNTexture {
    /// Creates a texture that belongs to an atlas.
    ///
    /// - Parameters:
    ///   - atlasName: The name of the containing atlas.
    ///   - imageName: The name of the image within the atlas.
    internal convenience init(atlasName: String, imageName: String) {
        // The full path for registry lookup
        let fullName = "\(atlasName)/\(imageName)"
        self.init(imageNamed: fullName)
    }
}

// MARK: - Animation Support

extension SNTextureAtlas {
    /// Returns textures that match a pattern, sorted by name.
    ///
    /// Useful for loading animation frames:
    /// ```swift
    /// // Load player-walk1, player-walk2, player-walk3, etc.
    /// let walkFrames = atlas.textures(withPrefix: "player-walk")
    /// ```
    ///
    /// - Parameter prefix: The prefix to match.
    /// - Returns: Textures with matching names, sorted alphabetically.
    public func textures(withPrefix prefix: String) -> [SNTexture] {
        textureNames
            .filter { $0.hasPrefix(prefix) }
            .sorted()
            .compactMap { textures[$0] }
    }

    /// Returns textures that match a pattern with numbered suffix.
    ///
    /// Loads frames in numeric order:
    /// ```swift
    /// // Load run0, run1, run2, ... run9
    /// let runFrames = atlas.textures(named: "run", range: 0..<10)
    /// ```
    ///
    /// - Parameters:
    ///   - baseName: The base name before the number.
    ///   - range: The range of numbers to load.
    /// - Returns: An array of textures.
    public func textures(named baseName: String, range: Swift.Range<Int>) -> [SNTexture] {
        range.compactMap { index in
            textureNamed("\(baseName)\(index)")
        }
    }

    /// Returns textures that match a pattern with numbered suffix.
    ///
    /// - Parameters:
    ///   - baseName: The base name before the number.
    ///   - range: The closed range of numbers to load.
    /// - Returns: An array of textures.
    public func textures(named baseName: String, range: Swift.ClosedRange<Int>) -> [SNTexture] {
        range.compactMap { index in
            textureNamed("\(baseName)\(index)")
        }
    }
}
