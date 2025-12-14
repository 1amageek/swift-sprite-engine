# Input

## Overview

Wisp uses a **polling-based** input model. Input state is read from JavaScript each frame and provided to Swift as a simple struct.

There are no events, callbacks, or input queues. The current state of all inputs is available during `update(dt:)`.

## InputState

### Definition

```swift
struct InputState: Equatable, Sendable {
    // Digital directional inputs
    var up: Bool = false
    var down: Bool = false
    var left: Bool = false
    var right: Bool = false

    // Action buttons
    var action: Bool = false
    var action2: Bool = false
    var pause: Bool = false

    // Pointer (mouse/touch)
    var pointerPosition: Vec2? = nil
    var pointerDown: Bool = false
    var pointerJustPressed: Bool = false
    var pointerJustReleased: Bool = false
}
```

## Digital Inputs

### Directional

```swift
var up: Bool      // W, Arrow Up, D-Pad Up
var down: Bool    // S, Arrow Down, D-Pad Down
var left: Bool    // A, Arrow Left, D-Pad Left
var right: Bool   // D, Arrow Right, D-Pad Right
```

### Action Buttons

```swift
var action: Bool   // Space, Enter, Gamepad A
var action2: Bool  // Shift, Gamepad B
var pause: Bool    // Escape, Gamepad Start
```

## Pointer Input

### pointerPosition

Current position of the mouse cursor or touch point in **view coordinates**.

```swift
var pointerPosition: Vec2?
```

- `nil` when no pointer is active (mouse outside window, no touch)
- For touch, this is the primary touch point
- For mouse, this is the cursor position

### pointerDown

Whether the primary pointer button is currently pressed.

```swift
var pointerDown: Bool
```

- Mouse: Left button is held
- Touch: Finger is touching screen

### Just Pressed/Released

Edge detection for pointer events:

```swift
var pointerJustPressed: Bool   // True only on the frame press began
var pointerJustReleased: Bool  // True only on the frame press ended
```

## Usage in Scene

Input is accessed through a global or passed to the scene:

```swift
class GameScene: Scene {
    override func update(dt: Float) {
        // Directional movement
        var velocity = Vec2.zero

        if input.left { velocity.x -= 1 }
        if input.right { velocity.x += 1 }
        if input.up { velocity.y += 1 }
        if input.down { velocity.y -= 1 }

        if velocity != .zero {
            velocity = velocity.normalized * playerSpeed
            player.position += velocity * dt
        }

        // Jump on action press
        if input.action && isGrounded {
            playerVelocity.y = jumpForce
        }

        // Pause toggle
        if input.pause {
            showPauseMenu()
        }
    }
}
```

## Pointer Handling

### Screen to World Conversion

Pointer position is in view coordinates. Convert to scene/world coordinates:

```swift
if let screenPos = input.pointerPosition {
    let worldPos = scene.convertPoint(fromView: screenPos)

    // Check if clicked on something
    if enemy.frame.contains(worldPos) {
        enemy.takeDamage()
    }
}
```

### Drag Operations

```swift
var isDragging = false
var dragOffset = Vec2.zero

override func update(dt: Float) {
    guard let pointerPos = input.pointerPosition else { return }
    let worldPos = convertPoint(fromView: pointerPos)

    if input.pointerJustPressed {
        if player.frame.contains(worldPos) {
            isDragging = true
            dragOffset = player.position - worldPos
        }
    }

    if isDragging {
        player.position = worldPos + dragOffset
    }

    if input.pointerJustReleased {
        isDragging = false
    }
}
```

### Tap Detection

```swift
var tapStartTime: Float = 0
let tapMaxDuration: Float = 0.3

override func update(dt: Float) {
    if input.pointerJustPressed {
        tapStartTime = currentTime
    }

    if input.pointerJustReleased {
        let duration = currentTime - tapStartTime
        if duration < tapMaxDuration {
            handleTap(at: input.pointerPosition!)
        }
    }
}
```

## Keyboard Mapping (JavaScript)

The JavaScript layer maps keyboard keys to input state:

```javascript
const keyMap = {
    // Directional
    'KeyW': 'up',
    'KeyA': 'left',
    'KeyS': 'down',
    'KeyD': 'right',
    'ArrowUp': 'up',
    'ArrowLeft': 'left',
    'ArrowDown': 'down',
    'ArrowRight': 'right',

    // Actions
    'Space': 'action',
    'Enter': 'action',
    'ShiftLeft': 'action2',
    'ShiftRight': 'action2',
    'Escape': 'pause'
};

document.addEventListener('keydown', (e) => {
    const input = keyMap[e.code];
    if (input) inputState[input] = true;
});

document.addEventListener('keyup', (e) => {
    const input = keyMap[e.code];
    if (input) inputState[input] = false;
});
```

## Gamepad Support

JavaScript handles gamepad input similarly:

```javascript
function pollGamepad() {
    const gamepads = navigator.getGamepads();
    const gp = gamepads[0];
    if (!gp) return;

    // D-pad or left stick
    inputState.left = gp.buttons[14]?.pressed || gp.axes[0] < -0.5;
    inputState.right = gp.buttons[15]?.pressed || gp.axes[0] > 0.5;
    inputState.up = gp.buttons[12]?.pressed || gp.axes[1] < -0.5;
    inputState.down = gp.buttons[13]?.pressed || gp.axes[1] > 0.5;

    // Face buttons
    inputState.action = gp.buttons[0]?.pressed;   // A
    inputState.action2 = gp.buttons[1]?.pressed;  // B
    inputState.pause = gp.buttons[9]?.pressed;    // Start
}
```

## Touch Input (Mobile)

Touch events map to pointer state:

```javascript
canvas.addEventListener('touchstart', (e) => {
    const touch = e.touches[0];
    inputState.pointerPosition = { x: touch.clientX, y: touch.clientY };
    inputState.pointerDown = true;
    inputState.pointerJustPressed = true;
});

canvas.addEventListener('touchmove', (e) => {
    const touch = e.touches[0];
    inputState.pointerPosition = { x: touch.clientX, y: touch.clientY };
});

canvas.addEventListener('touchend', (e) => {
    inputState.pointerDown = false;
    inputState.pointerJustReleased = true;
});
```

## Virtual Buttons (Mobile)

For mobile games, create on-screen controls:

```swift
class VirtualDPad: Node {
    func update(input: inout InputState) {
        guard let pos = input.pointerPosition else { return }

        if input.pointerDown && bounds.contains(pos) {
            let offset = pos - center
            input.left = offset.x < -threshold
            input.right = offset.x > threshold
            input.up = offset.y > threshold
            input.down = offset.y < -threshold
        }
    }
}
```

## Input in Preview

For SwiftUI previews, simulate input:

```swift
#Preview {
    GameScenePreview()
}

struct GameScenePreview: View {
    @State private var scene = GameScene(size: Vec2(x: 800, y: 600))
    @State private var input = InputState()

    var body: some View {
        ZStack {
            PreviewRenderer().render(
                commands: scene.generateDrawCommands(),
                viewport: scene.calculateViewport()
            )

            // Debug controls
            VStack {
                Spacer()
                HStack {
                    Button("Left") { input.left = true }
                    Button("Right") { input.right = true }
                    Button("Jump") { input.action = true }
                }
            }
        }
        .onAppear {
            scene.sceneDidLoad()
        }
    }
}
```

## Design Notes

### Why Polling?

- Simpler mental model
- No event timing issues
- Deterministic (same input = same behavior)
- Matches fixed timestep philosophy

### Why No Raw Events?

- Events complicate determinism
- Polling sufficient for most games
- Raw events can be added in future if needed

### Edge Detection

`pointerJustPressed` and `pointerJustReleased` are set by comparing current and previous frame state:

```javascript
// At start of frame
inputState.pointerJustPressed = inputState.pointerDown && !prevPointerDown;
inputState.pointerJustReleased = !inputState.pointerDown && prevPointerDown;
prevPointerDown = inputState.pointerDown;
```
