import Testing
@testable import SpriteEngine

@Suite("Camera")
struct CameraTests {
    @Test("Viewport centered on camera position")
    func viewportCenteredOnPosition() {
        let camera = SNCamera()
        camera.position = Point(x: 100, y: 200)

        let viewport = camera.viewport(for: Size(width: 800, height: 600))

        #expect(viewport.midX == 100)
        #expect(viewport.midY == 200)
        #expect(viewport.width == 800)
        #expect(viewport.height == 600)
    }

    @Test("Zoom affects viewport size")
    func zoomAffectsViewport() {
        let camera = SNCamera()
        camera.position = Point(x: 0, y: 0)
        camera.zoom = 2.0 // Zoom in = smaller viewport

        let viewport = camera.viewport(for: Size(width: 800, height: 600))

        #expect(viewport.width == 400)
        #expect(viewport.height == 300)
    }

    @Test("Contains detects visible sprites")
    func containsDetectsVisibleSprites() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let camera = SNCamera()
        scene.addChild(camera)
        scene.camera = camera

        let visibleSprite = SNSpriteNode(color: .red, size: Size(width: 50, height: 50))
        visibleSprite.position = Point(x: 100, y: 100)
        scene.addChild(visibleSprite)

        let offscreenSprite = SNSpriteNode(color: .blue, size: Size(width: 50, height: 50))
        offscreenSprite.position = Point(x: 1000, y: 1000)
        scene.addChild(offscreenSprite)

        #expect(camera.contains(visibleSprite, sceneSize: scene.size))
        #expect(!camera.contains(offscreenSprite, sceneSize: scene.size))
    }

    @Test("ContainedNodeSet returns all visible nodes")
    func containedNodeSetReturnsVisible() {
        let scene = SNScene(size: Size(width: 800, height: 600))
        let camera = SNCamera()
        scene.addChild(camera)
        scene.camera = camera

        let sprite1 = SNSpriteNode(color: .red, size: Size(width: 50, height: 50))
        sprite1.position = Point(x: 100, y: 100)
        scene.addChild(sprite1)

        let sprite2 = SNSpriteNode(color: .green, size: Size(width: 50, height: 50))
        sprite2.position = Point(x: 200, y: 200)
        scene.addChild(sprite2)

        let offscreen = SNSpriteNode(color: .blue, size: Size(width: 50, height: 50))
        offscreen.position = Point(x: 2000, y: 2000)
        scene.addChild(offscreen)

        let visible = camera.containedNodeSet()

        #expect(visible.contains(sprite1))
        #expect(visible.contains(sprite2))
        #expect(!visible.contains(offscreen))
    }

    @Test("Smooth follow interpolates toward target")
    func smoothFollowInterpolates() {
        let camera = SNCamera()
        camera.position = Point(x: 0, y: 0)

        let target = Point(x: 100, y: 100)
        camera.smoothFollow(target: target, smoothing: 5.0, dt: 0.1)

        // Should move toward target but not reach it immediately
        #expect(camera.position.x > 0)
        #expect(camera.position.x < 100)
        #expect(camera.position.y > 0)
        #expect(camera.position.y < 100)
    }

    @Test("Clamp to bounds restricts camera movement")
    func clampToBoundsRestricts() {
        let camera = SNCamera()
        camera.position = Point(x: 0, y: 0)

        let bounds = Rect(x: 100, y: 100, width: 1000, height: 1000)
        let sceneSize = Size(width: 800, height: 600)

        camera.clampToBounds(bounds, sceneSize: sceneSize)

        // Camera should be pushed inside bounds accounting for viewport
        #expect(camera.position.x >= bounds.minX + sceneSize.width / 2)
        #expect(camera.position.y >= bounds.minY + sceneSize.height / 2)
    }

    @Test("Camera following moves viewport with target")
    func cameraFollowingMovesViewport() {
        let camera = SNCamera()
        camera.position = Point(x: 0, y: 0)

        let sceneSize = Size(width: 800, height: 600)
        let initialViewport = camera.viewport(for: sceneSize)

        camera.position = Point(x: 500, y: 300)
        let movedViewport = camera.viewport(for: sceneSize)

        #expect(movedViewport.minX == initialViewport.minX + 500)
        #expect(movedViewport.minY == initialViewport.minY + 300)
    }
}
