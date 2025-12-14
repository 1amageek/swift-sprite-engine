/// A container for per-node shader attribute values.
///
/// `ShaderAttributeValue` holds the data for a single shader attribute
/// that varies per node. Each node can have its own attribute values
/// while sharing the same shader.
///
/// ## Usage
/// ```swift
/// // Create attribute values for a node
/// let colorValue = ShaderAttributeValue(vectorFloat4: (1.0, 0.0, 0.0, 1.0))
/// let intensityValue = ShaderAttributeValue(float: 0.8)
///
/// // Assign to a sprite
/// sprite.setValue(colorValue, forAttribute: "a_color")
/// sprite.setValue(intensityValue, forAttribute: "a_intensity")
/// ```
public final class ShaderAttributeValue {
    /// The type of data stored in this attribute value.
    public private(set) var type: AttributeType

    // MARK: - Value Storage

    private var floatStorage: [Float] = []

    // MARK: - Float Accessors

    /// The attribute value as a single float.
    public var floatValue: Float {
        get { floatStorage.first ?? 0 }
        set {
            type = .float
            floatStorage = [newValue]
        }
    }

    /// The attribute value as a 2-component float vector.
    public var vectorFloat2Value: (Float, Float) {
        get {
            guard floatStorage.count >= 2 else { return (0, 0) }
            return (floatStorage[0], floatStorage[1])
        }
        set {
            type = .vectorFloat2
            floatStorage = [newValue.0, newValue.1]
        }
    }

    /// The attribute value as a 3-component float vector.
    public var vectorFloat3Value: (Float, Float, Float) {
        get {
            guard floatStorage.count >= 3 else { return (0, 0, 0) }
            return (floatStorage[0], floatStorage[1], floatStorage[2])
        }
        set {
            type = .vectorFloat3
            floatStorage = [newValue.0, newValue.1, newValue.2]
        }
    }

    /// The attribute value as a 4-component float vector.
    public var vectorFloat4Value: (Float, Float, Float, Float) {
        get {
            guard floatStorage.count >= 4 else { return (0, 0, 0, 0) }
            return (floatStorage[0], floatStorage[1], floatStorage[2], floatStorage[3])
        }
        set {
            type = .vectorFloat4
            floatStorage = [newValue.0, newValue.1, newValue.2, newValue.3]
        }
    }

    // MARK: - Raw Data Access

    /// Returns the raw float data for GPU upload.
    public var floatData: [Float] {
        floatStorage
    }

    // MARK: - Initializers

    /// Creates an attribute value with a float.
    ///
    /// - Parameter float: The float value.
    public init(float: Float) {
        self.type = .float
        self.floatStorage = [float]
    }

    /// Creates an attribute value with a 2-component float vector.
    ///
    /// - Parameter vectorFloat2: The 2-component vector.
    public init(vectorFloat2: (Float, Float)) {
        self.type = .vectorFloat2
        self.floatStorage = [vectorFloat2.0, vectorFloat2.1]
    }

    /// Creates an attribute value with a 3-component float vector.
    ///
    /// - Parameter vectorFloat3: The 3-component vector.
    public init(vectorFloat3: (Float, Float, Float)) {
        self.type = .vectorFloat3
        self.floatStorage = [vectorFloat3.0, vectorFloat3.1, vectorFloat3.2]
    }

    /// Creates an attribute value with a 4-component float vector.
    ///
    /// - Parameter vectorFloat4: The 4-component vector.
    public init(vectorFloat4: (Float, Float, Float, Float)) {
        self.type = .vectorFloat4
        self.floatStorage = [vectorFloat4.0, vectorFloat4.1, vectorFloat4.2, vectorFloat4.3]
    }

    /// Creates an attribute value from a size.
    ///
    /// - Parameter size: The size to convert to a vectorFloat2.
    public init(size: Size) {
        self.type = .vectorFloat2
        self.floatStorage = [size.width, size.height]
    }

    /// Creates an attribute value from a point.
    ///
    /// - Parameter point: The point to convert to a vectorFloat2.
    public init(point: Point) {
        self.type = .vectorFloat2
        self.floatStorage = [point.x, point.y]
    }

    /// Creates an attribute value from a color.
    ///
    /// - Parameter color: The color to convert to a vectorFloat4.
    public init(color: Color) {
        self.type = .vectorFloat4
        self.floatStorage = [color.red, color.green, color.blue, color.alpha]
    }
}
