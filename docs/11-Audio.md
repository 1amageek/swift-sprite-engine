# Audio

## Overview

The Wisp audio system uses a **command-based architecture**. Swift describes WHAT sound should play and WHEN. The runtime (JavaScript WebAudio or native AVAudioEngine) handles HOW to play.

Audio is a **side effect** of simulation - it does not affect game state. This ensures deterministic simulation regardless of audio timing or failures.

## Design Philosophy

### Key Principles

1. **Swift describes, runtime plays** - No actual audio playback in Swift
2. **Commands are POD** - Plain Old Data, no strings, no callbacks
3. **Numeric IDs only** - Sound files referenced by UInt16 indices
4. **Per-frame buffer** - Commands collected each frame, consumed by runtime
5. **Deterministic** - Audio timing doesn't affect game logic

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Game Code (Swift)                   │
│              scene.audio.play(SoundIDs.explosion)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AudioSystem (Swift)                     │
│                  Collects AudioCommand[]                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   AudioCommand Buffer                       │
│            POD data: soundID, channel, volume, etc.         │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   WebAudio (JavaScript) │     │   AVAudioEngine (macOS) │
│      Browser Runtime    │     │     Native Runtime      │
└─────────────────────────┘     └─────────────────────────┘
```

## AudioEngine

The `AudioEngine` provides master control over all audio playback in a scene. It's similar to SpriteKit's `AVAudioEngine` integration.

```swift
// Access the audio engine
let engine = scene.audioEngine

// Control master volume
engine.mainMixerNode.outputVolume = 0.5  // Reduce all audio to 50%

// Pause all audio
engine.pause()

// Resume audio
engine.start()

// Stop all audio completely
engine.stop()
```

### Listener (Positional Audio)

Set the `listener` property to enable 2D positional audio mixing:

```swift
// Set camera as listener for positional audio
scene.listener = scene.camera

// Or use the player node
scene.listener = player
```

When a listener is set, audio from nodes will be mixed based on their distance from the listener. Audio from nodes further away will be quieter.

## AudioSystem

The `AudioSystem` struct is accessed through `scene.audio`.

### Sound Effects

Play one-shot sounds on the SFX channel (channel 0). Multiple sounds can overlap.

```swift
// Basic playback
scene.audio.play(SoundIDs.explosion)

// With parameters
scene.audio.play(
    SoundIDs.coin,
    volume: 0.8,    // 0.0 to 1.0
    pitch: 1.2,     // playback speed (1.0 = normal)
    pan: -0.5       // stereo position (-1 left, 0 center, 1 right)
)
```

### Background Music

Play looping music on the music channel (channel 1). Only one music track at a time.

```swift
// Start music
scene.audio.playMusic(SoundIDs.bgmLevel1)

// With fade-in
scene.audio.playMusic(SoundIDs.bgmBoss, volume: 0.7, fadeDuration: 2.0)

// Stop music
scene.audio.stopMusic()

// Stop with fade-out
scene.audio.stopMusic(fadeDuration: 1.0)

// Crossfade to new music (stops current, fades in new)
scene.audio.playMusic(SoundIDs.bgmVictory, fadeDuration: 2.0)

// Adjust volume
scene.audio.setMusicVolume(0.5, fadeDuration: 0.5)
```

### Ambient Sounds

Play looping ambient sounds on the ambient channel (channel 2).

```swift
// Start ambient
scene.audio.playAmbient(SoundIDs.forestAmbience)

// Stop ambient
scene.audio.stopAmbient(fadeDuration: 1.0)
```

### Generic Channel Control

For advanced use cases, control any channel directly.

```swift
// Play on specific channel
scene.audio.play(
    SoundIDs.voice1,
    on: AudioChannel.voice,
    volume: 1.0,
    loops: false,
    fadeDuration: 0
)

// Stop a channel
scene.audio.stop(channel: AudioChannel.voice, fadeDuration: 0.5)

// Set channel volume
scene.audio.setVolume(0.5, channel: AudioChannel.music, fadeDuration: 1.0)

// Stop all audio
scene.audio.stopAll(fadeDuration: 0.5)
```

## Channels

Audio channels separate different types of audio:

| Channel | ID | Behavior |
|---------|----|-----------|
| `AudioChannel.sfx` | 0 | Sound effects. Unlimited overlapping sounds. |
| `AudioChannel.music` | 1 | Background music. One track at a time. |
| `AudioChannel.ambient` | 2 | Ambient/environmental. One track at a time. |
| `AudioChannel.voice` | 3 | Voice/dialog. One track at a time. |

- **Channel 0 (SFX)**: Fire-and-forget sounds, can overlap freely
- **Channel 1+ (Named)**: Exclusive channels, playing new sound stops previous

## AudioCommand

Commands are POD (Plain Old Data) with no strings or callbacks:

```swift
struct AudioCommand {
    var type: AudioCommandType    // play, stop, setVolume, stopAll
    var soundID: UInt16           // index into preloaded sound array
    var channel: UInt8            // target channel
    var volume: Float             // 0.0 to 1.0
    var pitch: Float              // playback speed multiplier
    var pan: Float                // -1.0 to 1.0
    var loops: Bool               // whether to loop
    var fadeDuration: Float       // fade time in seconds
}
```

### Memory Layout (WASM-aligned)

```
Offset | Size | Field
-------|------|-------------
  0    |  1   | type (UInt8)
  1    |  1   | channel (UInt8)
  2    |  2   | soundID (UInt16)
  4    |  4   | volume (Float32)
  8    |  4   | pitch (Float32)
 12    |  4   | pan (Float32)
 16    |  1   | loops (UInt8: 0 or 1)
 17    |  3   | padding
 20    |  4   | fadeDuration (Float32)
 24    |  8   | padding (align to 32)
```

## Sound ID Registration

Sounds are referenced by numeric IDs, not strings. Define constants:

```swift
enum SoundIDs {
    static let explosion: UInt16 = 0
    static let coin: UInt16 = 1
    static let jump: UInt16 = 2
    static let bgmLevel1: UInt16 = 100
    static let bgmBoss: UInt16 = 101
}
```

The runtime must preload sounds and map these IDs to actual audio files.

## Frame Cycle Integration

Audio commands are collected during the frame and consumed after:

```
Frame Start
    │
    ├── audio.beginFrame()      ← Buffer cleared
    │
    ├── update(dt:)             ← Game logic calls audio.play(), etc.
    │
    ├── didEvaluateActions()
    │
    ├── didSimulatePhysics()
    │
    ├── didFinishUpdate()
    │
Frame End
    │
    └── runtime.processAudio(scene.audio.commands)  ← Commands consumed
```

## Runtime Implementation (JavaScript)

The JavaScript runtime consumes `AudioCommand[]` after each frame:

```javascript
class AudioRuntime {
    constructor(audioContext, soundBank) {
        this.ctx = audioContext;
        this.sounds = soundBank;  // Map<number, AudioBuffer>
        this.channels = new Map(); // Active sounds per channel
    }

    processCommands(commands) {
        for (const cmd of commands) {
            switch (cmd.type) {
                case 0: // play
                    this.play(cmd);
                    break;
                case 1: // stop
                    this.stop(cmd.channel, cmd.fadeDuration);
                    break;
                case 2: // setVolume
                    this.setVolume(cmd.channel, cmd.volume, cmd.fadeDuration);
                    break;
                case 3: // stopAll
                    this.stopAll(cmd.fadeDuration);
                    break;
            }
        }
    }

    play(cmd) {
        const buffer = this.sounds.get(cmd.soundID);
        if (!buffer) return;

        const source = this.ctx.createBufferSource();
        source.buffer = buffer;
        source.playbackRate.value = cmd.pitch;
        source.loop = cmd.loops;

        const gainNode = this.ctx.createGain();
        gainNode.gain.value = cmd.fadeDuration > 0 ? 0 : cmd.volume;

        const panNode = this.ctx.createStereoPanner();
        panNode.pan.value = cmd.pan;

        source.connect(panNode);
        panNode.connect(gainNode);
        gainNode.connect(this.ctx.destination);

        // Fade in
        if (cmd.fadeDuration > 0) {
            gainNode.gain.linearRampToValueAtTime(
                cmd.volume,
                this.ctx.currentTime + cmd.fadeDuration
            );
        }

        source.start();

        // Track on channel (for non-SFX channels)
        if (cmd.channel > 0) {
            this.stopChannel(cmd.channel);
            this.channels.set(cmd.channel, { source, gainNode });
        }
    }
}
```

## Usage Examples

### Playing Sound on Collision

```swift
class GameScene: Scene {
    override func didSimulatePhysics() {
        for contact in physicsWorld.contacts {
            if contact.bodyA.categoryBitMask == Category.player &&
               contact.bodyB.categoryBitMask == Category.coin {
                audio.play(SoundIDs.coin)
            }
        }
    }
}
```

### Dynamic Audio Based on Game State

```swift
class GameScene: Scene {
    var isBossFight = false

    func startBossFight() {
        isBossFight = true
        audio.playMusic(SoundIDs.bgmBoss, fadeDuration: 2.0)
    }

    override func update(dt: Float) {
        // Adjust music volume based on player health
        let healthRatio = player.health / player.maxHealth
        audio.setMusicVolume(0.5 + healthRatio * 0.5)
    }
}
```

### Positional Audio (Manual Pan)

```swift
class GameScene: Scene {
    override func update(dt: Float) {
        // Pan based on enemy position relative to camera
        for enemy in enemies {
            let screenX = (enemy.position.x - camera!.position.x) / (size.width / 2)
            let pan = max(-1, min(1, screenX))
            audio.play(SoundIDs.enemyGrowl, pan: pan)
        }
    }
}
```

## SpriteKit Comparison

| SpriteKit | Wisp |
|-----------|------|
| `SKScene.audioEngine` | `scene.audioEngine` ✓ |
| `SKScene.listener` | `scene.listener` ✓ |
| `audioEngine.mainMixerNode.outputVolume` | `audioEngine.mainMixerNode.outputVolume` ✓ |
| `audioEngine.pause()` | `audioEngine.pause()` ✓ |
| `SKAudioNode` | `scene.audio` |
| `playSoundFileNamed()` action | `audio.play(soundID)` |
| String-based file names | Numeric sound IDs |
| Node-based positional audio | Manual pan calculation |
| Callback on completion | No callbacks (fire-and-forget) |

## Design Notes

### Why No Strings?

Strings cannot cross the Swift/JavaScript boundary efficiently. Using numeric IDs:
- Enables direct memory sharing between WASM and JS
- Avoids string allocation/deallocation overhead
- Maintains determinism (no string hashing variability)

### Why No Callbacks?

Audio completion callbacks would:
- Break determinism (timing varies by device/browser)
- Require complex cross-boundary communication
- Add state that affects simulation

Instead, track audio state in game logic if needed:
```swift
var explosionStartTime: Float = 0

func playExplosion() {
    audio.play(SoundIDs.explosion)
    explosionStartTime = currentTime
}

func update(dt: Float) {
    // Assume explosion lasts 0.5 seconds
    if currentTime - explosionStartTime > 0.5 {
        // Explosion finished
    }
}
```

### Why Command Buffer?

Collecting commands per frame:
- Allows runtime to batch audio operations
- Separates simulation from side effects
- Enables audio processing on a different thread/timing
- Makes testing easier (inspect commands without playing audio)
