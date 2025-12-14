import Testing
@testable import SpriteEngine

@Suite("KeyframeSequence")
struct KeyframeSequenceTests {
    @Test("Linear interpolation between keyframes")
    func linearInterpolation() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.interpolationMode = .linear

        #expect(sequence.sample(at: 0) == 0)
        #expect(sequence.sample(at: 0.5) == 50)
        #expect(sequence.sample(at: 1) == 100)
    }

    @Test("Step interpolation snaps to nearest keyframe")
    func stepInterpolation() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.interpolationMode = .step

        #expect(sequence.sample(at: 0.25) == 0)
        #expect(sequence.sample(at: 0.75) == 100)
    }

    @Test("Spline interpolation provides smooth curve")
    func splineInterpolation() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.interpolationMode = .spline

        let midpoint = sequence.sample(at: 0.5)
        // Spline at t=0.5 should be 50 (smooth step formula: t²(3-2t) = 0.5)
        #expect(midpoint == 50)

        // At t=0.25, spline should ease in (slower than linear)
        let quarter = sequence.sample(at: 0.25)
        #expect(quarter < 25) // Easing in = slower than linear
    }

    @Test("Loop repeat mode wraps time")
    func loopRepeatMode() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.repeatMode = .loop

        #expect(sequence.sample(at: 1.5) == 50)
        #expect(sequence.sample(at: 2.0) == 0)
    }

    @Test("PingPong repeat mode reverses direction")
    func pingPongRepeatMode() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.repeatMode = .pingPong

        // Forward pass
        #expect(sequence.sample(at: 0.5) == 50)
        // Reverse pass
        #expect(sequence.sample(at: 1.5) == 50)
    }

    @Test("Clamp repeat mode holds at boundaries")
    func clampRepeatMode() {
        var sequence = KeyframeSequence<Float>(keyframes: [0, 100], times: [0, 1])
        sequence.repeatMode = .clamp

        #expect(sequence.sample(at: -1) == 0)
        #expect(sequence.sample(at: 2) == 100)
    }

    @Test("Color interpolation blends RGBA components")
    func colorInterpolation() {
        let sequence = KeyframeSequence<Color>(
            keyframes: [Color(red: 1, green: 0, blue: 0, alpha: 1),
                       Color(red: 0, green: 0, blue: 1, alpha: 1)],
            times: [0, 1]
        )

        let midColor = sequence.sample(at: 0.5)
        #expect(midColor.red == 0.5)
        #expect(midColor.green == 0)
        #expect(midColor.blue == 0.5)
    }

    @Test("Point interpolation moves along path")
    func pointInterpolation() {
        let sequence = KeyframeSequence<Point>(
            keyframes: [Point(x: 0, y: 0), Point(x: 100, y: 100)],
            times: [0, 1]
        )

        let midPoint = sequence.sample(at: 0.5)
        #expect(midPoint.x == 50)
        #expect(midPoint.y == 50)
    }

    @Test("Multiple keyframes interpolate correctly")
    func multipleKeyframes() {
        let sequence = KeyframeSequence<Float>(
            keyframes: [0, 100, 50, 200],
            times: [0, 0.25, 0.5, 1.0]
        )

        #expect(sequence.sample(at: 0.125) == 50)   // Between 0 and 100
        #expect(sequence.sample(at: 0.375) == 75)   // Between 100 and 50
        #expect(sequence.sample(at: 0.75) == 125)   // Between 50 and 200
    }
}
