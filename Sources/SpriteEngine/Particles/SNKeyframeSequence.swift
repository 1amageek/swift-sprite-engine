#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

/// An object that performs interpolation between values specified at different times (keyframes).
///
/// The primary use for an `SNKeyframeSequence` object is to animate properties on particles
/// emitted by an `SNEmitterNode` object, but it can also be used for general interpolation
/// across a discrete set of inputs.
///
/// When a keyframe sequence is used with an emitter node, particles determine their values
/// by sampling the keyframe sequence. The sequence replaces the normal simulation performed
/// by the emitter node.
///
/// ## Usage
/// ```swift
/// // Create a scale sequence that starts small, grows, then shrinks
/// let scaleSequence = SNKeyframeSequence(
///     keyframeValues: [0.2, 0.7, 0.1],
///     times: [0.0, 0.25, 0.75]
/// )
/// emitter.particleScaleSequence = scaleSequence
///
/// // Create a color sequence for fire particles
/// let colorSequence = SNKeyframeSequence(
///     keyframeValues: [Color.white, Color.yellow, Color.orange, Color(white: 0.3, alpha: 1)],
///     times: [0.0, 0.2, 0.5, 1.0]
/// )
/// emitter.particleColorSequence = colorSequence
/// ```
public final class SNKeyframeSequence {

    // MARK: - Properties

    /// The keyframe values in the sequence.
    private var values: [Any]

    /// The times for each keyframe (normalized to 0.0-1.0 range).
    private var times: [Float]

    /// The mode used to determine how values for times between keyframes are calculated.
    public var interpolationMode: SNInterpolationMode = .linear

    /// The mode used to determine how the keyframe sequence repeats.
    public var repeatMode: SNRepeatMode = .clamp

    // MARK: - Initialization

    /// Initializes a keyframe sequence with an initial set of values and times.
    ///
    /// - Parameters:
    ///   - keyframeValues: An array of values for the keyframes.
    ///   - times: An array of times (0.0 to 1.0) for each keyframe.
    public init(keyframeValues: [Any], times: [Float]) {
        precondition(keyframeValues.count == times.count, "Values and times arrays must have the same count")
        precondition(!keyframeValues.isEmpty, "Keyframe sequence must have at least one value")

        // Sort by time and validate
        let sortedPairs = zip(keyframeValues, times).sorted { $0.1 < $1.1 }
        self.values = sortedPairs.map { $0.0 }
        self.times = sortedPairs.map { $0.1 }
    }

    /// Initializes a new keyframe sequence with a given capacity.
    ///
    /// - Parameter capacity: The initial capacity.
    public convenience init(capacity: Int) {
        self.init(keyframeValues: [Float(0)], times: [Float(0)])
        self.values.reserveCapacity(capacity)
        self.times.reserveCapacity(capacity)
    }

    // MARK: - Sequence Building

    /// Adds a keyframe to the sequence.
    ///
    /// - Parameters:
    ///   - value: The value for the keyframe.
    ///   - time: The time (0.0 to 1.0) for the keyframe.
    public func addKeyframeValue(_ value: Any, time: Float) {
        // Find insertion point to maintain sorted order
        var insertIndex = times.count
        for (index, t) in times.enumerated() {
            if time < t {
                insertIndex = index
                break
            }
        }
        values.insert(value, at: insertIndex)
        times.insert(time, at: insertIndex)
    }

    /// Removes a keyframe from the sequence.
    ///
    /// - Parameter index: The index of the keyframe to remove.
    public func removeKeyframe(at index: Int) {
        guard index >= 0 && index < values.count && values.count > 1 else { return }
        values.remove(at: index)
        times.remove(at: index)
    }

    /// Removes the last value in the sequence.
    public func removeLastKeyframe() {
        guard values.count > 1 else { return }
        values.removeLast()
        times.removeLast()
    }

    /// Changes the time for a specific keyframe.
    ///
    /// - Parameters:
    ///   - time: The new time.
    ///   - index: The index of the keyframe.
    public func setKeyframeTime(_ time: Float, for index: Int) {
        guard index >= 0 && index < times.count else { return }
        times[index] = time
    }

    /// Changes the value for a specific keyframe.
    ///
    /// - Parameters:
    ///   - value: The new value.
    ///   - index: The index of the keyframe.
    public func setKeyframeValue(_ value: Any, for index: Int) {
        guard index >= 0 && index < values.count else { return }
        values[index] = value
    }

    /// Replaces a keyframe in the sequence with a new keyframe.
    ///
    /// - Parameters:
    ///   - value: The new value.
    ///   - time: The new time.
    ///   - index: The index of the keyframe.
    public func setKeyframeValue(_ value: Any, time: Float, for index: Int) {
        guard index >= 0 && index < values.count else { return }
        values[index] = value
        times[index] = time
    }

    // MARK: - Sequence Information

    /// The number of keyframes in the sequence.
    public func count() -> Int {
        values.count
    }

    /// Gets the time for a keyframe in the sequence.
    ///
    /// - Parameter index: The index of the keyframe.
    /// - Returns: The time for the keyframe.
    public func getKeyframeTime(for index: Int) -> Float {
        guard index >= 0 && index < times.count else { return 0 }
        return times[index]
    }

    /// Gets the value for a keyframe in the sequence.
    ///
    /// - Parameter index: The index of the keyframe.
    /// - Returns: The value for the keyframe.
    public func getKeyframeValue(for index: Int) -> Any {
        guard index >= 0 && index < values.count else { return 0 }
        return values[index]
    }

    // MARK: - Sampling

    /// Calculates the sample at a particular time.
    ///
    /// - Parameter time: The time to sample (0.0 to 1.0 for particle lifetime).
    /// - Returns: The interpolated value at the specified time.
    public func sample(atTime time: Float) -> Any? {
        guard !values.isEmpty else { return nil }

        // Handle repeat mode
        let normalizedTime = normalizeTime(time)

        // Find the surrounding keyframes
        var lowerIndex = 0
        var upperIndex = 0

        for (index, t) in times.enumerated() {
            if normalizedTime <= t {
                upperIndex = index
                break
            }
            lowerIndex = index
            upperIndex = index
        }

        // If we're past the last keyframe
        if normalizedTime > times[upperIndex] {
            upperIndex = times.count - 1
            lowerIndex = upperIndex
        }

        // Same keyframe or step interpolation
        if lowerIndex == upperIndex || interpolationMode == .step {
            return values[lowerIndex]
        }

        // Calculate local progress between the two keyframes
        let lowerTime = times[lowerIndex]
        let upperTime = times[upperIndex]
        let localProgress: Float
        if upperTime > lowerTime {
            localProgress = (normalizedTime - lowerTime) / (upperTime - lowerTime)
        } else {
            localProgress = 0
        }

        // Interpolate based on value type
        return interpolate(from: values[lowerIndex], to: values[upperIndex], progress: localProgress)
    }

    /// Samples the sequence and returns a Float value.
    ///
    /// - Parameter time: The time to sample (0.0 to 1.0).
    /// - Returns: The interpolated Float value.
    public func sampleFloat(atTime time: Float) -> Float {
        guard let value = sample(atTime: time) else { return 0 }
        if let floatValue = value as? Float {
            return floatValue
        } else if let intValue = value as? Int {
            return Float(intValue)
        } else if let doubleValue = value as? Double {
            return Float(doubleValue)
        }
        return 0
    }

    /// Samples the sequence and returns a Color value.
    ///
    /// - Parameter time: The time to sample (0.0 to 1.0).
    /// - Returns: The interpolated Color value.
    public func sampleColor(atTime time: Float) -> Color {
        guard let value = sample(atTime: time) else { return .white }
        if let color = value as? Color {
            return color
        }
        return .white
    }

    // MARK: - Private Helpers

    private func normalizeTime(_ time: Float) -> Float {
        switch repeatMode {
        case .clamp:
            return max(0, min(1, time))
        case .loop:
            return time - floor(time)
        }
    }

    private func interpolate(from: Any, to: Any, progress: Float) -> Any {
        switch interpolationMode {
        case .step:
            return from
        case .linear:
            return linearInterpolate(from: from, to: to, progress: progress)
        case .spline:
            // For now, use linear interpolation for spline
            // A proper implementation would use Catmull-Rom or similar
            return linearInterpolate(from: from, to: to, progress: progress)
        }
    }

    private func linearInterpolate(from: Any, to: Any, progress: Float) -> Any {
        // Float interpolation
        if let fromFloat = from as? Float, let toFloat = to as? Float {
            return fromFloat + (toFloat - fromFloat) * progress
        }

        // Int interpolation (return Float)
        if let fromInt = from as? Int, let toInt = to as? Int {
            return Float(fromInt) + Float(toInt - fromInt) * progress
        }

        // Color interpolation
        if let fromColor = from as? Color, let toColor = to as? Color {
            return Color.lerp(from: fromColor, to: toColor, t: progress)
        }

        // Point interpolation
        if let fromPoint = from as? Point, let toPoint = to as? Point {
            return Point.lerp(from: fromPoint, to: toPoint, t: progress)
        }

        // Size interpolation
        if let fromSize = from as? Size, let toSize = to as? Size {
            return Size(
                width: fromSize.width + (toSize.width - fromSize.width) * progress,
                height: fromSize.height + (toSize.height - fromSize.height) * progress
            )
        }

        // Default: return 'from' value
        return from
    }
}

// MARK: - Interpolation Mode

/// The modes used to interpolate between keyframes in the sequence.
public enum SNInterpolationMode: Int, Sendable {
    /// Linear interpolation between keyframes.
    case linear = 1

    /// Step interpolation - no interpolation, values jump at keyframe times.
    case step = 2

    /// Spline interpolation for smooth curves through keyframes.
    case spline = 3
}

// MARK: - Repeat Mode

/// The modes used to determine how the keyframe sequence repeats.
public enum SNRepeatMode: Int, Sendable {
    /// Values are clamped to the range [0, 1].
    case clamp = 1

    /// The sequence loops when time exceeds 1.0.
    case loop = 2
}

// MARK: - Convenience Initializers

extension SNKeyframeSequence {
    /// Creates a keyframe sequence for Float values.
    ///
    /// - Parameters:
    ///   - floatValues: An array of Float values.
    ///   - times: An array of times (0.0 to 1.0) for each keyframe.
    public convenience init(floatValues: [Float], times: [Float]) {
        self.init(keyframeValues: floatValues, times: times)
    }

    /// Creates a keyframe sequence for Color values.
    ///
    /// - Parameters:
    ///   - colors: An array of Color values.
    ///   - times: An array of times (0.0 to 1.0) for each keyframe.
    public convenience init(colors: [Color], times: [Float]) {
        self.init(keyframeValues: colors, times: times)
    }
}
