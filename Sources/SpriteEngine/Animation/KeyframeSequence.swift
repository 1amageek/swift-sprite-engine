/// An object that performs interpolation between values specified at different times (keyframes).
///
/// `KeyframeSequence` is used to define complex animations by specifying values at
/// specific points in time. The sequence interpolates between these keyframes.
///
/// ## Usage
/// ```swift
/// // Create a keyframe sequence for color animation
/// let colorSequence = KeyframeSequence<Color>(
///     keyframes: [.red, .yellow, .green, .blue],
///     times: [0, 0.33, 0.66, 1.0]
/// )
///
/// // Sample at a specific time
/// let color = colorSequence.sample(at: 0.5)
/// ```
public struct KeyframeSequence<Value>: Sendable where Value: Sendable {
    // MARK: - Properties

    /// The keyframe values.
    private var values: [Value]

    /// The times for each keyframe (normalized 0-1).
    private var times: [CGFloat]

    /// The interpolation mode.
    public var interpolationMode: InterpolationMode = .linear

    /// The repeat mode.
    public var repeatMode: RepeatMode = .clamp

    // MARK: - Initialization

    /// Creates a keyframe sequence with the specified values and times.
    ///
    /// - Parameters:
    ///   - keyframes: The values at each keyframe.
    ///   - times: The times for each keyframe (should be sorted, typically 0-1).
    public init(keyframes: [Value], times: [CGFloat]) {
        precondition(keyframes.count == times.count, "Keyframes and times must have the same count")
        precondition(!keyframes.isEmpty, "Keyframe sequence must have at least one keyframe")
        self.values = keyframes
        self.times = times
    }

    /// Creates an empty keyframe sequence with the specified capacity.
    ///
    /// - Parameter capacity: The initial capacity.
    public init(capacity: Int = 4) {
        self.values = []
        self.times = []
        self.values.reserveCapacity(capacity)
        self.times.reserveCapacity(capacity)
    }

    // MARK: - Keyframe Management

    /// The number of keyframes in the sequence.
    public var count: Int {
        values.count
    }

    /// Adds a keyframe to the sequence.
    ///
    /// - Parameters:
    ///   - value: The keyframe value.
    ///   - time: The time for the keyframe.
    public mutating func addKeyframe(value: Value, time: CGFloat) {
        // Insert in sorted order
        let index = times.firstIndex { $0 > time } ?? times.count
        values.insert(value, at: index)
        times.insert(time, at: index)
    }

    /// Removes a keyframe at the specified index.
    ///
    /// - Parameter index: The index of the keyframe to remove.
    public mutating func removeKeyframe(at index: Int) {
        guard index >= 0 && index < count else { return }
        values.remove(at: index)
        times.remove(at: index)
    }

    /// Removes the last keyframe.
    public mutating func removeLastKeyframe() {
        guard !values.isEmpty else { return }
        values.removeLast()
        times.removeLast()
    }

    /// Gets the value for a keyframe at the specified index.
    ///
    /// - Parameter index: The keyframe index.
    /// - Returns: The value at that index.
    public func getKeyframeValue(at index: Int) -> Value? {
        guard index >= 0 && index < count else { return nil }
        return values[index]
    }

    /// Gets the time for a keyframe at the specified index.
    ///
    /// - Parameter index: The keyframe index.
    /// - Returns: The time at that index.
    public func getKeyframeTime(at index: Int) -> CGFloat? {
        guard index >= 0 && index < count else { return nil }
        return times[index]
    }

    /// Sets the value for a keyframe at the specified index.
    ///
    /// - Parameters:
    ///   - value: The new value.
    ///   - index: The keyframe index.
    public mutating func setKeyframeValue(_ value: Value, at index: Int) {
        guard index >= 0 && index < count else { return }
        values[index] = value
    }

    /// Sets the time for a keyframe at the specified index.
    ///
    /// - Parameters:
    ///   - time: The new time.
    ///   - index: The keyframe index.
    public mutating func setKeyframeTime(_ time: CGFloat, at index: Int) {
        guard index >= 0 && index < count else { return }
        times[index] = time
    }
}

// MARK: - Sampling (CGFloat)

extension KeyframeSequence where Value == CGFloat {
    /// Samples the sequence at the specified time.
    ///
    /// - Parameter time: The time to sample at.
    /// - Returns: The interpolated value.
    public func sample(at time: CGFloat) -> CGFloat {
        guard count > 0 else { return 0 }
        guard count > 1 else { return values[0] }

        let adjustedTime = adjustTime(time)

        // Find the keyframes to interpolate between
        let (index0, index1, t) = findKeyframes(at: adjustedTime)

        return interpolate(from: values[index0], to: values[index1], t: t)
    }

    private func interpolate(from: CGFloat, to: CGFloat, t: CGFloat) -> CGFloat {
        switch interpolationMode {
        case .linear:
            return from + (to - from) * t
        case .step:
            return t < 0.5 ? from : to
        case .spline:
            // Smooth step interpolation
            let smoothT = t * t * (3 - 2 * t)
            return from + (to - from) * smoothT
        }
    }
}

// MARK: - Sampling (Color)

extension KeyframeSequence where Value == Color {
    /// Samples the sequence at the specified time.
    ///
    /// - Parameter time: The time to sample at.
    /// - Returns: The interpolated color.
    public func sample(at time: CGFloat) -> Color {
        guard count > 0 else { return .white }
        guard count > 1 else { return values[0] }

        let adjustedTime = adjustTime(time)
        let (index0, index1, t) = findKeyframes(at: adjustedTime)

        return interpolateColor(from: values[index0], to: values[index1], t: t)
    }

    private func interpolateColor(from: Color, to: Color, t: CGFloat) -> Color {
        let effectiveT: CGFloat
        switch interpolationMode {
        case .linear:
            effectiveT = t
        case .step:
            effectiveT = t < 0.5 ? 0 : 1
        case .spline:
            effectiveT = t * t * (3 - 2 * t)
        }

        return Color.lerp(from: from, to: to, t: effectiveT)
    }
}

// MARK: - Sampling (Point)

extension KeyframeSequence where Value == Point {
    /// Samples the sequence at the specified time.
    ///
    /// - Parameter time: The time to sample at.
    /// - Returns: The interpolated point.
    public func sample(at time: CGFloat) -> Point {
        guard count > 0 else { return .zero }
        guard count > 1 else { return values[0] }

        let adjustedTime = adjustTime(time)
        let (index0, index1, t) = findKeyframes(at: adjustedTime)

        return interpolatePoint(from: values[index0], to: values[index1], t: t)
    }

    private func interpolatePoint(from: Point, to: Point, t: CGFloat) -> Point {
        let effectiveT: CGFloat
        switch interpolationMode {
        case .linear:
            effectiveT = t
        case .step:
            effectiveT = t < 0.5 ? 0 : 1
        case .spline:
            effectiveT = t * t * (3 - 2 * t)
        }

        return Point.lerp(from: from, to: to, t: effectiveT)
    }
}

// MARK: - Sampling (Size)

extension KeyframeSequence where Value == Size {
    /// Samples the sequence at the specified time.
    ///
    /// - Parameter time: The time to sample at.
    /// - Returns: The interpolated size.
    public func sample(at time: CGFloat) -> Size {
        guard count > 0 else { return .zero }
        guard count > 1 else { return values[0] }

        let adjustedTime = adjustTime(time)
        let (index0, index1, t) = findKeyframes(at: adjustedTime)

        return interpolateSize(from: values[index0], to: values[index1], t: t)
    }

    private func interpolateSize(from: Size, to: Size, t: CGFloat) -> Size {
        let effectiveT: CGFloat
        switch interpolationMode {
        case .linear:
            effectiveT = t
        case .step:
            effectiveT = t < 0.5 ? 0 : 1
        case .spline:
            effectiveT = t * t * (3 - 2 * t)
        }

        return Size.lerp(from: from, to: to, t: effectiveT)
    }
}

// MARK: - Private Helpers

extension KeyframeSequence {
    /// Adjusts time based on repeat mode.
    private func adjustTime(_ time: CGFloat) -> CGFloat {
        guard let firstTime = times.first, let lastTime = times.last else { return time }

        let duration = lastTime - firstTime
        guard duration > 0 else { return firstTime }

        switch repeatMode {
        case .clamp:
            return max(firstTime, min(lastTime, time))

        case .loop:
            var t = time
            if t < firstTime {
                let cycles = ((firstTime - t) / duration).rounded(.up)
                t += cycles * duration
            } else if t > lastTime {
                t = firstTime + (t - firstTime).truncatingRemainder(dividingBy: duration)
            }
            return t

        case .pingPong:
            var t = time
            if t < firstTime {
                let cycles = ((firstTime - t) / duration).rounded(.up)
                t += cycles * duration
            }
            let cyclePosition = ((t - firstTime) / duration).truncatingRemainder(dividingBy: 2)
            if cyclePosition >= 1 {
                t = lastTime - (t - firstTime - duration).truncatingRemainder(dividingBy: duration)
            } else {
                t = firstTime + (t - firstTime).truncatingRemainder(dividingBy: duration)
            }
            return max(firstTime, min(lastTime, t))
        }
    }

    /// Finds the keyframes surrounding a time value.
    ///
    /// - Parameter time: The time to find keyframes for.
    /// - Returns: A tuple of (lower index, upper index, interpolation factor).
    private func findKeyframes(at time: CGFloat) -> (Int, Int, CGFloat) {
        // Find the first keyframe with time > adjustedTime
        let upperIndex = times.firstIndex { $0 > time } ?? times.count

        // Handle edge cases
        if upperIndex == 0 {
            return (0, 0, 0)
        }
        if upperIndex >= times.count {
            return (times.count - 1, times.count - 1, 0)
        }

        let lowerIndex = upperIndex - 1
        let t0 = times[lowerIndex]
        let t1 = times[upperIndex]

        let t = (t1 - t0) > 0 ? (time - t0) / (t1 - t0) : 0

        return (lowerIndex, upperIndex, t)
    }
}
