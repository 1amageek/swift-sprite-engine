/// The direction in which a scene transition is performed.
///
/// Used with transitions that have a directional component,
/// such as push or reveal transitions.
public enum TransitionDirection: Int, Hashable, Sendable {
    /// The transition goes upward.
    case up = 0

    /// The transition goes downward.
    case down = 1

    /// The transition goes to the right.
    case right = 2

    /// The transition goes to the left.
    case left = 3
}
