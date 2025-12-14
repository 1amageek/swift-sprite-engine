/// Options for aligning text horizontally.
///
/// Used with label nodes to control horizontal text positioning
/// relative to the node's origin.
public enum LabelHorizontalAlignmentMode: Int, Hashable, Sendable {
    /// Centers the text horizontally on the node's origin.
    case center = 0

    /// Positions the text so that the left side is on the node's origin.
    case left = 1

    /// Positions the text so that the right side is on the node's origin.
    case right = 2
}

/// Options for aligning text vertically.
///
/// Used with label nodes to control vertical text positioning
/// relative to the node's origin.
public enum LabelVerticalAlignmentMode: Int, Hashable, Sendable {
    /// Positions the text so that the font's baseline lies on the node's origin.
    case baseline = 0

    /// Centers the text vertically on the node's origin.
    case center = 1

    /// Positions the text so that the top of the text is on the node's origin.
    case top = 2

    /// Positions the text so that the bottom of the text is on the node's origin.
    case bottom = 3
}
