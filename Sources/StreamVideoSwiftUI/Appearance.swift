//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// An object containing visual configuration for the whole application.
public class Appearance {
    public var colors: Colors
    public var images: Images
    public var fonts: Fonts
    public var sounds: Sounds
    
    public init(
        colors: Colors = Colors(),
        images: Images = Images(),
        fonts: Fonts = Fonts(),
        sounds: Sounds = Sounds()
    ) {
        self.colors = colors
        self.images = images
        self.fonts = fonts
        self.sounds = sounds
    }
    
    /// Provider for custom localization which is dependent on App Bundle.
    public nonisolated(unsafe) static var localizationProvider: (_ key: String, _ table: String) -> String = { key, table in
        Bundle.streamVideoUI.localizedString(forKey: key, value: nil, table: table)
    }
}

// MARK: - Appearance + Default

public extension Appearance {
    nonisolated(unsafe) static var `default`: Appearance = .init()
}

/// Provides the default value of the `Appearance` class.
enum AppearanceKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: Appearance = Appearance()
}

extension InjectedValues {
    /// Provides access to the `Appearance` class to the views and view models.
    public var appearance: Appearance {
        get {
            Self[AppearanceKey.self]
        }
        set {
            Self[AppearanceKey.self] = newValue
        }
    }

    /// Provides access to the `Colors` instance.
    public var colors: Colors {
        get {
            appearance.colors
        }
        set {
            appearance.colors = newValue
        }
    }

    /// Provides access to the `Images` instance.
    public var images: Images {
        get {
            appearance.images
        }
        set {
            appearance.images = newValue
        }
    }

    /// Provides access to the `Fonts` instance.
    public var fonts: Fonts {
        get {
            appearance.fonts
        }
        set {
            appearance.fonts = newValue
        }
    }

    /// Provides access to the `Sounds` instance.
    public var sounds: Sounds {
        get {
            appearance.sounds
        }
        set {
            appearance.sounds = newValue
        }
    }
}
