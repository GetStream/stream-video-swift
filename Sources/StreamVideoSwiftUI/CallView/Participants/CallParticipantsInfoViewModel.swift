//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
class CallParticipantsInfoViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var inviteParticipantsShown = false
    
    private lazy var muteAudioAction = CallParticipantMenuAction(
        id: "mute-audio-user",
        title: "Mute user",
        requiredCapability: .muteUsers,
        iconName: "speaker.slash",
        action: muteAudio(for:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private lazy var muteVideoAction = CallParticipantMenuAction(
        id: "mute-video-user",
        title: "Disable video",
        requiredCapability: .muteUsers,
        iconName: "video.slash",
        action: muteVideo(for:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private lazy var unblockAction = CallParticipantMenuAction(
        id: "unblock-user",
        title: "Unblock user",
        requiredCapability: .blockUsers,
        iconName: "person.badge.plus",
        action: unblock(userId:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private lazy var blockAction = CallParticipantMenuAction(
        id: "block-user",
        title: "Block user",
        requiredCapability: .blockUsers,
        iconName: "person.badge.minus",
        action: block(userId:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private var call: Call?
    
    var inviteParticipantsButtonShown: Bool {
        call?.currentUserHasCapability(.updateCallMember) == true
    }
            
    init(call: Call?) {
        self.call = call
    }
    
    func menuActions(for participant: CallParticipant) -> [CallParticipantMenuAction] {
        guard let call else { return [] }
        var actions = [CallParticipantMenuAction]()
        guard call.currentUserHasCapability(.blockUsers) else { return actions }
        if participant.hasAudio {
            actions.append(muteAudioAction)
        }
        if participant.hasVideo {
            actions.append(muteVideoAction)
        }
        actions.append(blockAction)

        return actions
    }
    
    func unblockActions(for user: User) -> [CallParticipantMenuAction] {
        guard let call else { return [] }
        if call.currentUserHasCapability(.blockUsers) {
            return [unblockAction]
        } else {
            return []
        }
    }
    
    private func muteAudio(for userId: String) {
        let muteRequest = MuteUsersRequest(
            audio: true,
            muteAllUsers: false,
            screenshare: false,
            userIds: [userId],
            video: false
        )
        execute(muteRequest: muteRequest)
    }
    
    private func muteVideo(for userId: String) {
        let muteRequest = MuteUsersRequest(
            audio: false,
            muteAllUsers: false,
            screenshare: false,
            userIds: [userId],
            video: true
        )
        execute(muteRequest: muteRequest)
    }
    
    private func block(userId: String) {
        guard let call else { return }
        Task {
            try await call.blockUser(with: userId)
        }
    }
    
    private func unblock(userId: String) {
        guard let call else { return }
        Task {
            try await call.unblockUser(with: userId)
        }
    }
    
    private func execute(muteRequest: MuteUsersRequest) {
        guard let call else { return }
        Task {
            try await call.muteUsers(with: muteRequest)
        }
    }
}
