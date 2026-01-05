//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
#if canImport(UIKit)
import UIKit
#endif

/// Protocol for navigation to external URLs and system settings.
public protocol URLNavigating {
    
    /// Opens the app's settings page in the system Settings app.
    /// - Throws: An error if the settings cannot be opened.
    @MainActor
    func openSettings() throws
}

enum URLNavigatingKey: InjectionKey {
    public nonisolated(unsafe) static var currentValue: URLNavigating = StreamURLNavigator()
}

extension InjectedValues {
    public var urlNavigator: URLNavigating {
        get { Self[URLNavigatingKey.self] }
        set { Self[URLNavigatingKey.self] = newValue }
    }
}

/// Default implementation of URLNavigating that handles URL navigation on
/// supported platforms.
final class StreamURLNavigator: URLNavigating {

    @MainActor
    func openSettings() throws {
        #if canImport(UIKit)
        guard
            let url = URL(string: UIApplication.openSettingsURLString)
        else {
            throw ClientError("Settings URL isn't available.")
        }

        guard
            UIApplication.shared.canOpenURL(url)
        else {
            throw ClientError("Application cannot open settings url:\(url).")
        }

        UIApplication.shared.open(url)
        #else
        throw ClientError("Opening settings isn't supported on current platform.")
        #endif
    }
}
