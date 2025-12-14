import Testing
@testable import SpriteEngine

@Suite("Range")
struct RangeTests {
    @Test("Clamps values to defined boundaries")
    func clampBehavior() {
        let range = Range(lowerLimit: -10, upperLimit: 10)

        #expect(range.clamp(-100) == -10)
        #expect(range.clamp(100) == 10)
        #expect(range.clamp(0) == 0)
    }

    @Test("Variance creates symmetric bounds around center")
    func varianceSymmetry() {
        let range = Range(value: 100, variance: 25)

        #expect(range.clamp(74) == 75)
        #expect(range.clamp(126) == 125)
        #expect(range.clamp(100) == 100)
    }
}
