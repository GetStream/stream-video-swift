//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import Combine

extension URL {
    public var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

extension View {

    func observeAndHandleDeeplinks(
        _ viewModel: CallViewModel,
        deeplinkInfoPublisher: AnyPublisher<DeeplinkInfo, Never>,
        resetAppState: @escaping () -> Void
    ) -> some View {
        self.onReceive(deeplinkInfoPublisher) { deeplinkInfo in
            if deeplinkInfo != .empty {
                /// https://github.com/apple/swift/pull/60688
                Task { @MainActor in
                    viewModel.joinCall(
                        callId: deeplinkInfo.callId,
                        type: deeplinkInfo.callType
                    )
                }
                resetAppState()
            }
        }
    }
}
