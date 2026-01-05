//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        YourView()
            .onOpenURL { url in
                handleDeepLink(from: url)
            }

        func handleDeepLink(from url: URL) {
            if appState.userState == .notLoggedIn {
                return
            }
            let callId = url.lastPathComponent
            let queryParams = url.queryParameters
            let callType = queryParams["type"] ?? "default"
            appState.deeplinkInfo = DeeplinkInfo(callId: callId, callType: callType)
        }
    }

    viewContainer {
        var callViewModel = viewModel

        ViewThatHostsCall()
            .onReceive(appState.$deeplinkInfo, perform: { deeplinkInfo in
                if deeplinkInfo != .empty {
                    callViewModel.joinCall(callType: deeplinkInfo.callType, callId: deeplinkInfo.callId)
                    appState.deeplinkInfo = .empty
                }
            })
    }
}
