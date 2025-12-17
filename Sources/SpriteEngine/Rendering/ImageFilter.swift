/// A filter that can be applied to images and textures to create visual effects.
///
/// `ImageFilter` provides a platform-agnostic abstraction for image processing,
/// similar to Apple's Core Image (CIFilter) but designed to work across
/// all platforms including WebGPU.
///
/// ## Platform Mapping
/// ```
/// Wisp                         Apple (Preview)      Web (WebGPU)
/// ─────────────────────────    ─────────────────    ─────────────────
/// ImageFilter                  CIFilter             Compute Shader
/// .gaussianBlur(radius:)       CIGaussianBlur       blur.wgsl
/// .colorMatrix(_:)             CIColorMatrix        colorMatrix.wgsl
/// .grayscale                   CIPhotoEffectMono    grayscale.wgsl
/// ```
///
/// ## Usage
/// ```swift
/// // Apply a single filter
/// let blurred = texture.applying(.gaussianBlur(radius: 10))
///
/// // Chain multiple filters
/// let processed = texture
///     .applying(.colorAdjust(brightness: 0.1, contrast: 1.2))
///     .applying(.gaussianBlur(radius: 5))
///
/// // Use with sprites
/// let sprite = SpriteNode(texture: texture.applying(.sepia(intensity: 0.8)))
/// ```
///
/// ## Custom Filters
/// For real-time effects that change every frame, use `Shader` instead.
/// `ImageFilter` is for pre-processing textures before rendering.
public struct ImageFilter: Hashable, Sendable {
    // MARK: - Filter Type

    /// The type of filter operation.
    public enum FilterType: Hashable, Sendable {
        // MARK: Blur
        /// Gaussian blur with specified radius.
        case gaussianBlur(radius: Float)
        /// Box blur (faster but lower quality).
        case boxBlur(radius: Float)
        /// Motion blur in a specific direction.
        case motionBlur(radius: Float, angle: Float)

        // MARK: Color Adjustment
        /// Adjusts brightness, contrast, and saturation.
        case colorAdjust(brightness: Float, contrast: Float, saturation: Float)
        /// Adjusts hue rotation in radians.
        case hueRotate(angle: Float)
        /// Applies a color matrix transformation.
        case colorMatrix(matrix: ColorMatrix)
        /// Adjusts exposure.
        case exposure(ev: Float)
        /// Adjusts gamma.
        case gamma(value: Float)
        /// Adjusts vibrance (smart saturation).
        case vibrance(amount: Float)

        // MARK: Color Effects
        /// Converts to grayscale.
        case grayscale
        /// Applies sepia tone effect.
        case sepia(intensity: Float)
        /// Inverts colors.
        case colorInvert
        /// Applies a color tint.
        case colorTint(color: Color)
        /// Posterize effect (reduce color levels).
        case posterize(levels: Int)
        /// Threshold effect (black and white based on luminance).
        case threshold(value: Float)

        // MARK: Stylize
        /// Pixelate effect.
        case pixelate(scale: Float)
        /// Edge detection.
        case edges(intensity: Float)
        /// Sharpen.
        case sharpen(sharpness: Float)
        /// Vignette effect.
        case vignette(radius: Float, intensity: Float)

        // MARK: Blend
        /// Blend with another color using a blend mode.
        /// Uses `SNBlendMode` from `BlendMode.swift`.
        case colorBlend(color: Color, mode: SNBlendMode)

        // MARK: Generator
        /// Generate a solid color texture.
        case solidColor(color: Color)
        /// Generate a linear gradient.
        case linearGradient(start: Color, end: Color, angle: Float)
        /// Generate a radial gradient.
        case radialGradient(center: Color, edge: Color, radius: Float)
    }

    /// The filter operation to apply.
    public let type: FilterType

    /// Optional input size (for generated textures).
    public var inputSize: Size?

    // MARK: - Initialization

    /// Creates a filter with the specified type.
    public init(_ type: FilterType) {
        self.type = type
    }

    // MARK: - Factory Methods (Blur)

    /// Creates a Gaussian blur filter.
    ///
    /// - Parameter radius: The blur radius in pixels. Default is 10.
    /// - Returns: A Gaussian blur filter.
    public static func gaussianBlur(radius: Float = 10) -> ImageFilter {
        ImageFilter(.gaussianBlur(radius: radius))
    }

    /// Creates a box blur filter.
    ///
    /// - Parameter radius: The blur radius in pixels.
    /// - Returns: A box blur filter.
    public static func boxBlur(radius: Float = 10) -> ImageFilter {
        ImageFilter(.boxBlur(radius: radius))
    }

    /// Creates a motion blur filter.
    ///
    /// - Parameters:
    ///   - radius: The blur radius.
    ///   - angle: The blur angle in radians.
    /// - Returns: A motion blur filter.
    public static func motionBlur(radius: Float = 10, angle: Float = 0) -> ImageFilter {
        ImageFilter(.motionBlur(radius: radius, angle: angle))
    }

    // MARK: - Factory Methods (Color Adjustment)

    /// Creates a color adjustment filter.
    ///
    /// - Parameters:
    ///   - brightness: Brightness adjustment (-1 to 1). Default is 0.
    ///   - contrast: Contrast multiplier. Default is 1.
    ///   - saturation: Saturation multiplier. Default is 1.
    /// - Returns: A color adjustment filter.
    public static func colorAdjust(
        brightness: Float = 0,
        contrast: Float = 1,
        saturation: Float = 1
    ) -> ImageFilter {
        ImageFilter(.colorAdjust(brightness: brightness, contrast: contrast, saturation: saturation))
    }

    /// Creates a hue rotation filter.
    ///
    /// - Parameter angle: The rotation angle in radians.
    /// - Returns: A hue rotation filter.
    public static func hueRotate(angle: Float) -> ImageFilter {
        ImageFilter(.hueRotate(angle: angle))
    }

    /// Creates a color matrix filter.
    ///
    /// - Parameter matrix: The 4x4 color transformation matrix.
    /// - Returns: A color matrix filter.
    public static func colorMatrix(_ matrix: ColorMatrix) -> ImageFilter {
        ImageFilter(.colorMatrix(matrix: matrix))
    }

    /// Creates an exposure adjustment filter.
    ///
    /// - Parameter ev: Exposure value adjustment.
    /// - Returns: An exposure filter.
    public static func exposure(ev: Float) -> ImageFilter {
        ImageFilter(.exposure(ev: ev))
    }

    /// Creates a gamma adjustment filter.
    ///
    /// - Parameter value: Gamma value. 1.0 is neutral.
    /// - Returns: A gamma filter.
    public static func gamma(_ value: Float) -> ImageFilter {
        ImageFilter(.gamma(value: value))
    }

    /// Creates a vibrance filter.
    ///
    /// - Parameter amount: Vibrance amount (-1 to 1).
    /// - Returns: A vibrance filter.
    public static func vibrance(_ amount: Float) -> ImageFilter {
        ImageFilter(.vibrance(amount: amount))
    }

    // MARK: - Factory Methods (Color Effects)

    /// Creates a grayscale filter.
    public static var grayscale: ImageFilter {
        ImageFilter(.grayscale)
    }

    /// Creates a sepia tone filter.
    ///
    /// - Parameter intensity: Effect intensity (0 to 1). Default is 1.
    /// - Returns: A sepia filter.
    public static func sepia(intensity: Float = 1) -> ImageFilter {
        ImageFilter(.sepia(intensity: intensity))
    }

    /// Creates a color inversion filter.
    public static var colorInvert: ImageFilter {
        ImageFilter(.colorInvert)
    }

    /// Creates a color tint filter.
    ///
    /// - Parameter color: The tint color.
    /// - Returns: A color tint filter.
    public static func colorTint(_ color: Color) -> ImageFilter {
        ImageFilter(.colorTint(color: color))
    }

    /// Creates a posterize filter.
    ///
    /// - Parameter levels: Number of color levels per channel.
    /// - Returns: A posterize filter.
    public static func posterize(levels: Int = 6) -> ImageFilter {
        ImageFilter(.posterize(levels: levels))
    }

    /// Creates a threshold filter.
    ///
    /// - Parameter value: Luminance threshold (0 to 1).
    /// - Returns: A threshold filter.
    public static func threshold(_ value: Float = 0.5) -> ImageFilter {
        ImageFilter(.threshold(value: value))
    }

    // MARK: - Factory Methods (Stylize)

    /// Creates a pixelate filter.
    ///
    /// - Parameter scale: Pixel size scale.
    /// - Returns: A pixelate filter.
    public static func pixelate(scale: Float = 8) -> ImageFilter {
        ImageFilter(.pixelate(scale: scale))
    }

    /// Creates an edge detection filter.
    ///
    /// - Parameter intensity: Edge intensity.
    /// - Returns: An edges filter.
    public static func edges(intensity: Float = 1) -> ImageFilter {
        ImageFilter(.edges(intensity: intensity))
    }

    /// Creates a sharpen filter.
    ///
    /// - Parameter sharpness: Sharpening amount.
    /// - Returns: A sharpen filter.
    public static func sharpen(_ sharpness: Float = 0.5) -> ImageFilter {
        ImageFilter(.sharpen(sharpness: sharpness))
    }

    /// Creates a vignette filter.
    ///
    /// - Parameters:
    ///   - radius: Vignette radius (0 to 1).
    ///   - intensity: Darkness intensity.
    /// - Returns: A vignette filter.
    public static func vignette(radius: Float = 0.5, intensity: Float = 0.5) -> ImageFilter {
        ImageFilter(.vignette(radius: radius, intensity: intensity))
    }

    // MARK: - Factory Methods (Blend)

    /// Creates a color blend filter.
    ///
    /// - Parameters:
    ///   - color: The color to blend.
    ///   - mode: The blend mode to use.
    /// - Returns: A color blend filter.
    public static func colorBlend(_ color: Color, mode: SNBlendMode = .multiply) -> ImageFilter {
        ImageFilter(.colorBlend(color: color, mode: mode))
    }

    /// Creates a color blend filter with alpha blending.
    ///
    /// - Parameter color: The color to blend.
    /// - Returns: A color blend filter with alpha mode.
    public static func colorBlendAlpha(_ color: Color) -> ImageFilter {
        ImageFilter(.colorBlend(color: color, mode: .alpha))
    }

    // MARK: - Factory Methods (Generator)

    /// Creates a solid color texture generator.
    ///
    /// - Parameters:
    ///   - color: The fill color.
    ///   - size: The output size.
    /// - Returns: A solid color generator filter.
    public static func solidColor(_ color: Color, size: Size) -> ImageFilter {
        var filter = ImageFilter(.solidColor(color: color))
        filter.inputSize = size
        return filter
    }

    /// Creates a linear gradient texture generator.
    ///
    /// - Parameters:
    ///   - start: Start color.
    ///   - end: End color.
    ///   - angle: Gradient angle in radians.
    ///   - size: The output size.
    /// - Returns: A linear gradient generator filter.
    public static func linearGradient(
        start: Color,
        end: Color,
        angle: Float = 0,
        size: Size
    ) -> ImageFilter {
        var filter = ImageFilter(.linearGradient(start: start, end: end, angle: angle))
        filter.inputSize = size
        return filter
    }

    /// Creates a radial gradient texture generator.
    ///
    /// - Parameters:
    ///   - center: Center color.
    ///   - edge: Edge color.
    ///   - radius: Gradient radius (0 to 1).
    ///   - size: The output size.
    /// - Returns: A radial gradient generator filter.
    public static func radialGradient(
        center: Color,
        edge: Color,
        radius: Float = 1,
        size: Size
    ) -> ImageFilter {
        var filter = ImageFilter(.radialGradient(center: center, edge: edge, radius: radius))
        filter.inputSize = size
        return filter
    }
}

// MARK: - Color Matrix

/// A 4x5 matrix for color transformations.
///
/// The matrix operates on RGBA color values:
/// ```
/// | r' |   | m00 m01 m02 m03 m04 |   | r |
/// | g' | = | m10 m11 m12 m13 m14 | × | g |
/// | b' |   | m20 m21 m22 m23 m24 |   | b |
/// | a' |   | m30 m31 m32 m33 m34 |   | a |
///                                    | 1 |
/// ```
///
/// The fifth column (m04, m14, m24, m34) contains bias values that are added
/// after the matrix multiplication.
public struct ColorMatrix: Hashable, Sendable {
    /// Matrix values in row-major order (4 rows × 5 columns).
    public var values: [CGFloat]

    /// Creates an identity color matrix.
    public init() {
        self.values = [
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0
        ]
    }

    /// Creates a color matrix with the specified values.
    ///
    /// - Parameter values: 20 float values in row-major order.
    public init(values: [CGFloat]) {
        precondition(values.count == 20, "ColorMatrix requires exactly 20 values")
        self.values = values
    }

    /// The identity matrix (no transformation).
    public static let identity = ColorMatrix()

    /// Creates a saturation adjustment matrix.
    ///
    /// - Parameter s: Saturation multiplier. 0 = grayscale, 1 = original.
    public static func saturation(_ s: CGFloat) -> ColorMatrix {
        let lumR: CGFloat = 0.3086
        let lumG: CGFloat = 0.6094
        let lumB: CGFloat = 0.0820

        let sr = (1 - s) * lumR
        let sg = (1 - s) * lumG
        let sb = (1 - s) * lumB

        return ColorMatrix(values: [
            sr + s, sg,     sb,     0, 0,
            sr,     sg + s, sb,     0, 0,
            sr,     sg,     sb + s, 0, 0,
            0,      0,      0,      1, 0
        ])
    }

    /// Creates a brightness adjustment matrix.
    ///
    /// - Parameter b: Brightness offset (-1 to 1).
    public static func brightness(_ b: CGFloat) -> ColorMatrix {
        ColorMatrix(values: [
            1, 0, 0, 0, b,
            0, 1, 0, 0, b,
            0, 0, 1, 0, b,
            0, 0, 0, 1, 0
        ])
    }

    /// Creates a contrast adjustment matrix.
    ///
    /// - Parameter c: Contrast multiplier.
    public static func contrast(_ c: CGFloat) -> ColorMatrix {
        let t = (1 - c) / 2
        return ColorMatrix(values: [
            c, 0, 0, 0, t,
            0, c, 0, 0, t,
            0, 0, c, 0, t,
            0, 0, 0, 1, 0
        ])
    }

    /// Creates a sepia tone matrix.
    ///
    /// - Parameter intensity: Effect intensity (0 to 1).
    public static func sepia(_ intensity: CGFloat = 1) -> ColorMatrix {
        let i = intensity
        let ni = 1 - intensity

        return ColorMatrix(values: [
            ni + i * 0.393, i * 0.769, i * 0.189, 0, 0,
            i * 0.349, ni + i * 0.686, i * 0.168, 0, 0,
            i * 0.272, i * 0.534, ni + i * 0.131, 0, 0,
            0, 0, 0, 1, 0
        ])
    }

    /// Multiplies two color matrices.
    public static func * (lhs: ColorMatrix, rhs: ColorMatrix) -> ColorMatrix {
        var result = [CGFloat](repeating: 0, count: 20)

        for row in 0..<4 {
            for col in 0..<5 {
                var sum: CGFloat = 0
                for k in 0..<4 {
                    sum += lhs.values[row * 5 + k] * rhs.values[k * 5 + col]
                }
                if col == 4 {
                    sum += lhs.values[row * 5 + 4]
                }
                result[row * 5 + col] = sum
            }
        }

        return ColorMatrix(values: result)
    }
}

// Note: SNBlendMode is defined in BlendMode.swift and used for both
// sprite rendering and filter compositing operations.

// MARK: - Filter Chain

/// A chain of filters to be applied in sequence.
///
/// Use filter chains to combine multiple effects:
/// ```swift
/// let chain = ImageFilterChain(
///     .colorAdjust(brightness: 0.1),
///     .gaussianBlur(radius: 5),
///     .vignette(radius: 0.8, intensity: 0.3)
/// )
/// let processed = texture.applying(chain)
/// ```
public struct ImageFilterChain: Hashable, Sendable {
    /// The filters in the chain.
    public var filters: [ImageFilter]

    /// Creates an empty filter chain.
    public init() {
        self.filters = []
    }

    /// Creates a filter chain with the specified filters.
    public init(_ filters: [ImageFilter]) {
        self.filters = filters
    }

    /// Creates a filter chain with the specified filters.
    public init(_ filters: ImageFilter...) {
        self.filters = filters
    }

    /// Appends a filter to the chain.
    public mutating func append(_ filter: ImageFilter) {
        filters.append(filter)
    }

    /// Returns a new chain with the filter appended.
    public func appending(_ filter: ImageFilter) -> ImageFilterChain {
        var chain = self
        chain.append(filter)
        return chain
    }

    /// Returns true if the chain has no filters.
    public var isEmpty: Bool {
        filters.isEmpty
    }

    /// The number of filters in the chain.
    public var count: Int {
        filters.count
    }
}

// MARK: - CustomStringConvertible

extension ImageFilter: CustomStringConvertible {
    public var description: String {
        switch type {
        case .gaussianBlur(let radius):
            return "ImageFilter.gaussianBlur(radius: \(radius))"
        case .boxBlur(let radius):
            return "ImageFilter.boxBlur(radius: \(radius))"
        case .motionBlur(let radius, let angle):
            return "ImageFilter.motionBlur(radius: \(radius), angle: \(angle))"
        case .colorAdjust(let b, let c, let s):
            return "ImageFilter.colorAdjust(brightness: \(b), contrast: \(c), saturation: \(s))"
        case .hueRotate(let angle):
            return "ImageFilter.hueRotate(angle: \(angle))"
        case .colorMatrix:
            return "ImageFilter.colorMatrix(...)"
        case .exposure(let ev):
            return "ImageFilter.exposure(ev: \(ev))"
        case .gamma(let value):
            return "ImageFilter.gamma(\(value))"
        case .vibrance(let amount):
            return "ImageFilter.vibrance(\(amount))"
        case .grayscale:
            return "ImageFilter.grayscale"
        case .sepia(let intensity):
            return "ImageFilter.sepia(intensity: \(intensity))"
        case .colorInvert:
            return "ImageFilter.colorInvert"
        case .colorTint(let color):
            return "ImageFilter.colorTint(\(color))"
        case .posterize(let levels):
            return "ImageFilter.posterize(levels: \(levels))"
        case .threshold(let value):
            return "ImageFilter.threshold(\(value))"
        case .pixelate(let scale):
            return "ImageFilter.pixelate(scale: \(scale))"
        case .edges(let intensity):
            return "ImageFilter.edges(intensity: \(intensity))"
        case .sharpen(let sharpness):
            return "ImageFilter.sharpen(\(sharpness))"
        case .vignette(let radius, let intensity):
            return "ImageFilter.vignette(radius: \(radius), intensity: \(intensity))"
        case .colorBlend(let color, let mode):
            return "ImageFilter.colorBlend(\(color), mode: \(mode))"
        case .solidColor(let color):
            return "ImageFilter.solidColor(\(color))"
        case .linearGradient:
            return "ImageFilter.linearGradient(...)"
        case .radialGradient:
            return "ImageFilter.radialGradient(...)"
        }
    }
}

extension ImageFilterChain: CustomStringConvertible {
    public var description: String {
        "ImageFilterChain(\(filters.count) filters)"
    }
}
