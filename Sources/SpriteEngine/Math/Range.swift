/// A definition of a range of floating-point values.
///
/// `Range` is used to clamp values so they stay within a specified range.
/// It's useful for constraints and limiting properties.
///
/// ## Usage
/// ```swift
/// // Create a range from -100 to 100
/// let range = Range(lowerLimit: -100, upperLimit: 100)
/// let clamped = range.clamp(150)  // Returns 100
///
/// // Create a range with variance
/// let range2 = Range(value: 50, variance: 10)  // 40 to 60
/// ```
public struct Range: Hashable, Sendable {
    // MARK: - Properties

    /// The minimum value of the range.
    public var lowerLimit: Float

    /// The maximum value of the range.
    public var upperLimit: Float

    // MARK: - Initialization

    /// Creates a range with the specified limits.
    ///
    /// - Parameters:
    ///   - lowerLimit: The minimum value.
    ///   - upperLimit: The maximum value.
    @inlinable
    public init(lowerLimit: Float, upperLimit: Float) {
        self.lowerLimit = lowerLimit
        self.upperLimit = upperLimit
    }

    /// Creates a range centered on a value with the specified variance.
    ///
    /// - Parameters:
    ///   - value: The center value.
    ///   - variance: The maximum distance from the center value.
    @inlinable
    public init(value: Float, variance: Float) {
        self.lowerLimit = value - variance
        self.upperLimit = value + variance
    }

    /// Creates a range that specifies only a minimum value.
    ///
    /// - Parameter lowerLimit: The minimum value.
    @inlinable
    public init(lowerLimit: Float) {
        self.lowerLimit = lowerLimit
        self.upperLimit = .infinity
    }

    /// Creates a range that specifies only a maximum value.
    ///
    /// - Parameter upperLimit: The maximum value.
    @inlinable
    public init(upperLimit: Float) {
        self.lowerLimit = -.infinity
        self.upperLimit = upperLimit
    }

    /// Creates a range that represents a constant value.
    ///
    /// - Parameter constantValue: The constant value.
    @inlinable
    public init(constantValue: Float) {
        self.lowerLimit = constantValue
        self.upperLimit = constantValue
    }

    // MARK: - Factory Methods

    /// A range with no limits (all values are valid).
    public static let noLimits = Range(lowerLimit: -.infinity, upperLimit: .infinity)

    /// Creates a range with no limits.
    @inlinable
    public static func withNoLimits() -> Range {
        .noLimits
    }

    // MARK: - Clamping

    /// Clamps a value to be within this range.
    ///
    /// - Parameter value: The value to clamp.
    /// - Returns: The clamped value.
    @inlinable
    public func clamp(_ value: Float) -> Float {
        max(lowerLimit, min(upperLimit, value))
    }

    /// Returns whether a value is within this range.
    ///
    /// - Parameter value: The value to check.
    /// - Returns: `true` if the value is within the range.
    @inlinable
    public func contains(_ value: Float) -> Bool {
        value >= lowerLimit && value <= upperLimit
    }

    // MARK: - Properties

    /// The span of the range (upper - lower).
    @inlinable
    public var span: Float {
        upperLimit - lowerLimit
    }

    /// The center value of the range.
    @inlinable
    public var center: Float {
        (lowerLimit + upperLimit) / 2
    }

    /// Whether this range represents a constant value.
    @inlinable
    public var isConstant: Bool {
        lowerLimit == upperLimit
    }

    /// Whether this range has no limits.
    @inlinable
    public var hasNoLimits: Bool {
        lowerLimit == -.infinity && upperLimit == .infinity
    }
}

// MARK: - CustomStringConvertible

extension Range: CustomStringConvertible {
    public var description: String {
        "[\(lowerLimit), \(upperLimit)]"
    }
}

// MARK: - Codable

extension Range: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lowerLimit = try container.decode(Float.self)
        upperLimit = try container.decode(Float.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lowerLimit)
        try container.encode(upperLimit)
    }
}
