#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WASILibc)
import WASILibc
#endif

/// A reusable object that animates a node's properties over time.
///
/// Actions provide a way to animate nodes without manual per-frame updates.
/// They can move, rotate, scale, fade, and perform other transformations.
///
/// ## Usage
/// ```swift
/// // Move a sprite
/// let moveAction = SNAction.move(to: Point(x: 200, y: 100), duration: 1.0)
/// sprite.run(moveAction)
///
/// // Chain actions in sequence
/// let sequence = SNAction.sequence([
///     SNAction.move(to: Point(x: 200, y: 100), duration: 0.5),
///     SNAction.fadeOut(duration: 0.3),
///     SNAction.removeFromParent()
/// ])
/// sprite.run(sequence)
/// ```
public class Action {
    // MARK: - Properties

    /// The duration of this action in seconds.
    public let duration: Float

    /// The timing function for this action.
    public var timingMode: ActionTimingMode = .linear

    /// A custom timing function that overrides `timingMode`.
    ///
    /// The function receives a value from 0 to 1 (input time) and should return
    /// a value from 0 to 1 (output progress). When 0.0 is input, return 0.0.
    /// When 1.0 is input, return 1.0.
    ///
    /// ## Usage
    /// ```swift
    /// let action = SNAction.move(to: destination, duration: 1.0)
    /// action.timingFunction = { t in
    ///     // Custom bounce effect
    ///     return t * t * (3 - 2 * t)
    /// }
    /// ```
    public var timingFunction: ((Float) -> Float)?

    /// A speed factor that modifies how fast the action runs.
    /// Default is 1.0 (normal speed). Values > 1.0 speed up, values < 1.0 slow down.
    public var speed: Float = 1.0

    /// Current elapsed time.
    internal var elapsed: Float = 0

    /// Whether this action has completed.
    internal var isComplete: Bool = false

    // MARK: - Initialization

    /// Creates an action with the specified duration.
    public init(duration: Float) {
        self.duration = duration
    }

    // MARK: - Evaluation

    /// Evaluates the action for one frame.
    ///
    /// - Parameters:
    ///   - node: The node this action is running on.
    ///   - dt: The delta time for this frame.
    /// - Returns: `true` if the action has completed, `false` otherwise.
    internal func evaluate(on node: SNNode, dt: Float) -> Bool {
        // Apply speed factor
        elapsed += dt * speed

        if duration > 0 {
            let progress = min(elapsed / duration, 1.0)
            // Use custom timing function if provided, otherwise use timing mode
            let easedProgress: Float
            if let customTiming = timingFunction {
                easedProgress = customTiming(progress)
            } else {
                easedProgress = timingMode.apply(progress)
            }
            apply(to: node, progress: easedProgress)

            if elapsed >= duration {
                isComplete = true
                return true
            }
        } else {
            // Instant action
            apply(to: node, progress: 1.0)
            isComplete = true
            return true
        }

        return false
    }

    /// Applies the action at the given progress.
    ///
    /// Override in subclasses to implement specific behavior.
    ///
    /// - Parameters:
    ///   - node: The node to apply the action to.
    ///   - progress: The progress from 0 to 1.
    internal func apply(to node: SNNode, progress: Float) {
        // Override in subclasses
    }

    /// Creates a copy of this action for reuse.
    public func copy() -> Action {
        let action = Action(duration: duration)
        action.timingMode = timingMode
        action.timingFunction = timingFunction
        action.speed = speed
        return action
    }

    /// Resets the action to its initial state.
    internal func reset() {
        elapsed = 0
        isComplete = false
    }
}

/// Type alias for SpriteKit compatibility
public typealias SNAction = Action

// MARK: - Timing Modes

/// The timing function for an action's animation.
public enum ActionTimingMode: Sendable {
    /// Linear interpolation.
    case linear
    /// Ease in (slow start).
    case easeIn
    /// Ease out (slow end).
    case easeOut
    /// Ease in and out (slow start and end).
    case easeInOut

    /// Applies the timing function to a progress value.
    internal func apply(_ t: Float) -> Float {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return t * (2 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        }
    }
}

// MARK: - Move Actions

/// Action that moves a node to a position.
public final class MoveToAction: Action {
    private let targetPosition: Point
    private var startPosition: Point?

    public init(to position: Point, duration: Float) {
        self.targetPosition = position
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startPosition == nil {
            startPosition = node.position
        }
        guard let start = startPosition else { return }

        node.position = Point(
            x: start.x + (targetPosition.x - start.x) * progress,
            y: start.y + (targetPosition.y - start.y) * progress
        )
    }

    public override func copy() -> Action {
        let action = MoveToAction(to: targetPosition, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startPosition = nil
    }
}

/// Action that moves a node by a delta.
public final class MoveByAction: Action {
    private let delta: Vector2
    private var startPosition: Point?

    public init(by delta: Vector2, duration: Float) {
        self.delta = delta
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startPosition == nil {
            startPosition = node.position
        }
        guard let start = startPosition else { return }

        node.position = Point(
            x: start.x + delta.dx * progress,
            y: start.y + delta.dy * progress
        )
    }

    public override func copy() -> Action {
        let action = MoveByAction(by: delta, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startPosition = nil
    }
}

// MARK: - Rotate Actions

/// Action that rotates a node to an angle.
public final class RotateToAction: Action {
    private let targetRotation: Float
    private var startRotation: Float?

    public init(to rotation: Float, duration: Float) {
        self.targetRotation = rotation
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startRotation == nil {
            startRotation = node.rotation
        }
        guard let start = startRotation else { return }

        node.rotation = start + (targetRotation - start) * progress
    }

    public override func copy() -> Action {
        let action = RotateToAction(to: targetRotation, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startRotation = nil
    }
}

/// Action that rotates a node by a delta.
public final class RotateByAction: Action {
    private let delta: Float
    private var startRotation: Float?

    public init(by delta: Float, duration: Float) {
        self.delta = delta
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startRotation == nil {
            startRotation = node.rotation
        }
        guard let start = startRotation else { return }

        node.rotation = start + delta * progress
    }

    public override func copy() -> Action {
        let action = RotateByAction(by: delta, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startRotation = nil
    }
}

// MARK: - Scale Actions

/// Action that scales a node to a size.
public final class ScaleToAction: Action {
    private let targetScale: Size
    private var startScale: Size?

    public init(to scale: Size, duration: Float) {
        self.targetScale = scale
        super.init(duration: duration)
    }

    public init(to scale: Float, duration: Float) {
        self.targetScale = Size(width: scale, height: scale)
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScale == nil {
            startScale = node.scale
        }
        guard let start = startScale else { return }

        node.scale = Size(
            width: start.width + (targetScale.width - start.width) * progress,
            height: start.height + (targetScale.height - start.height) * progress
        )
    }

    public override func copy() -> Action {
        let action = ScaleToAction(to: targetScale, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScale = nil
    }
}

/// Action that scales a node by a factor.
public final class ScaleByAction: Action {
    private let factor: Size
    private var startScale: Size?

    public init(by factor: Size, duration: Float) {
        self.factor = factor
        super.init(duration: duration)
    }

    public init(by factor: Float, duration: Float) {
        self.factor = Size(width: factor, height: factor)
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScale == nil {
            startScale = node.scale
        }
        guard let start = startScale else { return }

        node.scale = Size(
            width: start.width * (1 + (factor.width - 1) * progress),
            height: start.height * (1 + (factor.height - 1) * progress)
        )
    }

    public override func copy() -> Action {
        let action = ScaleByAction(by: factor, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScale = nil
    }
}

// MARK: - Fade Actions

/// Action that fades a node to an alpha value.
public final class FadeToAction: Action {
    private let targetAlpha: Float
    private var startAlpha: Float?

    public init(to alpha: Float, duration: Float) {
        self.targetAlpha = alpha
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startAlpha == nil {
            startAlpha = node.alpha
        }
        guard let start = startAlpha else { return }

        node.alpha = start + (targetAlpha - start) * progress
    }

    public override func copy() -> Action {
        let action = FadeToAction(to: targetAlpha, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startAlpha = nil
    }
}

// MARK: - Sequence Action

/// Action that runs a series of actions one after another.
public final class SequenceAction: Action {
    private let actions: [Action]
    private var currentIndex: Int = 0

    public init(_ actions: [Action]) {
        self.actions = actions.map { $0.copy() }
        let totalDuration = actions.reduce(0) { $0 + $1.duration }
        super.init(duration: totalDuration)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        guard currentIndex < actions.count else {
            isComplete = true
            return true
        }

        let currentAction = actions[currentIndex]
        if currentAction.evaluate(on: node, dt: dt) {
            currentIndex += 1
            if currentIndex >= actions.count {
                isComplete = true
                return true
            }
        }

        return false
    }

    public override func copy() -> Action {
        SequenceAction(actions)
    }

    internal override func reset() {
        super.reset()
        currentIndex = 0
        for action in actions {
            action.reset()
        }
    }
}

// MARK: - Group Action

/// Action that runs multiple actions simultaneously.
public final class GroupAction: Action {
    private let actions: [Action]
    private var completedCount: Int = 0

    public init(_ actions: [Action]) {
        self.actions = actions.map { $0.copy() }
        let maxDuration = actions.reduce(0) { max($0, $1.duration) }
        super.init(duration: maxDuration)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        var allComplete = true

        for action in actions {
            if !action.isComplete {
                if action.evaluate(on: node, dt: dt) {
                    completedCount += 1
                } else {
                    allComplete = false
                }
            }
        }

        if allComplete {
            isComplete = true
            return true
        }

        return false
    }

    public override func copy() -> Action {
        GroupAction(actions)
    }

    internal override func reset() {
        super.reset()
        completedCount = 0
        for action in actions {
            action.reset()
        }
    }
}

// MARK: - Repeat Action

/// Action that repeats another action.
public final class RepeatAction: Action {
    private let action: Action
    private let count: Int
    private var currentCount: Int = 0
    private let forever: Bool

    public init(_ action: Action, count: Int) {
        self.action = action.copy()
        self.count = count
        self.forever = false
        super.init(duration: action.duration * Float(count))
    }

    private init(_ action: Action, forever: Bool) {
        self.action = action.copy()
        self.count = 0
        self.forever = true
        super.init(duration: Float.infinity)
    }

    public static func forever(_ action: Action) -> RepeatAction {
        RepeatAction(action, forever: true)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if action.evaluate(on: node, dt: dt) {
            currentCount += 1
            if !forever && currentCount >= count {
                isComplete = true
                return true
            }
            action.reset()
        }
        return false
    }

    public override func copy() -> Action {
        if forever {
            return RepeatAction.forever(action)
        } else {
            return RepeatAction(action, count: count)
        }
    }

    internal override func reset() {
        super.reset()
        currentCount = 0
        action.reset()
    }
}

// MARK: - Wait Action

/// Action that waits for a duration.
public final class WaitAction: Action {
    public override init(duration: Float) {
        super.init(duration: duration)
    }

    public override func copy() -> Action {
        WaitAction(duration: duration)
    }
}

// MARK: - Run Block Action

/// Action that runs a closure.
public final class RunBlockAction: Action {
    private let block: () -> Void
    private var hasRun: Bool = false

    public init(_ block: @escaping () -> Void) {
        self.block = block
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if !hasRun {
            block()
            hasRun = true
        }
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        RunBlockAction(block)
    }

    internal override func reset() {
        super.reset()
        hasRun = false
    }
}

// MARK: - Remove From Parent Action

/// Action that removes the node from its parent.
public final class RemoveFromParentAction: Action {
    public init() {
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        node.removeFromParent()
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        RemoveFromParentAction()
    }
}

// MARK: - Hide/Unhide Actions

/// Action that hides a node.
public final class HideAction: Action {
    public init() {
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        node.isHidden = true
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        HideAction()
    }
}

/// Action that shows a hidden node.
public final class UnhideAction: Action {
    public init() {
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        node.isHidden = false
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        UnhideAction()
    }
}

// MARK: - Texture Animation Actions

/// Action that animates a sprite through a sequence of textures.
public final class AnimateWithTexturesAction: Action {
    private let textures: [SNTexture]
    private let timePerFrame: Float
    private let resize: Bool
    private let restore: Bool
    private var originalTexture: SNTexture?
    private var currentFrameIndex: Int = 0

    /// Creates an action that animates through textures.
    ///
    /// - Parameters:
    ///   - textures: The array of textures to animate through.
    ///   - timePerFrame: The duration to display each texture.
    ///   - resize: Whether to resize the sprite to match each texture. Default is true.
    ///   - restore: Whether to restore the original texture after animation. Default is true.
    public init(textures: [SNTexture], timePerFrame: Float, resize: Bool = true, restore: Bool = true) {
        self.textures = textures
        self.timePerFrame = timePerFrame
        self.resize = resize
        self.restore = restore
        super.init(duration: Float(textures.count) * timePerFrame)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode, !textures.isEmpty else { return }

        if originalTexture == nil {
            originalTexture = sprite.texture
        }

        let frameIndex = min(Int(progress * Float(textures.count)), textures.count - 1)
        if frameIndex != currentFrameIndex || progress == 0 {
            currentFrameIndex = frameIndex
            sprite.texture = textures[frameIndex]
        }
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        let result = super.evaluate(on: node, dt: dt)
        if result && restore, let sprite = node as? SNSpriteNode {
            sprite.texture = originalTexture
        }
        return result
    }

    public override func copy() -> Action {
        let action = AnimateWithTexturesAction(textures: textures, timePerFrame: timePerFrame, resize: resize, restore: restore)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        originalTexture = nil
        currentFrameIndex = 0
    }
}

/// Action that immediately sets a sprite's texture.
public final class SetTextureAction: Action {
    private let texture: SNTexture
    private let resize: Bool

    /// Creates an action that sets the sprite's texture.
    ///
    /// - Parameters:
    ///   - texture: The new texture.
    ///   - resize: Whether to resize the sprite. Default is true.
    public init(texture: SNTexture, resize: Bool = true) {
        self.texture = texture
        self.resize = resize
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if let sprite = node as? SNSpriteNode {
            sprite.texture = texture
            if resize {
                sprite.size = texture.size
            }
        }
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        SetTextureAction(texture: texture, resize: resize)
    }
}

// MARK: - Color Actions

/// Action that animates a sprite's color and color blend factor.
public final class ColorizeAction: Action {
    private let targetColor: Color
    private let targetBlendFactor: Float
    private var startColor: Color?
    private var startBlendFactor: Float?

    /// Creates an action that colorizes a sprite.
    ///
    /// - Parameters:
    ///   - color: The target color.
    ///   - colorBlendFactor: The target blend factor (0-1).
    ///   - duration: The animation duration.
    public init(color: Color, colorBlendFactor: Float, duration: Float) {
        self.targetColor = color
        self.targetBlendFactor = colorBlendFactor
        super.init(duration: duration)
    }

    /// Creates an action that animates only the color blend factor.
    ///
    /// - Parameters:
    ///   - colorBlendFactor: The target blend factor (0-1).
    ///   - duration: The animation duration.
    public init(colorBlendFactor: Float, duration: Float) {
        self.targetColor = .white
        self.targetBlendFactor = colorBlendFactor
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode else { return }

        if startColor == nil {
            startColor = sprite.color
            startBlendFactor = sprite.colorBlendFactor
        }

        guard let startColor = startColor, let startBlendFactor = startBlendFactor else { return }

        sprite.color = Color.lerp(from: startColor, to: targetColor, t: progress)
        sprite.colorBlendFactor = startBlendFactor + (targetBlendFactor - startBlendFactor) * progress
    }

    public override func copy() -> Action {
        let action = ColorizeAction(color: targetColor, colorBlendFactor: targetBlendFactor, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startColor = nil
        startBlendFactor = nil
    }
}

// MARK: - Custom Action

/// Action that executes a custom block each frame with progress.
public final class CustomAction: Action {
    private let actionBlock: (SNNode, Float) -> Void

    /// Creates a custom action.
    ///
    /// - Parameters:
    ///   - duration: The action duration.
    ///   - actionBlock: A closure called each frame with the node and elapsed time.
    public init(duration: Float, actionBlock: @escaping (SNNode, Float) -> Void) {
        self.actionBlock = actionBlock
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        let elapsedTime = progress * duration
        actionBlock(node, elapsedTime)
    }

    public override func copy() -> Action {
        let action = CustomAction(duration: duration, actionBlock: actionBlock)
        action.timingMode = timingMode
        return action
    }
}

// MARK: - Axis-Specific Move Actions

/// Action that moves a node to a specific X position.
public final class MoveToXAction: Action {
    private let targetX: Float
    private var startX: Float?

    public init(x: Float, duration: Float) {
        self.targetX = x
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startX == nil {
            startX = node.position.x
        }
        guard let start = startX else { return }

        node.position = Point(
            x: start + (targetX - start) * progress,
            y: node.position.y
        )
    }

    public override func copy() -> Action {
        let action = MoveToXAction(x: targetX, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startX = nil
    }
}

/// Action that moves a node to a specific Y position.
public final class MoveToYAction: Action {
    private let targetY: Float
    private var startY: Float?

    public init(y: Float, duration: Float) {
        self.targetY = y
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startY == nil {
            startY = node.position.y
        }
        guard let start = startY else { return }

        node.position = Point(
            x: node.position.x,
            y: start + (targetY - start) * progress
        )
    }

    public override func copy() -> Action {
        let action = MoveToYAction(y: targetY, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startY = nil
    }
}

// MARK: - Axis-Specific Scale Actions

/// Action that scales a node's X axis to a specific value.
public final class ScaleXToAction: Action {
    private let targetScaleX: Float
    private var startScaleX: Float?

    public init(x: Float, duration: Float) {
        self.targetScaleX = x
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleX == nil {
            startScaleX = node.scale.width
        }
        guard let start = startScaleX else { return }

        node.scale = Size(
            width: start + (targetScaleX - start) * progress,
            height: node.scale.height
        )
    }

    public override func copy() -> Action {
        let action = ScaleXToAction(x: targetScaleX, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleX = nil
    }
}

/// Action that scales a node's Y axis to a specific value.
public final class ScaleYToAction: Action {
    private let targetScaleY: Float
    private var startScaleY: Float?

    public init(y: Float, duration: Float) {
        self.targetScaleY = y
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleY == nil {
            startScaleY = node.scale.height
        }
        guard let start = startScaleY else { return }

        node.scale = Size(
            width: node.scale.width,
            height: start + (targetScaleY - start) * progress
        )
    }

    public override func copy() -> Action {
        let action = ScaleYToAction(y: targetScaleY, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleY = nil
    }
}

/// Action that scales a node's X axis by a factor.
public final class ScaleXByAction: Action {
    private let factor: Float
    private var startScaleX: Float?

    public init(x: Float, duration: Float) {
        self.factor = x
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleX == nil {
            startScaleX = node.scale.width
        }
        guard let start = startScaleX else { return }

        node.scale = Size(
            width: start * (1 + (factor - 1) * progress),
            height: node.scale.height
        )
    }

    public override func copy() -> Action {
        let action = ScaleXByAction(x: factor, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleX = nil
    }
}

/// Action that scales a node's Y axis by a factor.
public final class ScaleYByAction: Action {
    private let factor: Float
    private var startScaleY: Float?

    public init(y: Float, duration: Float) {
        self.factor = y
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleY == nil {
            startScaleY = node.scale.height
        }
        guard let start = startScaleY else { return }

        node.scale = Size(
            width: node.scale.width,
            height: start * (1 + (factor - 1) * progress)
        )
    }

    public override func copy() -> Action {
        let action = ScaleYByAction(y: factor, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleY = nil
    }
}

// MARK: - Combined Scale Actions

/// Action that scales a node's X and Y axes to specific values.
public final class ScaleXYToAction: Action {
    private let targetX: Float
    private let targetY: Float
    private var startScaleX: Float?
    private var startScaleY: Float?

    public init(x: Float, y: Float, duration: Float) {
        self.targetX = x
        self.targetY = y
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleX == nil {
            startScaleX = node.scale.width
            startScaleY = node.scale.height
        }
        guard let startX = startScaleX, let startY = startScaleY else { return }

        node.scale = Size(
            width: startX + (targetX - startX) * progress,
            height: startY + (targetY - startY) * progress
        )
    }

    public override func copy() -> Action {
        let action = ScaleXYToAction(x: targetX, y: targetY, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleX = nil
        startScaleY = nil
    }
}

/// Action that scales a node's X and Y axes by factors.
public final class ScaleXYByAction: Action {
    private let factorX: Float
    private let factorY: Float
    private var startScaleX: Float?
    private var startScaleY: Float?

    public init(x: Float, y: Float, duration: Float) {
        self.factorX = x
        self.factorY = y
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startScaleX == nil {
            startScaleX = node.scale.width
            startScaleY = node.scale.height
        }
        guard let startX = startScaleX, let startY = startScaleY else { return }

        node.scale = Size(
            width: startX * (1 + (factorX - 1) * progress),
            height: startY * (1 + (factorY - 1) * progress)
        )
    }

    public override func copy() -> Action {
        let action = ScaleXYByAction(x: factorX, y: factorY, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startScaleX = nil
        startScaleY = nil
    }
}

// MARK: - Single-Axis Resize Actions

/// Action that resizes a sprite's width to a specific value.
public final class ResizeToWidthAction: Action {
    private let targetWidth: Float
    private var startWidth: Float?

    public init(width: Float, duration: Float) {
        self.targetWidth = width
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode else { return }

        if startWidth == nil {
            startWidth = sprite.size.width
        }
        guard let start = startWidth else { return }

        sprite.size = Size(
            width: start + (targetWidth - start) * progress,
            height: sprite.size.height
        )
    }

    public override func copy() -> Action {
        let action = ResizeToWidthAction(width: targetWidth, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startWidth = nil
    }
}

/// Action that resizes a sprite's height to a specific value.
public final class ResizeToHeightAction: Action {
    private let targetHeight: Float
    private var startHeight: Float?

    public init(height: Float, duration: Float) {
        self.targetHeight = height
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode else { return }

        if startHeight == nil {
            startHeight = sprite.size.height
        }
        guard let start = startHeight else { return }

        sprite.size = Size(
            width: sprite.size.width,
            height: start + (targetHeight - start) * progress
        )
    }

    public override func copy() -> Action {
        let action = ResizeToHeightAction(height: targetHeight, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startHeight = nil
    }
}

// MARK: - Shortest Arc Rotation Action

/// Action that rotates a node to an angle using the shortest path.
public final class RotateToShortestAction: Action {
    private let targetRotation: Float
    private var startRotation: Float?
    private var deltaRotation: Float = 0

    public init(to rotation: Float, duration: Float) {
        self.targetRotation = rotation
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startRotation == nil {
            startRotation = node.rotation
            // Calculate shortest path
            var delta = targetRotation - node.rotation
            // Normalize to [-π, π]
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            deltaRotation = delta
        }
        guard let start = startRotation else { return }

        node.rotation = start + deltaRotation * progress
    }

    public override func copy() -> Action {
        let action = RotateToShortestAction(to: targetRotation, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startRotation = nil
        deltaRotation = 0
    }
}

// MARK: - Normal Texture Actions

/// Action that sets a sprite's normal texture.
public final class SetNormalTextureAction: Action {
    private let texture: SNTexture

    public init(texture: SNTexture) {
        self.texture = texture
        super.init(duration: 0)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if let sprite = node as? SNSpriteNode {
            sprite.normalTexture = texture
        }
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        SetNormalTextureAction(texture: texture)
    }
}

/// Action that animates through normal textures.
public final class AnimateWithNormalTexturesAction: Action {
    private let textures: [SNTexture]
    private let timePerFrame: Float
    private var currentFrameIndex: Int = 0

    public init(textures: [SNTexture], timePerFrame: Float) {
        self.textures = textures
        self.timePerFrame = timePerFrame
        super.init(duration: Float(textures.count) * timePerFrame)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode, !textures.isEmpty else { return }

        let frameIndex = min(Int(progress * Float(textures.count)), textures.count - 1)
        if frameIndex != currentFrameIndex || progress == 0 {
            currentFrameIndex = frameIndex
            sprite.normalTexture = textures[frameIndex]
        }
    }

    public override func copy() -> Action {
        let action = AnimateWithNormalTexturesAction(textures: textures, timePerFrame: timePerFrame)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        currentFrameIndex = 0
    }
}

// MARK: - Warp Geometry Actions

/// Action that animates to a warp geometry.
public final class WarpToAction: Action {
    private let targetWarp: WarpGeometryGrid
    private var startWarp: WarpGeometryGrid?

    public init(warp: WarpGeometryGrid, duration: Float) {
        self.targetWarp = warp
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let warpable = node as? Warpable else { return }

        if startWarp == nil {
            if let currentWarp = warpable.warpGeometry as? WarpGeometryGrid {
                startWarp = currentWarp
            } else {
                // Create a default grid matching target dimensions
                startWarp = WarpGeometryGrid(
                    columns: targetWarp.columns,
                    rows: targetWarp.rows
                )
            }
        }
        guard let start = startWarp else { return }

        // Use the interpolate method which handles all the details
        if let interpolated = WarpGeometryGrid.interpolate(from: start, to: targetWarp, progress: progress) {
            warpable.warpGeometry = interpolated
        }
    }

    public override func copy() -> Action {
        let action = WarpToAction(warp: targetWarp, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startWarp = nil
    }
}

/// Action that animates through a sequence of warp geometries.
public final class AnimateWithWarpsAction: Action {
    private let warps: [WarpGeometryGrid]
    private let times: [Float]?
    private var currentIndex: Int = 0

    /// Creates an action that animates through warps with equal timing.
    public init(warps: [WarpGeometryGrid], duration: Float) {
        self.warps = warps
        self.times = nil
        super.init(duration: duration)
    }

    /// Creates an action that animates through warps with specified times.
    public init(warps: [WarpGeometryGrid], times: [Float]) {
        self.warps = warps
        self.times = times
        super.init(duration: times.reduce(0, +))
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let warpable = node as? Warpable, !warps.isEmpty else { return }

        let index: Int
        if let times = times {
            // Find the correct warp based on accumulated times
            var accumulated: Float = 0
            var foundIndex = 0
            for (i, time) in times.enumerated() {
                accumulated += time / duration
                if progress < accumulated {
                    foundIndex = i
                    break
                }
                foundIndex = i
            }
            index = min(foundIndex, warps.count - 1)
        } else {
            // Equal timing
            index = min(Int(progress * Float(warps.count)), warps.count - 1)
        }

        if index != currentIndex || progress == 0 {
            currentIndex = index
            warpable.warpGeometry = warps[index]
        }
    }

    public override func copy() -> Action {
        if let times = times {
            return AnimateWithWarpsAction(warps: warps, times: times)
        } else {
            return AnimateWithWarpsAction(warps: warps, duration: duration)
        }
    }

    internal override func reset() {
        super.reset()
        currentIndex = 0
    }
}

// MARK: - Node Speed Actions

/// Action that changes a node's speed property to a value.
public final class NodeSpeedToAction: Action {
    private let targetSpeed: Float
    private var startSpeed: Float?

    public init(speed: Float, duration: Float) {
        self.targetSpeed = speed
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startSpeed == nil {
            startSpeed = node.speed
        }
        guard let start = startSpeed else { return }

        node.speed = start + (targetSpeed - start) * progress
    }

    public override func copy() -> Action {
        let action = NodeSpeedToAction(speed: targetSpeed, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startSpeed = nil
    }
}

/// Action that changes a node's speed property by a delta.
public final class NodeSpeedByAction: Action {
    private let delta: Float
    private var startSpeed: Float?

    public init(delta: Float, duration: Float) {
        self.delta = delta
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startSpeed == nil {
            startSpeed = node.speed
        }
        guard let start = startSpeed else { return }

        node.speed = start + delta * progress
    }

    public override func copy() -> Action {
        let action = NodeSpeedByAction(delta: delta, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startSpeed = nil
    }
}

// MARK: - Follow Path with Speed Action

/// Action that moves a node along a path at a constant speed.
public final class FollowPathSpeedAction: Action {
    private let path: ShapePath
    private let pathSpeed: Float
    private let asOffset: Bool
    private let orientToPath: Bool
    private var startPosition: Point?
    private var pathLength: Float = 0
    private var currentDistance: Float = 0

    public init(path: ShapePath, speed: Float, asOffset: Bool = false, orientToPath: Bool = false) {
        self.path = path
        self.pathSpeed = speed
        self.asOffset = asOffset
        self.orientToPath = orientToPath
        // Calculate approximate path length for duration
        let estimatedLength = path.approximateLength()
        super.init(duration: estimatedLength / speed)
        self.pathLength = estimatedLength
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startPosition == nil {
            startPosition = node.position
        }
        guard let start = startPosition else { return }

        if let point = path.point(at: progress) {
            if asOffset {
                node.position = Point(x: start.x + point.x, y: start.y + point.y)
            } else {
                node.position = point
            }

            if orientToPath, progress < 1.0 {
                if let nextPoint = path.point(at: min(progress + 0.01, 1.0)) {
                    let dx = nextPoint.x - point.x
                    let dy = nextPoint.y - point.y
                    node.rotation = atan2(dy, dx)
                }
            }
        }
    }

    public override func copy() -> Action {
        FollowPathSpeedAction(path: path, speed: pathSpeed, asOffset: asOffset, orientToPath: orientToPath)
    }

    internal override func reset() {
        super.reset()
        startPosition = nil
        currentDistance = 0
    }
}

// MARK: - Fade By Action

/// Action that fades a node by a relative alpha amount.
public final class FadeByAction: Action {
    private let delta: Float
    private var startAlpha: Float?

    public init(by delta: Float, duration: Float) {
        self.delta = delta
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startAlpha == nil {
            startAlpha = node.alpha
        }
        guard let start = startAlpha else { return }

        node.alpha = max(0, min(1, start + delta * progress))
    }

    public override func copy() -> Action {
        let action = FadeByAction(by: delta, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startAlpha = nil
    }
}

// MARK: - Speed Action

/// Action that modifies the speed of another action.
public final class SpeedAction: Action {
    private let wrappedAction: Action
    private let speedMultiplier: Float

    /// Creates an action that runs another action at a different speed.
    ///
    /// - Parameters:
    ///   - action: The action to wrap.
    ///   - speed: The speed multiplier (2.0 = twice as fast, 0.5 = half speed).
    public init(action: Action, speed: Float) {
        self.wrappedAction = action.copy()
        self.speedMultiplier = speed
        super.init(duration: action.duration / speed)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        let adjustedDt = dt * speedMultiplier
        let result = wrappedAction.evaluate(on: node, dt: adjustedDt)
        if result {
            isComplete = true
        }
        return result
    }

    public override func copy() -> Action {
        SpeedAction(action: wrappedAction, speed: speedMultiplier)
    }

    internal override func reset() {
        super.reset()
        wrappedAction.reset()
    }
}

// MARK: - Reversed Action Support

/// Action that runs another action in reverse.
public final class ReversedAction: Action {
    private let originalAction: Action
    private var hasInitialized: Bool = false

    /// Creates an action that runs another action in reverse.
    ///
    /// - Parameter action: The action to reverse.
    public init(action: Action) {
        self.originalAction = action.copy()
        super.init(duration: action.duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        // Run the original action with inverted progress
        originalAction.apply(to: node, progress: 1.0 - progress)
    }

    public override func copy() -> Action {
        let action = ReversedAction(action: originalAction)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        originalAction.reset()
        hasInitialized = false
    }
}

// MARK: - Follow Path Action

/// Action that moves a node along a path.
public final class FollowPathAction: Action {
    private let path: ShapePath
    private let asOffset: Bool
    private let orientToPath: Bool
    private var startPosition: Point?

    /// Creates an action that moves a node along a path.
    ///
    /// - Parameters:
    ///   - path: The path to follow.
    ///   - asOffset: If true, path coordinates are relative to node position.
    ///   - orientToPath: If true, node rotates to face path direction.
    ///   - duration: The duration to traverse the path.
    public init(path: ShapePath, asOffset: Bool = false, orientToPath: Bool = false, duration: Float) {
        self.path = path
        self.asOffset = asOffset
        self.orientToPath = orientToPath
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        if startPosition == nil {
            startPosition = node.position
        }
        guard let start = startPosition else { return }

        // Sample the path at the current progress
        if let point = path.point(at: progress) {
            if asOffset {
                node.position = Point(x: start.x + point.x, y: start.y + point.y)
            } else {
                node.position = point
            }

            // Orient to path direction
            if orientToPath, progress < 1.0 {
                if let nextPoint = path.point(at: min(progress + 0.01, 1.0)) {
                    let dx = nextPoint.x - point.x
                    let dy = nextPoint.y - point.y
                    node.rotation = atan2(dy, dx)
                }
            }
        }
    }

    public override func copy() -> Action {
        let action = FollowPathAction(path: path, asOffset: asOffset, orientToPath: orientToPath, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startPosition = nil
    }
}

// MARK: - Resize Action

/// Action that resizes a sprite to a specific size.
public final class ResizeToAction: Action {
    private let targetSize: Size
    private var startSize: Size?

    public init(to size: Size, duration: Float) {
        self.targetSize = size
        super.init(duration: duration)
    }

    public init(width: Float, height: Float, duration: Float) {
        self.targetSize = Size(width: width, height: height)
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode else { return }

        if startSize == nil {
            startSize = sprite.size
        }
        guard let start = startSize else { return }

        sprite.size = Size(
            width: start.width + (targetSize.width - start.width) * progress,
            height: start.height + (targetSize.height - start.height) * progress
        )
    }

    public override func copy() -> Action {
        let action = ResizeToAction(to: targetSize, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startSize = nil
    }
}

/// Action that resizes a sprite by a delta.
public final class ResizeByAction: Action {
    private let delta: Size
    private var startSize: Size?

    public init(by delta: Size, duration: Float) {
        self.delta = delta
        super.init(duration: duration)
    }

    public init(width: Float, height: Float, duration: Float) {
        self.delta = Size(width: width, height: height)
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let sprite = node as? SNSpriteNode else { return }

        if startSize == nil {
            startSize = sprite.size
        }
        guard let start = startSize else { return }

        sprite.size = Size(
            width: start.width + delta.width * progress,
            height: start.height + delta.height * progress
        )
    }

    public override func copy() -> Action {
        let action = ResizeByAction(by: delta, duration: duration)
        action.timingMode = timingMode
        return action
    }

    internal override func reset() {
        super.reset()
        startSize = nil
    }
}

// MARK: - Factory Methods

extension Action {
    // MARK: Move

    /// Creates an action that moves a node to a position.
    public static func move(to position: Point, duration: Float) -> Action {
        MoveToAction(to: position, duration: duration)
    }

    /// Creates an action that moves a node by a delta.
    public static func move(by delta: Vector2, duration: Float) -> Action {
        MoveByAction(by: delta, duration: duration)
    }

    /// Creates an action that moves a node horizontally.
    public static func moveBy(x: Float, y: Float, duration: Float) -> Action {
        MoveByAction(by: Vector2(dx: x, dy: y), duration: duration)
    }

    // MARK: Rotate

    /// Creates an action that rotates a node to an angle.
    public static func rotate(to angle: Float, duration: Float) -> Action {
        RotateToAction(to: angle, duration: duration)
    }

    /// Creates an action that rotates a node by a delta.
    public static func rotate(by angle: Float, duration: Float) -> Action {
        RotateByAction(by: angle, duration: duration)
    }

    // MARK: Scale

    /// Creates an action that scales a node to a size.
    public static func scale(to scale: Float, duration: Float) -> Action {
        ScaleToAction(to: scale, duration: duration)
    }

    /// Creates an action that scales a node by a factor.
    public static func scale(by factor: Float, duration: Float) -> Action {
        ScaleByAction(by: factor, duration: duration)
    }

    // MARK: Fade

    /// Creates an action that fades a node to an alpha value.
    public static func fade(to alpha: Float, duration: Float) -> Action {
        FadeToAction(to: alpha, duration: duration)
    }

    /// Creates an action that fades a node in.
    public static func fadeIn(duration: Float) -> Action {
        FadeToAction(to: 1.0, duration: duration)
    }

    /// Creates an action that fades a node out.
    public static func fadeOut(duration: Float) -> Action {
        FadeToAction(to: 0.0, duration: duration)
    }

    // MARK: Composite

    /// Creates an action that runs a sequence of actions.
    public static func sequence(_ actions: [Action]) -> Action {
        SequenceAction(actions)
    }

    /// Creates an action that runs multiple actions simultaneously.
    public static func group(_ actions: [Action]) -> Action {
        GroupAction(actions)
    }

    /// Creates an action that repeats another action.
    public static func `repeat`(_ action: Action, count: Int) -> Action {
        RepeatAction(action, count: count)
    }

    /// Creates an action that repeats another action forever.
    public static func repeatForever(_ action: Action) -> Action {
        RepeatAction.forever(action)
    }

    // MARK: Utility

    /// Creates an action that waits for a duration.
    public static func wait(duration: Float) -> Action {
        WaitAction(duration: duration)
    }

    /// Creates an action that runs a closure.
    public static func run(_ block: @escaping () -> Void) -> Action {
        RunBlockAction(block)
    }

    /// Creates an action that removes the node from its parent.
    public static func removeFromParent() -> Action {
        RemoveFromParentAction()
    }

    /// Creates an action that hides a node.
    public static func hide() -> Action {
        HideAction()
    }

    /// Creates an action that shows a node.
    public static func unhide() -> Action {
        UnhideAction()
    }

    // MARK: Texture Animation

    /// Creates an action that animates through a sequence of textures.
    ///
    /// - Parameters:
    ///   - textures: The textures to animate through.
    ///   - timePerFrame: The duration to display each texture.
    /// - Returns: An action that cycles through the textures.
    public static func animate(with textures: [SNTexture], timePerFrame: Float) -> Action {
        AnimateWithTexturesAction(textures: textures, timePerFrame: timePerFrame)
    }

    /// Creates an action that animates through textures with options.
    ///
    /// - Parameters:
    ///   - textures: The textures to animate through.
    ///   - timePerFrame: The duration to display each texture.
    ///   - resize: Whether to resize the sprite.
    ///   - restore: Whether to restore the original texture.
    /// - Returns: An action that cycles through the textures.
    public static func animate(with textures: [SNTexture], timePerFrame: Float, resize: Bool, restore: Bool) -> Action {
        AnimateWithTexturesAction(textures: textures, timePerFrame: timePerFrame, resize: resize, restore: restore)
    }

    /// Creates an action that sets a sprite's texture.
    ///
    /// - Parameter texture: The new texture.
    /// - Returns: An instant action that sets the texture.
    public static func setTexture(_ texture: SNTexture) -> Action {
        SetTextureAction(texture: texture)
    }

    /// Creates an action that sets a sprite's texture with resize option.
    ///
    /// - Parameters:
    ///   - texture: The new texture.
    ///   - resize: Whether to resize the sprite.
    /// - Returns: An instant action that sets the texture.
    public static func setTexture(_ texture: SNTexture, resize: Bool) -> Action {
        SetTextureAction(texture: texture, resize: resize)
    }

    // MARK: Colorize

    /// Creates an action that colorizes a sprite.
    ///
    /// - Parameters:
    ///   - color: The target color.
    ///   - colorBlendFactor: The target blend factor (0-1).
    ///   - duration: The animation duration.
    /// - Returns: An action that animates the color.
    public static func colorize(with color: Color, colorBlendFactor: Float, duration: Float) -> Action {
        ColorizeAction(color: color, colorBlendFactor: colorBlendFactor, duration: duration)
    }

    /// Creates an action that animates the color blend factor.
    ///
    /// - Parameters:
    ///   - colorBlendFactor: The target blend factor (0-1).
    ///   - duration: The animation duration.
    /// - Returns: An action that animates the blend factor.
    public static func colorize(withColorBlendFactor colorBlendFactor: Float, duration: Float) -> Action {
        ColorizeAction(colorBlendFactor: colorBlendFactor, duration: duration)
    }

    // MARK: Custom

    /// Creates a custom action that executes a block each frame.
    ///
    /// - Parameters:
    ///   - duration: The action duration.
    ///   - actionBlock: A closure called each frame with the node and elapsed time.
    /// - Returns: A custom action.
    public static func customAction(withDuration duration: Float, actionBlock: @escaping (SNNode, Float) -> Void) -> Action {
        CustomAction(duration: duration, actionBlock: actionBlock)
    }

    // MARK: Axis-Specific Move

    /// Creates an action that moves a node to a specific X position.
    ///
    /// - Parameters:
    ///   - x: The target X position.
    ///   - duration: The animation duration.
    /// - Returns: An action that moves to the X position.
    public static func moveTo(x: Float, duration: Float) -> Action {
        MoveToXAction(x: x, duration: duration)
    }

    /// Creates an action that moves a node to a specific Y position.
    ///
    /// - Parameters:
    ///   - y: The target Y position.
    ///   - duration: The animation duration.
    /// - Returns: An action that moves to the Y position.
    public static func moveTo(y: Float, duration: Float) -> Action {
        MoveToYAction(y: y, duration: duration)
    }

    // MARK: Axis-Specific Scale

    /// Creates an action that scales a node's X axis.
    ///
    /// - Parameters:
    ///   - x: The target X scale.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales the X axis.
    public static func scaleX(to x: Float, duration: Float) -> Action {
        ScaleXToAction(x: x, duration: duration)
    }

    /// Creates an action that scales a node's Y axis.
    ///
    /// - Parameters:
    ///   - y: The target Y scale.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales the Y axis.
    public static func scaleY(to y: Float, duration: Float) -> Action {
        ScaleYToAction(y: y, duration: duration)
    }

    /// Creates an action that scales a node's X axis by a factor.
    ///
    /// - Parameters:
    ///   - x: The scale factor.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales the X axis by a factor.
    public static func scaleX(by x: Float, duration: Float) -> Action {
        ScaleXByAction(x: x, duration: duration)
    }

    /// Creates an action that scales a node's Y axis by a factor.
    ///
    /// - Parameters:
    ///   - y: The scale factor.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales the Y axis by a factor.
    public static func scaleY(by y: Float, duration: Float) -> Action {
        ScaleYByAction(y: y, duration: duration)
    }

    // MARK: Fade By

    /// Creates an action that fades a node by a relative amount.
    ///
    /// - Parameters:
    ///   - delta: The alpha change (-1 to 1).
    ///   - duration: The animation duration.
    /// - Returns: An action that changes alpha by the delta.
    public static func fade(by delta: Float, duration: Float) -> Action {
        FadeByAction(by: delta, duration: duration)
    }

    // MARK: Speed

    /// Creates an action that runs another action at a different speed.
    ///
    /// - Parameters:
    ///   - action: The action to run.
    ///   - speed: The speed multiplier.
    /// - Returns: An action that runs at the specified speed.
    public static func speed(_ action: Action, by speed: Float) -> Action {
        SpeedAction(action: action, speed: speed)
    }

    // MARK: Reversed

    /// Creates an action that runs another action in reverse.
    ///
    /// - Parameter action: The action to reverse.
    /// - Returns: An action that runs in reverse.
    public static func reversed(_ action: Action) -> Action {
        ReversedAction(action: action)
    }

    // MARK: Follow Path

    /// Creates an action that moves a node along a path.
    ///
    /// - Parameters:
    ///   - path: The path to follow.
    ///   - duration: The duration to traverse the path.
    /// - Returns: An action that follows the path.
    public static func follow(_ path: ShapePath, duration: Float) -> Action {
        FollowPathAction(path: path, duration: duration)
    }

    /// Creates an action that moves a node along a path with options.
    ///
    /// - Parameters:
    ///   - path: The path to follow.
    ///   - asOffset: Whether path is relative to start position.
    ///   - orientToPath: Whether to rotate toward path direction.
    ///   - duration: The duration to traverse the path.
    /// - Returns: An action that follows the path.
    public static func follow(_ path: ShapePath, asOffset: Bool, orientToPath: Bool, duration: Float) -> Action {
        FollowPathAction(path: path, asOffset: asOffset, orientToPath: orientToPath, duration: duration)
    }

    // MARK: Resize

    /// Creates an action that resizes a sprite.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - height: The target height.
    ///   - duration: The animation duration.
    /// - Returns: An action that resizes the sprite.
    public static func resize(toWidth width: Float, height: Float, duration: Float) -> Action {
        ResizeToAction(width: width, height: height, duration: duration)
    }

    /// Creates an action that resizes a sprite by a delta.
    ///
    /// - Parameters:
    ///   - width: The width change.
    ///   - height: The height change.
    ///   - duration: The animation duration.
    /// - Returns: An action that resizes by the delta.
    public static func resize(byWidth width: Float, height: Float, duration: Float) -> Action {
        ResizeByAction(width: width, height: height, duration: duration)
    }

    /// Creates an action that resizes a sprite's width only.
    ///
    /// - Parameters:
    ///   - width: The target width.
    ///   - duration: The animation duration.
    /// - Returns: An action that resizes the width.
    public static func resize(toWidth width: Float, duration: Float) -> Action {
        ResizeToWidthAction(width: width, duration: duration)
    }

    /// Creates an action that resizes a sprite's height only.
    ///
    /// - Parameters:
    ///   - height: The target height.
    ///   - duration: The animation duration.
    /// - Returns: An action that resizes the height.
    public static func resize(toHeight height: Float, duration: Float) -> Action {
        ResizeToHeightAction(height: height, duration: duration)
    }

    // MARK: Combined Scale

    /// Creates an action that scales a node's X and Y axes to different values.
    ///
    /// - Parameters:
    ///   - x: The target X scale.
    ///   - y: The target Y scale.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales both axes.
    public static func scaleX(to x: Float, y: Float, duration: Float) -> Action {
        ScaleXYToAction(x: x, y: y, duration: duration)
    }

    /// Creates an action that scales a node's X and Y axes by different factors.
    ///
    /// - Parameters:
    ///   - x: The X scale factor.
    ///   - y: The Y scale factor.
    ///   - duration: The animation duration.
    /// - Returns: An action that scales both axes by factors.
    public static func scaleX(by x: Float, y: Float, duration: Float) -> Action {
        ScaleXYByAction(x: x, y: y, duration: duration)
    }

    // MARK: Shortest Arc Rotation

    /// Creates an action that rotates to an angle using the shortest path.
    ///
    /// - Parameters:
    ///   - angle: The target angle in radians.
    ///   - shortestUnitArc: If true, rotates via shortest path.
    ///   - duration: The animation duration.
    /// - Returns: An action that rotates using shortest arc.
    public static func rotate(to angle: Float, shortestUnitArc: Bool, duration: Float) -> Action {
        if shortestUnitArc {
            return RotateToShortestAction(to: angle, duration: duration)
        } else {
            return RotateToAction(to: angle, duration: duration)
        }
    }

    // MARK: Normal Texture

    /// Creates an action that sets a sprite's normal texture.
    ///
    /// - Parameter texture: The normal texture.
    /// - Returns: An instant action that sets the normal texture.
    public static func setNormalTexture(_ texture: SNTexture) -> Action {
        SetNormalTextureAction(texture: texture)
    }

    /// Creates an action that animates through normal textures.
    ///
    /// - Parameters:
    ///   - textures: The normal textures to animate through.
    ///   - timePerFrame: The duration to display each texture.
    /// - Returns: An action that cycles through the normal textures.
    public static func animate(withNormalTextures textures: [SNTexture], timePerFrame: Float) -> Action {
        AnimateWithNormalTexturesAction(textures: textures, timePerFrame: timePerFrame)
    }

    // MARK: Warp Geometry

    /// Creates an action that animates to a warp geometry.
    ///
    /// - Parameters:
    ///   - warp: The target warp geometry.
    ///   - duration: The animation duration.
    /// - Returns: An action that animates the warp.
    public static func warp(to warp: WarpGeometryGrid, duration: Float) -> Action {
        WarpToAction(warp: warp, duration: duration)
    }

    /// Creates an action that animates through warp geometries.
    ///
    /// - Parameters:
    ///   - warps: The warp geometries to animate through.
    ///   - times: The durations for each warp.
    /// - Returns: An action that cycles through the warps.
    public static func animate(withWarps warps: [WarpGeometryGrid], times: [Float]) -> Action {
        AnimateWithWarpsAction(warps: warps, times: times)
    }

    /// Creates an action that animates through warp geometries with equal timing.
    ///
    /// - Parameters:
    ///   - warps: The warp geometries to animate through.
    ///   - duration: The total animation duration.
    /// - Returns: An action that cycles through the warps.
    public static func animate(withWarps warps: [WarpGeometryGrid], duration: Float) -> Action {
        AnimateWithWarpsAction(warps: warps, duration: duration)
    }

    // MARK: Node Speed

    /// Creates an action that changes a node's speed to a value.
    ///
    /// - Parameters:
    ///   - speed: The target speed.
    ///   - duration: The animation duration.
    /// - Returns: An action that changes node speed.
    public static func speed(to speed: Float, duration: Float) -> Action {
        NodeSpeedToAction(speed: speed, duration: duration)
    }

    /// Creates an action that changes a node's speed by a delta.
    ///
    /// - Parameters:
    ///   - delta: The speed change.
    ///   - duration: The animation duration.
    /// - Returns: An action that changes node speed.
    public static func speed(by delta: Float, duration: Float) -> Action {
        NodeSpeedByAction(delta: delta, duration: duration)
    }

    // MARK: Follow Path with Speed

    /// Creates an action that moves a node along a path at a constant speed.
    ///
    /// - Parameters:
    ///   - path: The path to follow.
    ///   - speed: The movement speed in points per second.
    /// - Returns: An action that follows the path at constant speed.
    public static func follow(_ path: ShapePath, speed: Float) -> Action {
        FollowPathSpeedAction(path: path, speed: speed)
    }

    /// Creates an action that moves a node along a path at a constant speed with options.
    ///
    /// - Parameters:
    ///   - path: The path to follow.
    ///   - asOffset: Whether path is relative to start position.
    ///   - orientToPath: Whether to rotate toward path direction.
    ///   - speed: The movement speed in points per second.
    /// - Returns: An action that follows the path at constant speed.
    public static func follow(_ path: ShapePath, asOffset: Bool, orientToPath: Bool, speed: Float) -> Action {
        FollowPathSpeedAction(path: path, speed: speed, asOffset: asOffset, orientToPath: orientToPath)
    }

    // MARK: Wait with Range

    /// Creates an action that waits for a random duration within a range.
    ///
    /// - Parameters:
    ///   - duration: The base duration.
    ///   - range: The random range to add (0 to range).
    /// - Returns: An action that waits for a random duration.
    public static func wait(duration: Float, withRange range: Float) -> Action {
        let randomValue = Float.random(in: 0...1)
        let totalDuration = duration + randomValue * range
        return WaitAction(duration: totalDuration)
    }

    // MARK: Reach (Inverse Kinematics)

    /// Creates an action that performs inverse kinematics to reach a point.
    ///
    /// - Parameters:
    ///   - point: The target point to reach.
    ///   - rootNode: The root of the IK chain.
    ///   - duration: The animation duration.
    /// - Returns: An action that performs IK.
    public static func reach(to point: Point, rootNode: SNNode, duration: Float) -> Action {
        ReachAction(targetPoint: point, rootNode: rootNode, duration: duration)
    }

    /// Creates an action that performs inverse kinematics to reach a node.
    ///
    /// - Parameters:
    ///   - node: The target node to reach.
    ///   - rootNode: The root of the IK chain.
    ///   - duration: The animation duration.
    /// - Returns: An action that performs IK.
    public static func reach(to node: SNNode, rootNode: SNNode, duration: Float) -> Action {
        ReachToNodeAction(targetNode: node, rootNode: rootNode, duration: duration)
    }

    // MARK: Apply Physics

    /// Creates an action that applies a force to a physics body.
    ///
    /// - Parameters:
    ///   - force: The force vector.
    ///   - duration: The duration to apply the force.
    /// - Returns: An action that applies force.
    public static func applyForce(_ force: Vector2, duration: Float) -> Action {
        ApplyForceAction(force: force, duration: duration)
    }

    /// Creates an action that applies an impulse to a physics body.
    ///
    /// - Parameters:
    ///   - impulse: The impulse vector.
    ///   - duration: The duration (typically instantaneous).
    /// - Returns: An action that applies impulse.
    public static func applyImpulse(_ impulse: Vector2, duration: Float) -> Action {
        ApplyImpulseAction(impulse: impulse, duration: duration)
    }

    /// Creates an action that applies torque to a physics body.
    ///
    /// - Parameters:
    ///   - torque: The torque value.
    ///   - duration: The duration to apply the torque.
    /// - Returns: An action that applies torque.
    public static func applyTorque(_ torque: Float, duration: Float) -> Action {
        ApplyTorqueAction(torque: torque, duration: duration)
    }

    /// Creates an action that applies angular impulse to a physics body.
    ///
    /// - Parameters:
    ///   - impulse: The angular impulse value.
    ///   - duration: The duration (typically instantaneous).
    /// - Returns: An action that applies angular impulse.
    public static func applyAngularImpulse(_ impulse: Float, duration: Float) -> Action {
        ApplyAngularImpulseAction(impulse: impulse, duration: duration)
    }

    // MARK: Field Strength

    /// Creates an action that changes a field node's strength.
    ///
    /// - Parameters:
    ///   - strength: The target strength.
    ///   - duration: The animation duration.
    /// - Returns: An action that changes field strength.
    public static func strength(to strength: Float, duration: Float) -> Action {
        FieldStrengthAction(strength: strength, duration: duration)
    }

    /// Creates an action that changes a field node's falloff.
    ///
    /// - Parameters:
    ///   - falloff: The target falloff.
    ///   - duration: The animation duration.
    /// - Returns: An action that changes field falloff.
    public static func falloff(to falloff: Float, duration: Float) -> Action {
        FieldFalloffAction(falloff: falloff, duration: duration)
    }
}

// MARK: - Reach Actions (Inverse Kinematics)

/// Action that performs inverse kinematics to reach a point.
public final class ReachAction: Action {
    private let targetPoint: Point
    private weak var rootNode: SNNode?

    public init(targetPoint: Point, rootNode: SNNode, duration: Float) {
        self.targetPoint = targetPoint
        self.rootNode = rootNode
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let root = rootNode else { return }
        solveIK(endEffector: node, root: root, target: targetPoint, progress: progress)
    }

    private func solveIK(endEffector: SNNode, root: SNNode, target: Point, progress: Float) {
        var chain: [SNNode] = []
        var current: SNNode? = endEffector
        while let node = current, node !== root.parent {
            chain.append(node)
            current = node.parent
        }

        guard chain.count >= 2 else { return }

        let mid = chain[1]
        let targetPos = Point.lerp(from: endEffector.worldPosition, to: target, t: progress)
        let rootWorldPos = root.worldPosition

        let toTarget = atan2(targetPos.y - rootWorldPos.y, targetPos.x - rootWorldPos.x)
        let midWorldPos = mid.worldPosition
        let toMid = atan2(midWorldPos.y - rootWorldPos.y, midWorldPos.x - rootWorldPos.x)

        let deltaAngle = toTarget - toMid
        if let constraints = mid.reachConstraints {
            mid.rotation += constraints.clamp(deltaAngle) * progress
        } else {
            mid.rotation += deltaAngle * progress
        }
    }

    public override func copy() -> Action {
        ReachAction(targetPoint: targetPoint, rootNode: rootNode!, duration: duration)
    }
}

/// Action that performs inverse kinematics to reach another node.
public final class ReachToNodeAction: Action {
    private weak var targetNode: SNNode?
    private weak var rootNode: SNNode?

    public init(targetNode: SNNode, rootNode: SNNode, duration: Float) {
        self.targetNode = targetNode
        self.rootNode = rootNode
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let target = targetNode, let root = rootNode else { return }
        solveIK(endEffector: node, root: root, target: target.worldPosition, progress: progress)
    }

    private func solveIK(endEffector: SNNode, root: SNNode, target: Point, progress: Float) {
        var chain: [SNNode] = []
        var current: SNNode? = endEffector
        while let node = current, node !== root.parent {
            chain.append(node)
            current = node.parent
        }

        guard chain.count >= 2 else { return }

        let mid = chain[1]
        let rootWorldPos = root.worldPosition

        let toTarget = atan2(target.y - rootWorldPos.y, target.x - rootWorldPos.x)
        let midWorldPos = mid.worldPosition
        let toMid = atan2(midWorldPos.y - rootWorldPos.y, midWorldPos.x - rootWorldPos.x)

        let deltaAngle = toTarget - toMid
        if let constraints = mid.reachConstraints {
            mid.rotation += constraints.clamp(deltaAngle) * progress
        } else {
            mid.rotation += deltaAngle * progress
        }
    }

    public override func copy() -> Action {
        ReachToNodeAction(targetNode: targetNode!, rootNode: rootNode!, duration: duration)
    }
}

// MARK: - Physics Actions

/// Action that applies a force to a physics body.
public final class ApplyForceAction: Action {
    private let force: Vector2

    public init(force: Vector2, duration: Float) {
        self.force = force
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let body = node.physicsBody else { return }
        body.velocity = body.velocity + force * (1.0 / 60.0)
    }

    public override func copy() -> Action {
        ApplyForceAction(force: force, duration: duration)
    }
}

/// Action that applies an impulse to a physics body.
public final class ApplyImpulseAction: Action {
    private let impulse: Vector2
    private var applied = false

    public init(impulse: Vector2, duration: Float) {
        self.impulse = impulse
        super.init(duration: duration)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if !applied, let body = node.physicsBody {
            body.velocity = body.velocity + impulse / body.mass
            applied = true
        }
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        ApplyImpulseAction(impulse: impulse, duration: duration)
    }
}

/// Action that applies torque to a physics body.
public final class ApplyTorqueAction: Action {
    private let torque: Float

    public init(torque: Float, duration: Float) {
        self.torque = torque
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let body = node.physicsBody else { return }
        body.angularVelocity += torque * (1.0 / 60.0)
    }

    public override func copy() -> Action {
        ApplyTorqueAction(torque: torque, duration: duration)
    }
}

/// Action that applies angular impulse to a physics body.
public final class ApplyAngularImpulseAction: Action {
    private let impulse: Float
    private var applied = false

    public init(impulse: Float, duration: Float) {
        self.impulse = impulse
        super.init(duration: duration)
    }

    internal override func evaluate(on node: SNNode, dt: Float) -> Bool {
        if !applied, let body = node.physicsBody {
            body.angularVelocity += impulse
            applied = true
        }
        isComplete = true
        return true
    }

    public override func copy() -> Action {
        ApplyAngularImpulseAction(impulse: impulse, duration: duration)
    }
}

// MARK: - Field Actions

/// Action that animates a field node's strength.
public final class FieldStrengthAction: Action {
    private let targetStrength: Float
    private var startStrength: Float = 0

    public init(strength: Float, duration: Float) {
        self.targetStrength = strength
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let field = node as? SNFieldNode else { return }
        if progress == 0 {
            startStrength = field.strength
        }
        field.strength = startStrength + (targetStrength - startStrength) * progress
    }

    public override func copy() -> Action {
        FieldStrengthAction(strength: targetStrength, duration: duration)
    }
}

/// Action that animates a field node's falloff.
public final class FieldFalloffAction: Action {
    private let targetFalloff: Float
    private var startFalloff: Float = 0

    public init(falloff: Float, duration: Float) {
        self.targetFalloff = falloff
        super.init(duration: duration)
    }

    internal override func apply(to node: SNNode, progress: Float) {
        guard let field = node as? SNFieldNode else { return }
        if progress == 0 {
            startFalloff = field.falloff
        }
        field.falloff = startFalloff + (targetFalloff - startFalloff) * progress
    }

    public override func copy() -> Action {
        FieldFalloffAction(falloff: targetFalloff, duration: duration)
    }
}
