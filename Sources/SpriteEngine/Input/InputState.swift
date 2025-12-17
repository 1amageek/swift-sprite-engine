/// The current state of all input devices.
///
/// Wisp uses a polling-based input model. This struct represents the state
/// of all inputs at the current frame. There are no events or callbacks.
///
/// ## Usage
/// ```swift
/// override func update(dt: Float) {
///     if input.left { player.position.x -= speed * dt }
///     if input.right { player.position.x += speed * dt }
///     if input.action && isGrounded { jump() }
/// }
/// ```
public struct InputState: Equatable, Sendable {
    // MARK: - Directional Inputs

    /// Up direction (W, Arrow Up, D-Pad Up).
    public var up: Bool = false

    /// Down direction (S, Arrow Down, D-Pad Down).
    public var down: Bool = false

    /// Left direction (A, Arrow Left, D-Pad Left).
    public var left: Bool = false

    /// Right direction (D, Arrow Right, D-Pad Right).
    public var right: Bool = false

    // MARK: - Action Buttons

    /// Primary action (Space, Enter, Gamepad A).
    public var action: Bool = false

    /// Secondary action (Shift, Gamepad B).
    public var action2: Bool = false

    /// Pause button (Escape, Gamepad Start).
    public var pause: Bool = false

    // MARK: - Pointer (Mouse/Touch)

    /// Current pointer position in view coordinates.
    /// `nil` when no pointer is active.
    public var pointerPosition: Point? = nil

    /// Whether the primary pointer button is held (left mouse, touch).
    public var pointerDown: Bool = false

    /// True only on the frame when the pointer was pressed.
    public var pointerJustPressed: Bool = false

    /// True only on the frame when the pointer was released.
    public var pointerJustReleased: Bool = false

    // MARK: - Initialization

    /// Creates an empty input state with all buttons released.
    public init() {}

    // MARK: - Convenience

    /// Returns a normalized direction vector from WASD/arrow inputs.
    /// Returns zero vector if no direction is pressed.
    public var direction: Vector2 {
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if left { dx -= 1 }
        if right { dx += 1 }
        if down { dy -= 1 }
        if up { dy += 1 }

        let vector = Vector2(dx: dx, dy: dy)
        return vector.isZero ? vector : vector.normalized
    }

    /// Returns `true` if any directional input is pressed.
    public var hasDirectionalInput: Bool {
        up || down || left || right
    }

    /// Returns `true` if any action button is pressed.
    public var hasActionInput: Bool {
        action || action2
    }

    /// Returns `true` if any input at all is active.
    public var hasAnyInput: Bool {
        hasDirectionalInput || hasActionInput || pause || pointerDown
    }
}

// MARK: - Edge Detection

extension InputState {
    /// Updates edge detection flags by comparing with previous state.
    ///
    /// Call this at the start of each frame with the previous frame's state.
    public mutating func updateEdgeDetection(previousPointerDown: Bool) {
        pointerJustPressed = pointerDown && !previousPointerDown
        pointerJustReleased = !pointerDown && previousPointerDown
    }

    /// Clears edge detection flags. Call at the end of each frame.
    public mutating func clearEdgeFlags() {
        pointerJustPressed = false
        pointerJustReleased = false
    }
}

// MARK: - CustomStringConvertible

extension InputState: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []

        if up { parts.append("up") }
        if down { parts.append("down") }
        if left { parts.append("left") }
        if right { parts.append("right") }
        if action { parts.append("action") }
        if action2 { parts.append("action2") }
        if pause { parts.append("pause") }
        if pointerDown { parts.append("pointer") }

        return "InputState(\(parts.joined(separator: ", ")))"
    }
}

// MARK: - Codable

extension InputState: Codable {}
