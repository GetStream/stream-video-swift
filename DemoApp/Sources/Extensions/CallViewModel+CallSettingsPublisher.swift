//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import Combine

extension CallViewModel {

    internal var callSettingsPublisher: AnyPublisher<CallSettings, Never> {
        self.$callSettings.eraseToAnyPublisher()
    }
}
