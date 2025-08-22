//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
#if canImport(UIKit)
import UIKit
#endif

public protocol URLNavigating {

    @MainActor
    func openSettings() throws
}

enum URLNavigatingKey: InjectionKey {
    nonisolated(unsafe) public static var currentValue: URLNavigating = StreamURLNavigator()
}

extension InjectedValues {
    public var urlNavigator: URLNavigating {
        get { Self[URLNavigatingKey.self] }
        set { Self[URLNavigatingKey.self] = newValue }
    }
}

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
