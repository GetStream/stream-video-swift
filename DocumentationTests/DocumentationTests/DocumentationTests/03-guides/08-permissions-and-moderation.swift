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

        // mute only audio for a specific user
        try await call.mute(userId: "tommaso", audio: true, video: false)

        // mute only video for a specific user
        try await call.mute(userId: "tommaso", audio: false, video: true)
    }

    asyncContainer {
        for await event in call.subscribe() {
            switch event {
            case .typePermissionRequestEvent(let requestEvent):
                // A user is requesting permission
                print("User \(requestEvent.user.id) requested permissions")

            case .typeUpdatedCallPermissionsEvent(let permissionsEvent):
                // Permissions were updated for a user
                print("Permissions updated for user: \(permissionsEvent.user.id)")

            default:
                break
            }
        }
    }

    container {
        struct ParticipantModerationMenu: View {
            let call: Call
            let participant: CallParticipant
            @State private var showAlert = false
            @State private var alertMessage = ""

            var body: some View {
                Menu {
                    Button(role: .destructive) {
                        muteParticipant()
                    } label: {
                        Label("Mute", systemImage: "mic.slash")
                    }

                    Button(role: .destructive) {
                        muteParticipantVideo()
                    } label: {
                        Label("Turn off video", systemImage: "video.slash")
                    }

                    Button(role: .destructive) {
                        blockParticipant()
                    } label: {
                        Label("Block", systemImage: "hand.raised")
                    }

                    Button(role: .destructive) {
                        removeParticipant()
                    } label: {
                        Label("Remove from call", systemImage: "person.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding()
                }
                .alert("Moderation", isPresented: $showAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
            }

            private func muteParticipant() {
                Task {
                    do {
                        try await call.mute(userId: participant.userId, audio: true, video: false)
                    } catch {
                        alertMessage = "Failed to mute: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }

            private func muteParticipantVideo() {
                Task {
                    do {
                        try await call.mute(userId: participant.userId, audio: false, video: true)
                    } catch {
                        alertMessage = "Failed to disable video: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }

            private func blockParticipant() {
                Task {
                    do {
                        try await call.blockUser(with: participant.userId)
                    } catch {
                        alertMessage = "Failed to block: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }

            private func removeParticipant() {
                Task {
                    do {
                        try await call.removeMembers(ids: [participant.userId])
                    } catch {
                        alertMessage = "Failed to remove: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }
        }
    }

    container {
        let canMuteOthers = call.currentUserHasCapability(.muteUsers)
        let canBlockUsers = call.currentUserHasCapability(.blockUsers)
        let canRemoveMembers = call.currentUserHasCapability(.removeCallMember)
        let canEndCall = call.currentUserHasCapability(.endCall)
    }
}
