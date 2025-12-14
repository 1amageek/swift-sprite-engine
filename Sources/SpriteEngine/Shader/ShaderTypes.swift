/// Options that specify a shader attribute's data type.
///
/// Used when defining custom attributes for shaders.
public enum AttributeType: Int, Hashable, Sendable {
    /// No data type specified.
    case none = 0

    /// A single 32-bit floating-point value.
    case float = 1

    /// A single 16-bit half-precision floating-point value.
    case halfFloat = 2

    /// A vector of two 32-bit floating-point values.
    case vectorFloat2 = 3

    /// A vector of three 32-bit floating-point values.
    case vectorFloat3 = 4

    /// A vector of four 32-bit floating-point values.
    case vectorFloat4 = 5

    /// A vector of two 16-bit half-precision floating-point values.
    case vectorHalfFloat2 = 6

    /// A vector of three 16-bit half-precision floating-point values.
    case vectorHalfFloat3 = 7

    /// A vector of four 16-bit half-precision floating-point values.
    case vectorHalfFloat4 = 8
}

/// An enumeration identifying the type of a shader uniform object.
///
/// Uniform types describe the data that can be passed to shaders.
public enum UniformType: Int, Hashable, Sendable {
    /// The uniform does not currently hold any data.
    ///
    /// A uniform has this type until its value is first set.
    case none = 0

    /// A 32-bit floating-point value.
    case float = 1

    /// A vector of two 32-bit floating-point values.
    case floatVector2 = 2

    /// A vector of three 32-bit floating-point values.
    case floatVector3 = 3

    /// A vector of four 32-bit floating-point values.
    case floatVector4 = 4

    /// A 2x2 matrix of 32-bit floating-point values.
    case floatMatrix2 = 5

    /// A 3x3 matrix of 32-bit floating-point values.
    case floatMatrix3 = 6

    /// A 4x4 matrix of 32-bit floating-point values.
    case floatMatrix4 = 7

    /// A reference to a texture.
    case texture = 8
}
