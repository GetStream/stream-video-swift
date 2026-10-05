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
/// Video-only colors live on ``colors``. Shared typography is
/// ``tokens/fonts``.
///
/// ```swift
/// let tokens = DesignSystemTokens()
/// tokens.colors.accentPrimary = .red
/// let appearance = VideoAppearance(tokens: tokens)
/// appearance.colors.indicatorSoundIndicatorSpeaking = .green
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

    /// The images the Video SDK renders. Icons stay on the product SDK.
    public var images: Images

    /// The sounds played for incoming and outgoing calls.
    public var sounds: Sounds

    public init(
        tokens: DesignSystemTokens = DesignSystemTokens(),
        images: Images = Images(),
        sounds: Sounds = Sounds()
    ) {
        self.tokens = tokens
        self.colors = Colors(tokens: tokens)
        self.images = images
        self.sounds = sounds
    }

    /// Provider for custom localization which is dependent on App Bundle.
    public nonisolated(unsafe) static var localizationProvider: (
        _ key: String,
        _ table: String
    ) -> String = { key, table in
        Bundle.streamVideoUI.localizedString(
            forKey: key,
            value: nil,
            table: table
        )
    }
}

enum VideoAppearanceKey: InjectionKey {
    nonisolated(unsafe) static var currentValue = VideoAppearance.shared
}

extension InjectedValues {
    /// Provides access to Video's design-system appearance.
    public var videoAppearance: VideoAppearance {
        get {
            Self[VideoAppearanceKey.self]
        }
        set {
            Self[VideoAppearanceKey.self] = newValue
        }
    }

    /// Video-only colors plus every shared color token.
    ///
    /// In a file that also imports the Chat SDK, use
    /// `\.videoAppearance.colors` or `\.videoAppearance.tokens.colors`.
    public var colors: VideoAppearance.Colors {
        get { videoAppearance.colors }
        set { videoAppearance.colors = newValue }
    }

    /// The images the Video SDK renders.
    ///
    /// In a file that also imports the Chat SDK, use
    /// `\.videoAppearance.images`.
    public var images: Images {
        get { videoAppearance.images }
        set { videoAppearance.images = newValue }
    }

    /// Shared typography tokens.
    ///
    /// In a file that also imports the Chat SDK, use
    /// `\.videoAppearance.tokens.fonts`.
    public var fonts: DesignSystemTokens.Fonts {
        get { videoAppearance.tokens.fonts }
        set { videoAppearance.tokens.fonts = newValue }
    }

    /// Shared spacing, radius, stroke, and elevation tokens.
    ///
    /// In a file that also imports the Chat SDK, use
    /// `\.videoAppearance.tokens.layout`.
    public var layout: DesignSystemTokens.Layout {
        get { videoAppearance.tokens.layout }
        set { videoAppearance.tokens.layout = newValue }
    }
}
