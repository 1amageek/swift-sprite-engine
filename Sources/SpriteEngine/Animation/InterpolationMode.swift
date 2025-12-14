/// The modes used to interpolate between keyframes in a sequence.
///
/// Interpolation modes determine how values transition between
/// keyframe values over time.
public enum InterpolationMode: Int, Hashable, Sendable {
    /// Values between two keyframes are interpolated linearly.
    ///
    /// The transition is constant and even between keyframes.
    case linear = 0

    /// Values between two keyframes are interpolated using a spline curve.
    ///
    /// This creates smoother, more natural-looking transitions.
    case spline = 1

    /// Values between two keyframes are not interpolated.
    ///
    /// Instead, the value immediately jumps to the next keyframe's value.
    /// This is useful for discrete state changes.
    case step = 2
}

/// The modes used to determine how a sequence repeats.
public enum RepeatMode: Int, Hashable, Sendable {
    /// When a sample is calculated, the time value is clamped to the
    /// range of time values found in the sequence.
    ///
    /// For example, if the last keyframe's time value is 0.5, a sample
    /// at any time value from 0.5 to 1.0 returns the last keyframe's value.
    case clamp = 0

    /// When a sample is calculated, the sequence loops back to the
    /// beginning of the sequence.
    ///
    /// For example, if the last keyframe's time value is 0.5, then a
    /// sample at any time value from 0.5 to 1.0 returns the same value
    /// as the sequence did from 0.0 to 0.5.
    case loop = 1

    /// When a sample is calculated, the sequence reverses direction
    /// when the end is reached.
    ///
    /// For example, if the last keyframe's time is 0.5, then a sample
    /// at time 0.6 returns the same value as at time 0.4 (ping-pong).
    case pingPong = 2
}
