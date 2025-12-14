import Testing
@testable import SpriteEngine

@Suite("ReferenceNode")
struct ReferenceNodeTests {
    @Test("Factory creates child node on resolve")
    func factoryCreatesChild() {
        var factoryCalled = false
        let reference = SNReferenceNode {
            factoryCalled = true
            let sprite = SNSpriteNode(color: .red, size: Size(width: 32, height: 32))
            sprite.name = "generated"
            return sprite
        }

        reference.resolve()

        #expect(factoryCalled)
        #expect(reference.children.count == 1)
        #expect(reference.children.first?.name == "generated")
    }

    @Test("Auto-resolves when added to scene")
    func autoResolvesOnAddToScene() {
        var factoryCalled = false
        let reference = SNReferenceNode {
            factoryCalled = true
            return SNNode()
        }

        let scene = SNScene(size: Size(width: 800, height: 600))
        scene.addChild(reference)

        #expect(factoryCalled)
        #expect(reference.isResolved)
    }

    @Test("Resolve clears previous content")
    func resolveClearsPrevious() {
        var callCount = 0
        let reference = SNReferenceNode {
            callCount += 1
            let node = SNNode()
            node.name = "version\(callCount)"
            return node
        }

        reference.resolve()
        #expect(reference.children.first?.name == "version1")

        reference.resolve()
        #expect(reference.children.count == 1)
        #expect(reference.children.first?.name == "version2")
    }

    @Test("didLoad callback receives loaded node")
    func didLoadCallback() {
        final class TestReference: SNReferenceNode {
            var loadedNode: SNNode?

            override func didLoad(_ node: SNNode?) {
                loadedNode = node
            }
        }

        let reference = TestReference {
            let node = SNNode()
            node.name = "loaded"
            return node
        }

        reference.resolve()

        #expect(reference.loadedNode?.name == "loaded")
    }

    @Test("Nil factory result handled gracefully")
    func nilFactoryResult() {
        let reference = SNReferenceNode {
            return nil
        }

        reference.resolve()

        #expect(reference.isResolved)
        #expect(reference.children.isEmpty)
    }

    @Test("Multiple references share same factory logic")
    func sharedFactoryLogic() {
        func createEnemy() -> SNNode {
            let sprite = SNSpriteNode(color: .red, size: Size(width: 32, height: 32))
            sprite.name = "enemy"
            return sprite
        }

        let ref1 = SNReferenceNode(factory: createEnemy)
        let ref2 = SNReferenceNode(factory: createEnemy)

        ref1.resolve()
        ref2.resolve()

        #expect(ref1.children.first?.name == "enemy")
        #expect(ref2.children.first?.name == "enemy")
        #expect(ref1.children.first !== ref2.children.first)
    }
}
