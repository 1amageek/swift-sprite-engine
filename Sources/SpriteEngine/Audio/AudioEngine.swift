/// The audio engine used to play audio from audio nodes contained in the scene.
///
/// `AudioEngine` provides master control over all audio playback in a scene.
/// It wraps the `AudioSystem` command buffer and provides a SpriteKit-like API
/// for controlling overall audio behavior.
///
/// ## Usage
/// ```swift
/// // Reduce the overall volume
/// scene.audioEngine.mainMixerNode.outputVolume = 0.5
///
/// // Pause all audio
/// scene.audioEngine.pause()
///
/// // Resume audio
/// scene.audioEngine.resume()
/// ```
///
/// ## Platform Notes
/// - **Web**: Audio is handled by the JavaScript WebAudio API
/// - **Native Preview**: Audio commands are collected but not played
///
/// The actual audio playback is handled by the runtime after the frame update.
public final class AudioEngine: @unchecked Sendable {
    // MARK: - Properties

    /// The main mixer node providing master volume control.
    public let mainMixerNode: AudioMixerNode

    /// Whether the audio engine is currently running.
    public private(set) var isRunning: Bool = true

    /// The audio system that queues commands.
    internal var audioSystem: AudioSystem

    // MARK: - Initialization

    /// Creates a new audio engine.
    internal init() {
        self.mainMixerNode = AudioMixerNode()
        self.audioSystem = AudioSystem()
    }

    // MARK: - Engine Control

    /// Starts the audio engine.
    ///
    /// Audio playback resumes if it was previously paused.
    public func start() {
        isRunning = true
        audioSystem.setMasterVolume(mainMixerNode.outputVolume)
    }

    /// Pauses the audio engine.
    ///
    /// All audio playback is temporarily suspended. Call `start()` to resume.
    public func pause() {
        isRunning = false
        audioSystem.pauseAll()
    }

    /// Stops the audio engine and all playing audio.
    ///
    /// Unlike `pause()`, this stops all audio completely.
    public func stop() {
        isRunning = false
        audioSystem.stopAll()
    }

    /// Resets the audio engine to its initial state.
    public func reset() {
        audioSystem.stopAll()
        mainMixerNode.outputVolume = 1.0
        isRunning = true
    }

    // MARK: - Internal

    /// Clears the command buffer. Called at frame start.
    internal func beginFrame() {
        audioSystem.beginFrame()
    }

    /// Returns and clears the pending audio commands.
    internal func consumeCommands() -> [AudioCommand] {
        audioSystem.consumeCommands()
    }

    /// Whether there are any pending commands.
    internal var hasCommands: Bool {
        audioSystem.hasCommands
    }
}

// MARK: - AudioMixerNode

/// Represents the main mixer node for audio output control.
///
/// The mixer node provides master volume control for all audio
/// played through the audio engine.
public final class AudioMixerNode: @unchecked Sendable {
    /// The output volume level (0.0 to 1.0).
    ///
    /// Setting this value affects the volume of all audio played
    /// through the audio engine.
    ///
    /// - Note: Default value is 1.0 (full volume).
    public var outputVolume: Float = 1.0 {
        didSet {
            outputVolume = max(0, min(1, outputVolume))
        }
    }

    /// Creates a new mixer node with default settings.
    internal init() {}
}

// MARK: - AudioSystem Extensions

extension AudioSystem {
    /// Sets the master volume for all audio.
    internal mutating func setMasterVolume(_ volume: Float) {
        buffer.append(AudioCommand(
            type: .setMasterVolume,
            soundID: 0,
            channel: 0,
            volume: max(0, min(1, volume)),
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: 0
        ))
    }

    /// Pauses all audio playback.
    internal mutating func pauseAll() {
        buffer.append(AudioCommand(
            type: .pauseAll,
            soundID: 0,
            channel: 0,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: 0
        ))
    }

    /// Resumes all paused audio.
    internal mutating func resumeAll() {
        buffer.append(AudioCommand(
            type: .resumeAll,
            soundID: 0,
            channel: 0,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: 0
        ))
    }
}
