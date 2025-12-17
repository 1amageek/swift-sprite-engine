/// An object used to perform an animated transition to a new scene.
///
/// When presenting a new scene, you can use a transition to animate the change
/// from the old scene to the new scene. Using a transition provides continuity
/// so that the scene change is not abrupt.
///
/// ## Usage
/// ```swift
/// let newScene = GameScene(size: currentScene.size)
/// let transition = SNTransition.crossFade(duration: 1.0)
/// view.presentScene(newScene, transition: transition)
/// ```
public final class SNTransition: Sendable {
    // MARK: - Transition Type

    /// The type of transition effect.
    public enum TransitionType: Sendable {
        case crossFade
        case fade(color: Color)
        case fadeWithBlack
        case flipHorizontal
        case flipVertical
        case doorway
        case doorsOpenHorizontal
        case doorsOpenVertical
        case doorsCloseHorizontal
        case doorsCloseVertical
        case moveIn(direction: TransitionDirection)
        case push(direction: TransitionDirection)
        case reveal(direction: TransitionDirection)
    }

    // MARK: - Properties

    /// The duration of the transition in seconds.
    public let duration: CGFloat

    /// The type of transition effect.
    public let type: TransitionType

    /// Whether the incoming scene is paused during the transition.
    public let pausesIncomingScene: Bool

    /// Whether the outgoing scene is paused during the transition.
    public let pausesOutgoingScene: Bool

    // MARK: - Initialization

    private init(
        type: TransitionType,
        duration: CGFloat,
        pausesIncomingScene: Bool = true,
        pausesOutgoingScene: Bool = true
    ) {
        self.type = type
        self.duration = duration
        self.pausesIncomingScene = pausesIncomingScene
        self.pausesOutgoingScene = pausesOutgoingScene
    }

    // MARK: - Factory Methods: Fade Transitions

    /// Creates a cross fade transition.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func crossFade(duration: CGFloat) -> SNTransition {
        SNTransition(type: .crossFade, duration: duration)
    }

    /// Creates a transition that first fades to black and then fades to the new scene.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func fade(duration: CGFloat) -> SNTransition {
        SNTransition(type: .fadeWithBlack, duration: duration)
    }

    /// Creates a transition that first fades to a color and then fades to the new scene.
    ///
    /// - Parameters:
    ///   - color: The intermediate color.
    ///   - duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func fade(with color: Color, duration: CGFloat) -> SNTransition {
        SNTransition(type: .fade(color: color), duration: duration)
    }

    // MARK: - Factory Methods: Flip Transitions

    /// Creates a transition where scenes are flipped across a horizontal line.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func flipHorizontal(duration: CGFloat) -> SNTransition {
        SNTransition(type: .flipHorizontal, duration: duration)
    }

    /// Creates a transition where scenes are flipped across a vertical line.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func flipVertical(duration: CGFloat) -> SNTransition {
        SNTransition(type: .flipVertical, duration: duration)
    }

    // MARK: - Factory Methods: Door Transitions

    /// Creates a transition where the previous scene disappears as opening doors.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func doorway(duration: CGFloat) -> SNTransition {
        SNTransition(type: .doorway, duration: duration)
    }

    /// Creates a transition where the new scene appears as opening horizontal doors.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func doorsOpenHorizontal(duration: CGFloat) -> SNTransition {
        SNTransition(type: .doorsOpenHorizontal, duration: duration)
    }

    /// Creates a transition where the new scene appears as opening vertical doors.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func doorsOpenVertical(duration: CGFloat) -> SNTransition {
        SNTransition(type: .doorsOpenVertical, duration: duration)
    }

    /// Creates a transition where the new scene appears as closing horizontal doors.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func doorsCloseHorizontal(duration: CGFloat) -> SNTransition {
        SNTransition(type: .doorsCloseHorizontal, duration: duration)
    }

    /// Creates a transition where the new scene appears as closing vertical doors.
    ///
    /// - Parameter duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func doorsCloseVertical(duration: CGFloat) -> SNTransition {
        SNTransition(type: .doorsCloseVertical, duration: duration)
    }

    // MARK: - Factory Methods: Directional Transitions

    /// Creates a transition where the new scene moves in on top of the old scene.
    ///
    /// - Parameters:
    ///   - direction: The direction of the transition.
    ///   - duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func moveIn(with direction: TransitionDirection, duration: CGFloat) -> SNTransition {
        SNTransition(type: .moveIn(direction: direction), duration: duration)
    }

    /// Creates a transition where the new scene pushes the old scene out.
    ///
    /// - Parameters:
    ///   - direction: The direction of the transition.
    ///   - duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func push(with direction: TransitionDirection, duration: CGFloat) -> SNTransition {
        SNTransition(type: .push(direction: direction), duration: duration)
    }

    /// Creates a transition where the old scene moves out, revealing the new scene.
    ///
    /// - Parameters:
    ///   - direction: The direction of the transition.
    ///   - duration: The duration in seconds.
    /// - Returns: A transition object.
    public static func reveal(with direction: TransitionDirection, duration: CGFloat) -> SNTransition {
        SNTransition(type: .reveal(direction: direction), duration: duration)
    }
}
