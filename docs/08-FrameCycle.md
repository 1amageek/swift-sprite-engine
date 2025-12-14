# Frame Cycle

## Overview

Wisp uses a **fixed timestep** game loop. Every frame, the same amount of simulation time passes (typically 1/60 second), regardless of actual elapsed time.

This ensures **deterministic** behavior: given the same inputs, the game produces identical results.

## The Game Loop

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Browser Frame                           │
│                  (requestAnimationFrame)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Poll Input (JS)                          │
│            Read keyboard, mouse, gamepad state              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Accumulator Update                          │
│              accumulator += realDeltaTime                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
         ┌────────────────────────────────────────┐
         │       while accumulator >= fixedDt     │
         │  ┌──────────────────────────────────┐  │
         │  │     scene.update(fixedDt)        │  │
         │  │     accumulator -= fixedDt       │  │
         │  └──────────────────────────────────┘  │
         └────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Generate Draw Commands                       │
│             Traverse scene graph → DrawCommand[]            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Render (JS)                            │
│                 WebGPU submit commands                      │
└─────────────────────────────────────────────────────────────┘
```

### JavaScript Implementation

```javascript
const FIXED_DT = 1 / 60;  // 60 updates per second
const MAX_FRAME_TIME = 0.25;  // Prevent spiral of death

let accumulator = 0;
let lastTime = performance.now() / 1000;

function gameLoop(currentTime) {
    currentTime /= 1000;  // Convert to seconds

    // Calculate real elapsed time
    let frameTime = currentTime - lastTime;
    lastTime = currentTime;

    // Clamp to prevent spiral of death
    if (frameTime > MAX_FRAME_TIME) {
        frameTime = MAX_FRAME_TIME;
    }

    // Add to accumulator
    accumulator += frameTime;

    // Poll input once per frame
    pollInput();

    // Fixed timestep updates
    while (accumulator >= FIXED_DT) {
        wasmScene.update(FIXED_DT);
        accumulator -= FIXED_DT;
    }

    // Generate and render
    const commands = wasmScene.generateDrawCommands();
    renderer.render(commands);

    requestAnimationFrame(gameLoop);
}

requestAnimationFrame(gameLoop);
```

## Scene Frame Cycle

### v0.1 Simplified Cycle

```
┌─────────────────────────────────────────────────────────────┐
│  1. scene.update(dt)           ← Your game logic            │
│  2. scene.didFinishUpdate()    ← Post-processing hook       │
│  3. generateDrawCommands()     ← Traverse tree              │
│  4. render()                   ← Draw to screen             │
└─────────────────────────────────────────────────────────────┘
```

### Full Cycle (Future)

```
┌─────────────────────────────────────────────────────────────┐
│  1. scene.update(dt)           ← Your game logic            │
│  2. evaluateActions()          ← Process running actions    │
│  3. scene.didEvaluateActions() ← Post-action hook           │
│  4. simulatePhysics()          ← Physics step               │
│  5. scene.didSimulatePhysics() ← Post-physics hook          │
│  6. applyConstraints()         ← Apply node constraints     │
│  7. scene.didApplyConstraints()← Post-constraint hook       │
│  8. scene.didFinishUpdate()    ← Final processing           │
│  9. generateDrawCommands()     ← Traverse tree              │
│  10. render()                  ← Draw to screen             │
└─────────────────────────────────────────────────────────────┘
```

## Fixed Timestep Benefits

### Determinism

Same inputs always produce same outputs:

```swift
// Frame 1: dt = 0.0166...
player.position.x += velocity.x * dt  // Always same result

// Frame 2: dt = 0.0166...
player.position.x += velocity.x * dt  // Always same result
```

This enables:
- Replays (store inputs, replay deterministically)
- Networking (send inputs, simulate identically)
- Testing (predictable outcomes)

### Physics Stability

Fixed timestep prevents physics explosions from variable dt:

```swift
// BAD: Variable dt
// If dt spikes to 0.5, objects teleport through walls
position += velocity * dt

// GOOD: Fixed dt
// Always small, consistent steps
position += velocity * fixedDt  // fixedDt = 1/60
```

### Frame Rate Independence

Game logic runs at constant rate regardless of display:
- 30 FPS display: 2 updates per render
- 60 FPS display: 1 update per render
- 144 FPS display: might skip some renders

## Spiral of Death

### The Problem

If updates take longer than `fixedDt`, accumulator grows infinitely:

```
Frame 1: Update takes 20ms, accumulator += 16ms, still need more updates
Frame 2: Update takes 20ms, accumulator += 16ms, falling further behind
...
```

### The Solution

Clamp maximum frame time:

```javascript
if (frameTime > MAX_FRAME_TIME) {
    frameTime = MAX_FRAME_TIME;
}
```

This causes the game to slow down rather than spiral.

## Time Access

### In Scene

```swift
class Scene {
    private(set) var currentTime: Float = 0

    func update(dt: Float) {
        currentTime += dt
        // currentTime is total elapsed simulation time
    }
}
```

### In Game Logic

```swift
override func update(dt: Float) {
    // dt is always fixedDt (e.g., 1/60)
    // Use for movement, physics, etc.
    player.position.x += velocity * dt

    // Use currentTime for time-based events
    if currentTime > nextSpawnTime {
        spawnEnemy()
        nextSpawnTime = currentTime + spawnInterval
    }
}
```

## Interpolation (Advanced)

For smooth rendering between fixed updates, interpolate using the remaining accumulator:

```javascript
// After update loop
const alpha = accumulator / FIXED_DT;

// Interpolate render positions
for (const cmd of commands) {
    cmd.renderPosition = lerp(cmd.previousPosition, cmd.position, alpha);
}
```

**Note**: v0.1 does not implement interpolation. Updates and renders are 1:1.

## Pausing

### Pause the Scene

```swift
class Scene {
    var isPaused: Bool = false

    internal func tick(dt: Float) {
        guard !isPaused else { return }
        update(dt: dt)
        // ... rest of cycle
    }
}
```

### Time Scale (Future)

```swift
class Scene {
    var timeScale: Float = 1.0  // 0.5 = half speed, 2.0 = double speed

    internal func tick(dt: Float) {
        let scaledDt = dt * timeScale
        update(dt: scaledDt)
    }
}
```

## Best Practices

### Do in update(dt:)

- Movement and physics
- Input processing
- Game state changes
- Spawning/destroying entities

### Don't in update(dt:)

- Rendering (happens automatically after)
- Heavy computations (may cause spiral)
- Blocking operations

### Use dt Correctly

```swift
// GOOD: Multiply by dt for frame-rate independence
position += velocity * dt
rotation += angularVelocity * dt

// BAD: Ignoring dt causes frame-rate dependent behavior
position += velocity  // Moves faster at higher FPS
```

### Consistent Units

- Position: points
- Velocity: points per second
- dt: seconds (1/60 ≈ 0.0166)

```swift
let speed: Float = 200  // 200 points per second
position.x += speed * dt  // Moves 200 points in 1 second
```
