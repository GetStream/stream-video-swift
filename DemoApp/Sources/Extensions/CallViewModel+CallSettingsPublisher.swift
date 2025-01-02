//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamVideoSwiftUI

extension CallViewModel {

    internal var callSettingsPublisher: AnyPublisher<CallSettings, Never> {
        $callSettings.eraseToAnyPublisher()
    }
}
