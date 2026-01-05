//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        // see if you currently have this permission.
        let hasPermission = call.currentUserHasCapability(.sendAudio)

        // request the host to grant you this permission.
        let response = try await call.request(permissions: [.sendAudio])
    }

    asyncContainer {
        if let request = call.state.permissionRequests.first {
            // reject it
            request.reject()

            // grant it
            try await call.grant(request: request)
        }
    }

    asyncContainer {
        try await call.grant(permissions: [.sendAudio], for: "thrierry")
    }

    asyncContainer {
        let response = try await call.revoke(permissions: [.sendAudio], for: "tommaso")
    }

    asyncContainer {
        // block a user
        try await call.blockUser(with: "tommaso")

        // unblock a user
        try await call.unblockUser(with: "tommaso")

        // remove a member from a call
        try await call.removeMembers(ids: ["tommaso"])
    }

    asyncContainer {
        // mutes all users (audio and video are true by default) other than yourself
        try await call.muteAllUsers()

        // mute user with id "tommaso" specifically
        try await call.mute(userId: "tommaso")
    }
}
