import Testing
@testable import SpriteEngine

@Suite("Region")
struct RegionTests {
    @Test("Rectangular region containment")
    func rectContainment() {
        let region = Region(size: Size(width: 100, height: 100))

        #expect(region.contains(Point(x: 0, y: 0)))
        #expect(region.contains(Point(x: 49, y: 49)))
        #expect(!region.contains(Point(x: 51, y: 0)))
        #expect(!region.contains(Point(x: 0, y: 51)))
    }

    @Test("Circular region containment")
    func circleContainment() {
        let region = Region(radius: 50)

        #expect(region.contains(Point(x: 0, y: 0)))
        #expect(region.contains(Point(x: 35, y: 35))) // ~49.5 from center
        #expect(!region.contains(Point(x: 40, y: 40))) // ~56.6 from center
    }

    @Test("Union combines two regions")
    func unionOperation() {
        let left = Region(size: Size(width: 100, height: 100))
        let right = Region(size: Size(width: 100, height: 100))

        // Shift conceptually: left is at origin, test union behavior
        let union = left.union(with: right)

        // Points in either region should be contained
        #expect(union.contains(Point(x: 0, y: 0)))
        #expect(union.contains(Point(x: 25, y: 25)))
    }

    @Test("Intersection finds overlap")
    func intersectionOperation() {
        let regionA = Region(size: Size(width: 100, height: 100))
        let regionB = Region(size: Size(width: 100, height: 100))

        let intersection = regionA.intersection(with: regionB)

        // Only points in both regions
        #expect(intersection.contains(Point(x: 0, y: 0)))
        #expect(intersection.contains(Point(x: 25, y: 25)))
    }

    @Test("Difference subtracts region")
    func differenceOperation() {
        let large = Region(size: Size(width: 200, height: 200))
        let small = Region(size: Size(width: 50, height: 50))

        let difference = large.difference(from: small)

        // Point outside small but inside large
        #expect(difference.contains(Point(x: 50, y: 50)))
        // Point inside small (should be removed)
        #expect(!difference.contains(Point(x: 0, y: 0)))
    }

    @Test("Inverse flips containment")
    func inverseOperation() {
        let region = Region(radius: 50)
        let inverse = region.inverse()

        // Inside original = outside inverse
        #expect(!inverse.contains(Point(x: 0, y: 0)))
        // Outside original = inside inverse
        #expect(inverse.contains(Point(x: 100, y: 100)))
    }

    @Test("Infinite region contains all points")
    func infiniteRegion() {
        let region = Region.infinite()

        #expect(region.contains(Point(x: 0, y: 0)))
        #expect(region.contains(Point(x: 10000, y: -10000)))
        #expect(region.contains(Point(x: CGFloat.greatestFiniteMagnitude, y: 0)))
    }
}
