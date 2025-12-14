/// A structure that represents an RGBA color.
///
/// `Color` represents colors using red, green, blue, and alpha components,
/// each in the range [0, 1]. It uses `Float` for WebAssembly compatibility.
public struct Color: Hashable, Sendable {
    /// The red component (0-1).
    public var red: Float

    /// The green component (0-1).
    public var green: Float

    /// The blue component (0-1).
    public var blue: Float

    /// The alpha (opacity) component (0-1).
    public var alpha: Float

    /// Creates a color with the specified RGBA components.
    ///
    /// - Parameters:
    ///   - red: The red component (0-1).
    ///   - green: The green component (0-1).
    ///   - blue: The blue component (0-1).
    ///   - alpha: The alpha component (0-1). Defaults to 1 (fully opaque).
    @inlinable
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

// MARK: - Convenience Initializers

extension Color {
    /// Creates a grayscale color.
    ///
    /// - Parameters:
    ///   - white: The white level (0 = black, 1 = white).
    ///   - alpha: The alpha component (0-1). Defaults to 1.
    @inlinable
    public init(white: Float, alpha: Float = 1) {
        self.red = white
        self.green = white
        self.blue = white
        self.alpha = alpha
    }

    /// Creates a color from 8-bit integer components (0-255).
    @inlinable
    public init(red255: UInt8, green255: UInt8, blue255: UInt8, alpha255: UInt8 = 255) {
        self.red = Float(red255) / 255
        self.green = Float(green255) / 255
        self.blue = Float(blue255) / 255
        self.alpha = Float(alpha255) / 255
    }

    /// Creates a color from a hex integer (0xRRGGBB or 0xRRGGBBAA).
    ///
    /// - Parameter hex: The hex value. If 6 digits, alpha defaults to 1.
    @inlinable
    public init(hex: UInt32) {
        if hex > 0xFFFFFF {
            // 8 digits: RRGGBBAA
            self.red = Float((hex >> 24) & 0xFF) / 255
            self.green = Float((hex >> 16) & 0xFF) / 255
            self.blue = Float((hex >> 8) & 0xFF) / 255
            self.alpha = Float(hex & 0xFF) / 255
        } else {
            // 6 digits: RRGGBB
            self.red = Float((hex >> 16) & 0xFF) / 255
            self.green = Float((hex >> 8) & 0xFF) / 255
            self.blue = Float(hex & 0xFF) / 255
            self.alpha = 1
        }
    }

    /// Creates a color from HSB (Hue, Saturation, Brightness) values.
    ///
    /// - Parameters:
    ///   - hue: The hue (0-1, where 0 and 1 are both red).
    ///   - saturation: The saturation (0-1).
    ///   - brightness: The brightness (0-1).
    ///   - alpha: The alpha component (0-1). Defaults to 1.
    @inlinable
    public init(hue: Float, saturation: Float, brightness: Float, alpha: Float = 1) {
        let h = hue * 6
        let s = saturation
        let v = brightness
        let i = Int(h)
        let f = h - Float(i)
        let p = v * (1 - s)
        let q = v * (1 - s * f)
        let t = v * (1 - s * (1 - f))

        switch i % 6 {
        case 0:
            self.init(red: v, green: t, blue: p, alpha: alpha)
        case 1:
            self.init(red: q, green: v, blue: p, alpha: alpha)
        case 2:
            self.init(red: p, green: v, blue: t, alpha: alpha)
        case 3:
            self.init(red: p, green: q, blue: v, alpha: alpha)
        case 4:
            self.init(red: t, green: p, blue: v, alpha: alpha)
        default:
            self.init(red: v, green: p, blue: q, alpha: alpha)
        }
    }
}

// MARK: - Preset Colors

extension Color {
    /// Transparent (alpha = 0).
    public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)

    /// Black.
    public static let black = Color(red: 0, green: 0, blue: 0)

    /// White.
    public static let white = Color(red: 1, green: 1, blue: 1)

    /// Gray (50% brightness).
    public static let gray = Color(white: 0.5)

    /// Light gray.
    public static let lightGray = Color(white: 0.75)

    /// Dark gray.
    public static let darkGray = Color(white: 0.25)

    /// Red.
    public static let red = Color(red: 1, green: 0, blue: 0)

    /// Green.
    public static let green = Color(red: 0, green: 1, blue: 0)

    /// Blue.
    public static let blue = Color(red: 0, green: 0, blue: 1)

    /// Cyan.
    public static let cyan = Color(red: 0, green: 1, blue: 1)

    /// Magenta.
    public static let magenta = Color(red: 1, green: 0, blue: 1)

    /// Yellow.
    public static let yellow = Color(red: 1, green: 1, blue: 0)

    /// Orange.
    public static let orange = Color(red: 1, green: 0.5, blue: 0)

    /// Purple.
    public static let purple = Color(red: 0.5, green: 0, blue: 0.5)

    /// Brown.
    public static let brown = Color(red: 0.6, green: 0.4, blue: 0.2)

    /// Pink.
    public static let pink = Color(red: 1, green: 0.75, blue: 0.8)
}

// MARK: - Component Access

extension Color {
    /// The color components as an array [red, green, blue, alpha].
    @inlinable
    public var components: [Float] {
        [red, green, blue, alpha]
    }

    /// The RGB components as an array [red, green, blue].
    @inlinable
    public var rgbComponents: [Float] {
        [red, green, blue]
    }

    /// Returns the color as a 32-bit RGBA integer (0xRRGGBBAA).
    @inlinable
    public var rgba32: UInt32 {
        let r = UInt32(max(0, min(255, red * 255)))
        let g = UInt32(max(0, min(255, green * 255)))
        let b = UInt32(max(0, min(255, blue * 255)))
        let a = UInt32(max(0, min(255, alpha * 255)))
        return (r << 24) | (g << 16) | (b << 8) | a
    }

    /// Returns the color as a 32-bit RGB integer (0xRRGGBB).
    @inlinable
    public var rgb24: UInt32 {
        let r = UInt32(max(0, min(255, red * 255)))
        let g = UInt32(max(0, min(255, green * 255)))
        let b = UInt32(max(0, min(255, blue * 255)))
        return (r << 16) | (g << 8) | b
    }
}

// MARK: - HSB Access

extension Color {
    /// The hue component (0-1).
    @inlinable
    public var hue: Float {
        let maxC = max(red, max(green, blue))
        let minC = min(red, min(green, blue))
        let delta = maxC - minC

        guard delta > 0 else { return 0 }

        var h: Float
        if maxC == red {
            h = (green - blue) / delta
            if h < 0 { h += 6 }
        } else if maxC == green {
            h = 2 + (blue - red) / delta
        } else {
            h = 4 + (red - green) / delta
        }

        return h / 6
    }

    /// The saturation component (0-1).
    @inlinable
    public var saturation: Float {
        let maxC = max(red, max(green, blue))
        let minC = min(red, min(green, blue))
        guard maxC > 0 else { return 0 }
        return (maxC - minC) / maxC
    }

    /// The brightness component (0-1).
    @inlinable
    public var brightness: Float {
        max(red, max(green, blue))
    }

    /// The luminance according to the sRGB color space.
    @inlinable
    public var luminance: Float {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}

// MARK: - Color Manipulation

extension Color {
    /// Returns a new color with the alpha component changed.
    @inlinable
    public func withAlpha(_ alpha: Float) -> Color {
        Color(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Returns a lighter version of this color.
    ///
    /// - Parameter amount: How much to lighten (0-1). Default is 0.2.
    @inlinable
    public func lighter(by amount: Float = 0.2) -> Color {
        Color(
            red: min(1, red + amount),
            green: min(1, green + amount),
            blue: min(1, blue + amount),
            alpha: alpha
        )
    }

    /// Returns a darker version of this color.
    ///
    /// - Parameter amount: How much to darken (0-1). Default is 0.2.
    @inlinable
    public func darker(by amount: Float = 0.2) -> Color {
        Color(
            red: max(0, red - amount),
            green: max(0, green - amount),
            blue: max(0, blue - amount),
            alpha: alpha
        )
    }

    /// Returns the color with adjusted saturation.
    @inlinable
    public func saturated(by multiplier: Float) -> Color {
        Color(
            hue: hue,
            saturation: min(1, max(0, saturation * multiplier)),
            brightness: brightness,
            alpha: alpha
        )
    }

    /// Returns the inverted color (RGB components only).
    @inlinable
    public var inverted: Color {
        Color(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
    }

    /// Returns the grayscale version of this color.
    @inlinable
    public var grayscale: Color {
        Color(white: luminance, alpha: alpha)
    }
}

// MARK: - Blending

extension Color {
    /// Returns a color interpolated between two colors.
    @inlinable
    public static func lerp(from start: Color, to end: Color, t: Float) -> Color {
        Color(
            red: start.red + (end.red - start.red) * t,
            green: start.green + (end.green - start.green) * t,
            blue: start.blue + (end.blue - start.blue) * t,
            alpha: start.alpha + (end.alpha - start.alpha) * t
        )
    }

    /// Returns this color blended with another using alpha compositing.
    @inlinable
    public func blended(with foreground: Color) -> Color {
        let srcA = foreground.alpha
        let dstA = alpha * (1 - srcA)
        let outA = srcA + dstA

        guard outA > 0 else { return .clear }

        return Color(
            red: (foreground.red * srcA + red * dstA) / outA,
            green: (foreground.green * srcA + green * dstA) / outA,
            blue: (foreground.blue * srcA + blue * dstA) / outA,
            alpha: outA
        )
    }

    /// Multiplies two colors component-wise.
    @inlinable
    public func multiplied(by other: Color) -> Color {
        Color(
            red: red * other.red,
            green: green * other.green,
            blue: blue * other.blue,
            alpha: alpha * other.alpha
        )
    }
}

// MARK: - Premultiplied Alpha

extension Color {
    /// Returns the color with premultiplied alpha.
    @inlinable
    public var premultiplied: Color {
        Color(red: red * alpha, green: green * alpha, blue: blue * alpha, alpha: alpha)
    }

    /// Creates a color from premultiplied alpha components.
    @inlinable
    public static func fromPremultiplied(red: Float, green: Float, blue: Float, alpha: Float) -> Color {
        guard alpha > 0 else { return .clear }
        return Color(red: red / alpha, green: green / alpha, blue: blue / alpha, alpha: alpha)
    }
}

// MARK: - CustomStringConvertible

extension Color: CustomStringConvertible {
    public var description: String {
        if alpha == 1 {
            return String(format: "#%06X", rgb24)
        } else {
            return String(format: "#%08X", rgba32)
        }
    }
}

// MARK: - Codable

extension Color: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        red = try container.decode(Float.self)
        green = try container.decode(Float.self)
        blue = try container.decode(Float.self)
        alpha = try container.decodeIfPresent(Float.self) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(red)
        try container.encode(green)
        try container.encode(blue)
        if alpha != 1 {
            try container.encode(alpha)
        }
    }
}

// MARK: - CoreGraphics Interoperability

#if canImport(CoreGraphics)
import CoreGraphics

extension Color {
    /// Creates a `Color` from a `CGColor`.
    ///
    /// Converts the color to the sRGB color space if necessary.
    public init?(_ cgColor: CGColor) {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        if components.count == 4 {
            self.init(
                red: Float(components[0]),
                green: Float(components[1]),
                blue: Float(components[2]),
                alpha: Float(components[3])
            )
        } else {
            self.init(
                red: Float(components[0]),
                green: Float(components[1]),
                blue: Float(components[2]),
                alpha: 1
            )
        }
    }

    /// Returns this color as a `CGColor`.
    public var cgColor: CGColor {
        CGColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }
}
#endif

// MARK: - SwiftUI Interoperability

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Color {
    /// Returns this color as a SwiftUI `Color`.
    public var swiftUIColor: SwiftUI.Color {
        SwiftUI.Color(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            opacity: Double(alpha)
        )
    }
}
#endif
