/// The order to use when rendering particles from an emitter.
///
/// Particle render order affects the visual stacking of particles
/// and can impact performance.
public enum SNParticleRenderOrder: UInt, Hashable, Sendable {
    /// Particles are rendered from newest to oldest.
    ///
    /// This is the default value. Newer particles appear on top
    /// of older particles.
    case oldestLast = 0

    /// Particles are rendered from oldest to newest.
    ///
    /// Older particles appear on top of newer particles.
    case oldestFirst = 1

    /// Particles can be rendered in any order.
    ///
    /// The engine may reorder particles to improve rendering performance.
    /// Use this when particle stacking order doesn't matter visually.
    case dontCare = 2
}
