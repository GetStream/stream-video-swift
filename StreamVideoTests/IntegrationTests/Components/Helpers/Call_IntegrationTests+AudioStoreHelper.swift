//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    struct AudioStoreHelper: @unchecked Sendable {
        private var mockStore = MockRTCAudioStore()

        init() {
            mockStore.makeShared()
        }

        func dismantle() async throws {
            mockStore
                .audioStore
                .dispatch(.setAudioDeviceModule(nil))

            _ = try await mockStore
                .audioStore
                .publisher(\.audioDeviceModule)
                .filter { $0 == nil }
                .nextValue(timeout: 2)

            mockStore.dismantle()
        }

        func setActive(_ isActive: Bool) {
            mockStore
                .audioStore
                .dispatch(.setActive(isActive))
        }

        func setAudioRoute(_ route: RTCAudioStore.StoreState.AudioRoute) {
            mockStore
                .audioStore
                .dispatch(.setCurrentRoute(route))
        }

        func setMicrophoneMuted(_ isMuted: Bool) {
            mockStore
                .audioStore
                .dispatch(.setMicrophoneMuted(isMuted))
        }
    }
}
