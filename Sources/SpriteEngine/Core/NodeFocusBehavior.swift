/// Options for the focusable states of a node.
///
/// Focus behavior determines whether a node can receive focus
/// and how it affects focus navigation.
public enum NodeFocusBehavior: Int, Hashable, Sendable {
    /// Node is not focusable.
    ///
    /// The node cannot receive focus and does not affect
    /// the focusability of other nodes.
    case none = 0

    /// Node is not focusable but prevents nodes it visually
    /// obscures from becoming focusable.
    ///
    /// Use this for overlay elements that should block focus
    /// to elements behind them.
    case occluding = 1

    /// Node is focusable and prevents nodes it visually
    /// obscures from becoming focusable.
    ///
    /// This is the typical behavior for interactive elements.
    case focusable = 2
}
