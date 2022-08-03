//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

/// An object containing visual configuration for the whole application.
public class Appearance {
    public var colors: Colors
    public var images: Images
    public var fonts: Fonts
    
    public init(
        colors: Colors = Colors(),
        images: Images = Images(),
        fonts: Fonts = Fonts()
    ) {
        self.colors = colors
        self.images = images
        self.fonts = fonts
    }
    
    /// Provider for custom localization which is dependent on App Bundle.
    public static var localizationProvider: (_ key: String, _ table: String) -> String = { key, table in
        Bundle.streamVideoUI.localizedString(forKey: key, value: nil, table: table)
    }
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}

/// Provides the default value of the `Appearance` class.
public struct AppearanceKey: InjectionKey {
    public static var currentValue: Appearance = Appearance()
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
}
