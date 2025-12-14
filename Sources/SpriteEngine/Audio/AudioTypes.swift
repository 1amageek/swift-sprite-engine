/// The type of audio command.
///
/// Commands are collected per frame and sent to the audio runtime.
/// Swift does not execute audio - it only describes intent.
public enum AudioCommandType: UInt8, Sendable {
    /// Play a sound (one-shot or looping).
    case play = 0
    /// Stop a sound on a channel.
    case stop = 1
    /// Change volume (with optional fade).
    case setVolume = 2
    /// Stop all sounds.
    case stopAll = 3
    /// Set the master volume for all audio.
    case setMasterVolume = 4
    /// Pause all audio playback.
    case pauseAll = 5
    /// Resume all paused audio.
    case resumeAll = 6
}

/// A command describing an audio operation.
///
/// This is POD (Plain Old Data) - no references, no callbacks, no strings.
/// Commands are collected per frame and sent to the audio runtime.
///
/// ## Memory Layout (32 bytes, WASM-aligned)
/// ```
/// Offset | Size | Field
/// -------|------|-------------
///   0    |  1   | type (UInt8)
///   1    |  1   | channel (UInt8)
///   2    |  2   | soundID (UInt16)
///   4    |  4   | volume (Float32)
///   8    |  4   | pitch (Float32)
///  12    |  4   | pan (Float32)
///  16    |  1   | loops (UInt8: 0 or 1)
///  17    |  3   | padding
///  20    |  4   | fadeDuration (Float32)
///  24    |  8   | padding (align to 32)
/// ```
public struct AudioCommand: Sendable {
    // MARK: - Command Type

    /// The type of operation.
    public var type: AudioCommandType

    // MARK: - Sound Identification

    /// The sound to play (index into preloaded sound array).
    /// Ignored for stop/setVolume commands.
    public var soundID: UInt16

    /// The channel to use.
    ///
    /// - Channel 0: Sound effects (auto-managed, can overlap unlimited)
    /// - Channel 1+: Named channels for BGM (only one sound at a time)
    public var channel: UInt8

    // MARK: - Playback Parameters

    /// Volume level (0.0 to 1.0).
    public var volume: Float

    /// Playback speed/pitch multiplier (1.0 = normal).
    public var pitch: Float

    /// Stereo pan (-1.0 = left, 0.0 = center, 1.0 = right).
    public var pan: Float

    /// Whether to loop (for BGM).
    public var loops: Bool

    // MARK: - Fade Parameters

    /// Duration of volume fade in seconds (0 = immediate).
    public var fadeDuration: Float

    // MARK: - Initialization

    /// Creates an audio command.
    public init(
        type: AudioCommandType,
        soundID: UInt16 = 0,
        channel: UInt8 = 0,
        volume: Float = 1.0,
        pitch: Float = 1.0,
        pan: Float = 0.0,
        loops: Bool = false,
        fadeDuration: Float = 0
    ) {
        self.type = type
        self.soundID = soundID
        self.channel = channel
        self.volume = volume
        self.pitch = pitch
        self.pan = pan
        self.loops = loops
        self.fadeDuration = fadeDuration
    }
}

/// Collects audio commands for a single frame.
///
/// Cleared at the start of each frame.
/// Consumed by the audio runtime after the update loop.
///
/// ## Usage
/// ```swift
/// var buffer = AudioCommandBuffer()
/// buffer.append(AudioCommand(type: .play, soundID: 0))
/// // ... end of frame ...
/// let commands = buffer.commands
/// buffer.clear()
/// ```
public struct AudioCommandBuffer: Sendable {
    /// The commands to execute this frame.
    public private(set) var commands: [AudioCommand] = []

    /// Creates an empty command buffer.
    public init() {}

    /// Adds a command to the buffer.
    ///
    /// - Parameter command: The command to add.
    public mutating func append(_ command: AudioCommand) {
        commands.append(command)
    }

    /// Clears all commands.
    public mutating func clear() {
        commands.removeAll(keepingCapacity: true)
    }

    /// Whether the buffer is empty.
    public var isEmpty: Bool {
        commands.isEmpty
    }

    /// The number of commands in the buffer.
    public var count: Int {
        commands.count
    }
}

/// Well-known audio channel identifiers.
///
/// Channels separate different types of audio:
/// - SFX channel (0) allows unlimited overlapping sounds
/// - Music channels (1+) only play one sound at a time
public enum AudioChannel {
    /// Sound effects channel. Sounds can overlap freely.
    public static let sfx: UInt8 = 0

    /// Primary music channel.
    public static let music: UInt8 = 1

    /// Secondary music / ambient sounds channel.
    public static let ambient: UInt8 = 2

    /// Voice / dialog channel.
    public static let voice: UInt8 = 3
}
