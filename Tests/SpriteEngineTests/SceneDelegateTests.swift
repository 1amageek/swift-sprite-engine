import Testing
@testable import SpriteEngine

@Suite("SceneDelegate")
struct SceneDelegateTests {
    final class TestDelegate: SNSceneDelegate {
        var updateCalled = false
        var didEvaluateActionsCalled = false
        var didSimulatePhysicsCalled = false
        var didApplyConstraintsCalled = false
        var didFinishUpdateCalled = false
        var callOrder: [String] = []

        func update(_ dt: Float, for scene: SNScene) {
            updateCalled = true
            callOrder.append("update")
        }

        func didEvaluateActions(for scene: SNScene) {
            didEvaluateActionsCalled = true
            callOrder.append("didEvaluateActions")
        }

        func didSimulatePhysics(for scene: SNScene) {
            didSimulatePhysicsCalled = true
            callOrder.append("didSimulatePhysics")
        }

        func didApplyConstraints(for scene: SNScene) {
            didApplyConstraintsCalled = true
            callOrder.append("didApplyConstraints")
        }

        func didFinishUpdate(for scene: SNScene) {
            didFinishUpdateCalled = true
            callOrder.append("didFinishUpdate")
        }
    }

    @Test("Delegate receives all frame cycle callbacks")
    func delegateReceivesCallbacks() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let delegate = TestDelegate()
        scene.delegate = delegate

        scene.processFrame(dt: 1.0 / 60.0)

        #expect(delegate.updateCalled)
        #expect(delegate.didEvaluateActionsCalled)
        #expect(delegate.didSimulatePhysicsCalled)
        #expect(delegate.didApplyConstraintsCalled)
        #expect(delegate.didFinishUpdateCalled)
    }

    @Test("Frame cycle callbacks occur in correct order")
    func callbackOrder() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let delegate = TestDelegate()
        scene.delegate = delegate

        scene.processFrame(dt: 1.0 / 60.0)

        #expect(delegate.callOrder == [
            "update",
            "didEvaluateActions",
            "didSimulatePhysics",
            "didApplyConstraints",
            "didFinishUpdate"
        ])
    }

    @Test("Paused scene does not call delegate")
    func pausedSceneNoCallbacks() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let delegate = TestDelegate()
        scene.delegate = delegate
        scene.isPaused = true

        scene.processFrame(dt: 1.0 / 60.0)

        #expect(!delegate.updateCalled)
        #expect(delegate.callOrder.isEmpty)
    }

    @Test("Scene without delegate uses own methods")
    func sceneWithoutDelegate() {
        final class TestScene: SNScene {
            var updateCalled = false

            override func update(dt: Float) {
                updateCalled = true
                super.update(dt: dt)
            }
        }

        let scene = TestScene(size: Size(width: 800, height: 600))
        scene.processFrame(dt: 1.0 / 60.0)

        #expect(scene.updateCalled)
    }

    @Test("Constraints are applied during frame cycle")
    func constraintsAppliedInFrameCycle() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let node = SNNode()
        node.position = Point(x: 200, y: 0)
        node.constraints = [SNConstraint.positionX(Range(lowerLimit: 0, upperLimit: 100))]
        scene.addChild(node)

        scene.processFrame(dt: 1.0 / 60.0)

        #expect(node.position.x == 100)
    }
}
