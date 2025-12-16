/// A container for uniform data passed to shaders.
///
/// `SNUniform` holds named data that can be passed to shader programs.
/// The data is shared across all instances using the shader.
///
/// ## Usage
/// ```swift
/// // Create a time uniform
/// let timeUniform = SNUniform(name: "u_time", float: 0.0)
///
/// // Create a color uniform
/// let colorUniform = SNUniform(name: "u_tint", floatVector4: (1.0, 0.5, 0.0, 1.0))
///
/// // Update the uniform value
/// timeUniform.floatValue = elapsedTime
/// ```
public final class SNUniform {
    /// The name of the uniform as it appears in the shader.
    public let name: String

    /// The type of data stored in this uniform.
    public private(set) var uniformType: UniformType

    // MARK: - Value Storage

    private var floatStorage: [Float] = []

    // MARK: - Float Accessors

    /// The uniform's value as a single float.
    public var floatValue: Float {
        get { floatStorage.first ?? 0 }
        set {
            uniformType = .float
            floatStorage = [newValue]
        }
    }

    /// The uniform's value as a 2-component float vector.
    public var floatVector2Value: (Float, Float) {
        get {
            guard floatStorage.count >= 2 else { return (0, 0) }
            return (floatStorage[0], floatStorage[1])
        }
        set {
            uniformType = .floatVector2
            floatStorage = [newValue.0, newValue.1]
        }
    }

    /// The uniform's value as a 3-component float vector.
    public var floatVector3Value: (Float, Float, Float) {
        get {
            guard floatStorage.count >= 3 else { return (0, 0, 0) }
            return (floatStorage[0], floatStorage[1], floatStorage[2])
        }
        set {
            uniformType = .floatVector3
            floatStorage = [newValue.0, newValue.1, newValue.2]
        }
    }

    /// The uniform's value as a 4-component float vector.
    public var floatVector4Value: (Float, Float, Float, Float) {
        get {
            guard floatStorage.count >= 4 else { return (0, 0, 0, 0) }
            return (floatStorage[0], floatStorage[1], floatStorage[2], floatStorage[3])
        }
        set {
            uniformType = .floatVector4
            floatStorage = [newValue.0, newValue.1, newValue.2, newValue.3]
        }
    }

    /// The uniform's value as a 2x2 matrix (column-major order).
    public var floatMatrix2Value: [Float] {
        get { Array(floatStorage.prefix(4)) }
        set {
            uniformType = .floatMatrix2
            floatStorage = Array(newValue.prefix(4))
            while floatStorage.count < 4 {
                floatStorage.append(0)
            }
        }
    }

    /// The uniform's value as a 3x3 matrix (column-major order).
    public var floatMatrix3Value: [Float] {
        get { Array(floatStorage.prefix(9)) }
        set {
            uniformType = .floatMatrix3
            floatStorage = Array(newValue.prefix(9))
            while floatStorage.count < 9 {
                floatStorage.append(0)
            }
        }
    }

    /// The uniform's value as a 4x4 matrix (column-major order).
    public var floatMatrix4Value: [Float] {
        get { Array(floatStorage.prefix(16)) }
        set {
            uniformType = .floatMatrix4
            floatStorage = Array(newValue.prefix(16))
            while floatStorage.count < 16 {
                floatStorage.append(0)
            }
        }
    }

    // MARK: - Raw Data Access

    /// Returns the raw float data for GPU upload.
    public var floatData: [Float] {
        floatStorage
    }

    // MARK: - Initializers

    /// Creates a uniform with a float value.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - float: The initial float value.
    public init(name: String, float: Float) {
        self.name = name
        self.uniformType = .float
        self.floatStorage = [float]
    }

    /// Creates a uniform with a 2-component float vector.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatVector2: The initial 2-component vector.
    public init(name: String, floatVector2: (Float, Float)) {
        self.name = name
        self.uniformType = .floatVector2
        self.floatStorage = [floatVector2.0, floatVector2.1]
    }

    /// Creates a uniform with a 3-component float vector.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatVector3: The initial 3-component vector.
    public init(name: String, floatVector3: (Float, Float, Float)) {
        self.name = name
        self.uniformType = .floatVector3
        self.floatStorage = [floatVector3.0, floatVector3.1, floatVector3.2]
    }

    /// Creates a uniform with a 4-component float vector.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatVector4: The initial 4-component vector.
    public init(name: String, floatVector4: (Float, Float, Float, Float)) {
        self.name = name
        self.uniformType = .floatVector4
        self.floatStorage = [floatVector4.0, floatVector4.1, floatVector4.2, floatVector4.3]
    }

    /// Creates a uniform with a 2x2 matrix.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatMatrix2: The initial 2x2 matrix in column-major order.
    public init(name: String, floatMatrix2: [Float]) {
        self.name = name
        self.uniformType = .floatMatrix2
        self.floatStorage = Array(floatMatrix2.prefix(4))
        while self.floatStorage.count < 4 {
            self.floatStorage.append(0)
        }
    }

    /// Creates a uniform with a 3x3 matrix.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatMatrix3: The initial 3x3 matrix in column-major order.
    public init(name: String, floatMatrix3: [Float]) {
        self.name = name
        self.uniformType = .floatMatrix3
        self.floatStorage = Array(floatMatrix3.prefix(9))
        while self.floatStorage.count < 9 {
            self.floatStorage.append(0)
        }
    }

    /// Creates a uniform with a 4x4 matrix.
    ///
    /// - Parameters:
    ///   - name: The uniform name in the shader.
    ///   - floatMatrix4: The initial 4x4 matrix in column-major order.
    public init(name: String, floatMatrix4: [Float]) {
        self.name = name
        self.uniformType = .floatMatrix4
        self.floatStorage = Array(floatMatrix4.prefix(16))
        while self.floatStorage.count < 16 {
            self.floatStorage.append(0)
        }
    }
}
