/// Determines how a scene is scaled to fit the view.
public enum ScaleMode: Sendable {
    /// Stretches the scene to exactly match view dimensions.
    /// Content may appear distorted if aspect ratios differ.
    case fill

    /// Scales the scene uniformly to fit within the view.
    /// Black bars may appear (letterboxing).
    case aspectFit

    /// Scales the scene uniformly to fill the view completely.
    /// Content may be cropped.
    case aspectFill

    /// The scene size changes to match the view size exactly.
    /// No scaling is applied; scene coordinates match view coordinates.
    case resizeFill
}
