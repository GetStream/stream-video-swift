//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI

extension CallViewModel {

    func sendSnapshot(_ snapshotData: Data) {
        Task {
            do {
                let response = try await call?.sendCustomEvent([
                    "snapshot": .string(snapshotData.base64EncodedString())
                ])
                log.debug("Snapshot was sent successfully ✅")
            } catch {
                log.error("Snapshot failed to  send with error: \(error)")
            }
        }
    }
}

extension SendEventResponse: @unchecked Sendable {}
