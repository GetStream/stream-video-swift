//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

struct DemoChatViewModelInjectionKey: InjectionKey {
    static var currentValue: DemoChatViewModel?
}

extension InjectedValues {

    var chatViewModel: DemoChatViewModel? {
        get { Self[DemoChatViewModelInjectionKey.self] }
        set {
            guard AppEnvironment.chatIntegration == .enabled else { return }
            Self[DemoChatViewModelInjectionKey.self] = newValue
        }
    }
}
