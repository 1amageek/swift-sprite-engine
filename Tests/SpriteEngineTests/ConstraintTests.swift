import Testing
@testable import SpriteEngine

@Suite("Constraint")
struct ConstraintTests {
    @Test("Position X constraint clamps horizontal position")
    func positionXConstraint() {
        let node = SNNode()
        node.position = Point(x: 200, y: 50)

        let constraint = SNConstraint.positionX(Range(lowerLimit: 0, upperLimit: 100))
        constraint.apply(to: node)

        #expect(node.position.x == 100)
        #expect(node.position.y == 50) // Y unchanged
    }

    @Test("Position Y constraint clamps vertical position")
    func positionYConstraint() {
        let node = SNNode()
        node.position = Point(x: 50, y: -50)

        let constraint = SNConstraint.positionY(Range(lowerLimit: 0, upperLimit: 100))
        constraint.apply(to: node)

        #expect(node.position.x == 50) // X unchanged
        #expect(node.position.y == 0)
    }

    @Test("Position in rect constraint clamps to bounds")
    func positionInRectConstraint() {
        let node = SNNode()
        node.position = Point(x: 200, y: 200)

        let constraint = SNConstraint.position(in: Rect(x: 0, y: 0, width: 100, height: 100))
        constraint.apply(to: node)

        #expect(node.position.x == 100)
        #expect(node.position.y == 100)
    }

    @Test("Rotation constraint clamps angle")
    func rotationConstraint() {
        let node = SNNode()
        node.rotation = 2.0 // About 115 degrees

        let constraint = SNConstraint.rotation(Range(lowerLimit: 0, upperLimit: 1.0))
        constraint.apply(to: node)

        #expect(node.rotation == 1.0)
    }

    @Test("Distance constraint maintains min/max distance to target")
    func distanceConstraint() {
        let target = SNNode()
        target.position = Point(x: 100, y: 0)

        let node = SNNode()
        node.position = Point(x: 200, y: 0) // Distance = 100

        let constraint = SNConstraint.distance(Range(lowerLimit: 20, upperLimit: 50), to: target)
        constraint.apply(to: node)

        let distance = node.position.distance(to: target.position)
        #expect(distance <= 50.001) // Allow small floating point error
    }

    @Test("Orient to node constraint rotates toward target")
    func orientToNodeConstraint() {
        let target = SNNode()
        target.position = Point(x: 100, y: 100)

        let node = SNNode()
        node.position = Point(x: 0, y: 0)
        node.rotation = 0

        let constraint = SNConstraint.orient(to: target)
        constraint.apply(to: node)

        // Should point toward (100, 100) which is 45 degrees = π/4
        let expectedRotation = CGFloat.pi / 4
        #expect(abs(node.rotation - expectedRotation) < 0.001)
    }

    @Test("Orient to point constraint with offset")
    func orientToPointWithOffset() {
        let node = SNNode()
        node.position = Point(x: 0, y: 0)

        let constraint = SNConstraint.orient(to: Point(x: 100, y: 0), offset: CGFloat.pi / 2)
        constraint.apply(to: node)

        // Base rotation to (100, 0) is 0, plus offset of π/2
        #expect(abs(node.rotation - CGFloat.pi / 2) < 0.001)
    }

    @Test("Disabled constraint does not apply")
    func disabledConstraint() {
        let node = SNNode()
        node.position = Point(x: 200, y: 0)

        let constraint = SNConstraint.positionX(Range(lowerLimit: 0, upperLimit: 100))
        constraint.isEnabled = false
        constraint.apply(to: node)

        #expect(node.position.x == 200) // Unchanged
    }
}
