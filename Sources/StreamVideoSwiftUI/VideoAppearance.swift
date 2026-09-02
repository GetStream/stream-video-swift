//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@_exported import StreamCoreUI
import StreamVideo
import SwiftUI

/// Video design-system configuration.
///
/// Shared color and layout tokens come from ``DesignSystemTokens``. Pass
/// the same instance into Chat's appearance so both SDKs reskin together.
/// Video-only colors live on ``colors``. Existing views still use
/// ``Appearance`` until they migrate.
///
/// ```swift
/// let tokens = DesignSystemTokens()
/// tokens.colors.accentPrimary = .red
/// let appearance = VideoAppearance(tokens: tokens)
/// appearance.colors.indicatorSpeaking = .green
/// ```
public final class VideoAppearance {
    /// The instance the Video SDK uses unless it is given another one.
    ///
    /// Not synchronized. This is a process-wide UI configuration object.
    public nonisolated(unsafe) static let shared = VideoAppearance()

    /// Shared color and layout tokens. Mutating this instance is visible
    /// to any other appearance constructed with it.
    public let tokens: DesignSystemTokens

    /// Video-specific colors, derived from ``tokens``.
    public var colors: Colors

    public init(tokens: DesignSystemTokens = DesignSystemTokens()) {
        self.tokens = tokens
        self.colors = Colors(tokens: tokens)
    }
}
