/// The audio system for queueing sound playback.
///
/// Audio is a SIDE EFFECT of simulation - it does not affect game state.
/// This system only enqueues commands; actual playback happens in the runtime
/// (JavaScript WebAudio API on Web, AVAudioEngine on macOS).
///
/// ## Design Philosophy
/// - Swift describes WHAT sound should play and WHEN
/// - Runtime (JS/Native) handles HOW to play
/// - No callbacks from audio to game logic
/// - Deterministic simulation unaffected by audio timing
///
/// ## Usage
/// ```swift
/// // Play a sound effect
/// scene.audio.play(Sounds.explosion)
///
/// // Play with options
/// scene.audio.play(Sounds.coin, volume: 0.8, pan: -0.5)
///
/// // Play background music (looping)
/// scene.audio.playMusic(Sounds.bgmLevel1)
///
/// // Stop music with fade
/// scene.audio.stopMusic(fadeDuration: 1.0)
///
/// // Crossfade to new music
/// scene.audio.playMusic(Sounds.bgmBoss, fadeDuration: 2.0)
/// ```
public struct AudioSystem: Sendable {
    /// The command buffer for this frame.
    internal var buffer: AudioCommandBuffer = AudioCommandBuffer()

    /// Creates a new audio system.
    public init() {}

    // MARK: - Sound Effects

    /// Plays a sound effect.
    ///
    /// Sound effects use the SFX channel and can overlap freely.
    /// They do not loop by default.
    ///
    /// - Parameters:
    ///   - soundID: The sound to play.
    ///   - volume: Volume level (0.0 to 1.0). Default is 1.0.
    ///   - pitch: Playback speed multiplier. Default is 1.0.
    ///   - pan: Stereo position (-1 to 1). Default is 0.0 (center).
    public mutating func play(
        _ soundID: UInt16,
        volume: Float = 1.0,
        pitch: Float = 1.0,
        pan: Float = 0.0
    ) {
        buffer.append(AudioCommand(
            type: .play,
            soundID: soundID,
            channel: AudioChannel.sfx,
            volume: clamp(volume, 0, 1),
            pitch: max(0.1, pitch),
            pan: clamp(pan, -1, 1),
            loops: false,
            fadeDuration: 0
        ))
    }

    // MARK: - Music

    /// Plays background music.
    ///
    /// Music plays on the music channel (channel 1).
    /// Only one music track can play at a time.
    /// Playing new music automatically stops the previous track.
    ///
    /// - Parameters:
    ///   - soundID: The music to play.
    ///   - volume: Volume level (0.0 to 1.0). Default is 1.0.
    ///   - fadeDuration: Fade-in duration in seconds. Default is 0.
    public mutating func playMusic(
        _ soundID: UInt16,
        volume: Float = 1.0,
        fadeDuration: Float = 0
    ) {
        buffer.append(AudioCommand(
            type: .play,
            soundID: soundID,
            channel: AudioChannel.music,
            volume: clamp(volume, 0, 1),
            pitch: 1.0,
            pan: 0.0,
            loops: true,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Stops the background music.
    ///
    /// - Parameter fadeDuration: Fade-out duration in seconds. Default is 0.
    public mutating func stopMusic(fadeDuration: Float = 0) {
        buffer.append(AudioCommand(
            type: .stop,
            soundID: 0,
            channel: AudioChannel.music,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Sets the music volume.
    ///
    /// - Parameters:
    ///   - volume: The target volume (0.0 to 1.0).
    ///   - fadeDuration: Duration to reach target volume. Default is 0.
    public mutating func setMusicVolume(_ volume: Float, fadeDuration: Float = 0) {
        buffer.append(AudioCommand(
            type: .setVolume,
            soundID: 0,
            channel: AudioChannel.music,
            volume: clamp(volume, 0, 1),
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    // MARK: - Ambient

    /// Plays ambient sound.
    ///
    /// Ambient sounds play on the ambient channel (channel 2).
    /// Only one ambient track can play at a time.
    ///
    /// - Parameters:
    ///   - soundID: The ambient sound to play.
    ///   - volume: Volume level (0.0 to 1.0). Default is 1.0.
    ///   - fadeDuration: Fade-in duration in seconds. Default is 0.
    public mutating func playAmbient(
        _ soundID: UInt16,
        volume: Float = 1.0,
        fadeDuration: Float = 0
    ) {
        buffer.append(AudioCommand(
            type: .play,
            soundID: soundID,
            channel: AudioChannel.ambient,
            volume: clamp(volume, 0, 1),
            pitch: 1.0,
            pan: 0.0,
            loops: true,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Stops the ambient sound.
    ///
    /// - Parameter fadeDuration: Fade-out duration in seconds. Default is 0.
    public mutating func stopAmbient(fadeDuration: Float = 0) {
        buffer.append(AudioCommand(
            type: .stop,
            soundID: 0,
            channel: AudioChannel.ambient,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    // MARK: - Generic Channel Control

    /// Plays a sound on a specific channel.
    ///
    /// Non-zero channels only allow one sound at a time.
    /// Playing a new sound on a channel stops the previous one.
    ///
    /// - Parameters:
    ///   - soundID: The sound to play.
    ///   - channel: The channel to use.
    ///   - volume: Volume level (0.0 to 1.0).
    ///   - pitch: Playback speed multiplier.
    ///   - pan: Stereo position (-1 to 1).
    ///   - loops: Whether to loop the sound.
    ///   - fadeDuration: Fade-in duration in seconds.
    public mutating func play(
        _ soundID: UInt16,
        on channel: UInt8,
        volume: Float = 1.0,
        pitch: Float = 1.0,
        pan: Float = 0.0,
        loops: Bool = false,
        fadeDuration: Float = 0
    ) {
        buffer.append(AudioCommand(
            type: .play,
            soundID: soundID,
            channel: channel,
            volume: clamp(volume, 0, 1),
            pitch: max(0.1, pitch),
            pan: clamp(pan, -1, 1),
            loops: loops,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Stops sound on a channel.
    ///
    /// - Parameters:
    ///   - channel: The channel to stop.
    ///   - fadeDuration: Fade-out duration in seconds.
    public mutating func stop(channel: UInt8, fadeDuration: Float = 0) {
        buffer.append(AudioCommand(
            type: .stop,
            soundID: 0,
            channel: channel,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Sets the volume of a channel.
    ///
    /// - Parameters:
    ///   - volume: The target volume (0.0 to 1.0).
    ///   - channel: The channel to adjust.
    ///   - fadeDuration: Duration to reach target volume.
    public mutating func setVolume(
        _ volume: Float,
        channel: UInt8,
        fadeDuration: Float = 0
    ) {
        buffer.append(AudioCommand(
            type: .setVolume,
            soundID: 0,
            channel: channel,
            volume: clamp(volume, 0, 1),
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    /// Stops all sounds.
    ///
    /// - Parameter fadeDuration: Fade-out duration in seconds.
    public mutating func stopAll(fadeDuration: Float = 0) {
        buffer.append(AudioCommand(
            type: .stopAll,
            soundID: 0,
            channel: 0,
            volume: 0,
            pitch: 1.0,
            pan: 0.0,
            loops: false,
            fadeDuration: max(0, fadeDuration)
        ))
    }

    // MARK: - Internal

    /// Clears the command buffer. Called at frame start.
    internal mutating func beginFrame() {
        buffer.clear()
    }

    /// Returns the commands for this frame.
    ///
    /// The buffer is NOT cleared - call `beginFrame()` at frame start.
    public var commands: [AudioCommand] {
        buffer.commands
    }

    /// Returns and clears the commands.
    internal mutating func consumeCommands() -> [AudioCommand] {
        let result = buffer.commands
        buffer.clear()
        return result
    }

    /// Whether there are any commands this frame.
    public var hasCommands: Bool {
        !buffer.isEmpty
    }

    // MARK: - Helpers

    private func clamp(_ value: Float, _ min: Float, _ max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }
}
