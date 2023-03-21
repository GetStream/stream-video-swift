//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

class CallParticipantsInfoViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var inviteParticipantsShown = false
        
    private lazy var permissionsController: PermissionsController = {
        streamVideo.makePermissionsController()
    }()
    
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
        requiredCapability: .muteUsers, // TODO: check capability
        iconName: "person.badge.plus",
        action: unblock(userId:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private lazy var blockAction = CallParticipantMenuAction(
        id: "block-user",
        title: "Block user",
        requiredCapability: .muteUsers, // TODO: check capability
        iconName: "person.badge.minus",
        action: block(userId:),
        confirmationPopup: nil,
        isDestructive: false
    )
    
    private let callId: String
    private let callType: String
        
    init(callId: String, callType: String) {
        self.callId = callId
        self.callType = callType
    }
    
    func menuActions(for participant: CallParticipant) -> [CallParticipantMenuAction] {
        var actions = [CallParticipantMenuAction]()
        // TODO: check if this capability is enough for blocking users.
        guard permissionsController.currentUserHasCapability(.muteUsers) else { return actions }
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
        if permissionsController.currentUserHasCapability(.muteUsers) {
            return [unblockAction]
        } else {
            return []
        }
    }
    
    private func muteAudio(for userId: String) {
        let muteRequest = MuteRequest(
            userIds: [userId],
            muteAllUsers: false,
            audio: true,
            video: false,
            screenshare: false
        )
        execute(muteRequest: muteRequest)
    }
    
    private func muteVideo(for userId: String) {
        let muteRequest = MuteRequest(
            userIds: [userId],
            muteAllUsers: false,
            audio: false,
            video: true,
            screenshare: false
        )
        execute(muteRequest: muteRequest)
    }
    
    private func block(userId: String) {
        Task {
            try await permissionsController.blockUser(
                with: userId,
                callId: callId,
                callType: callType
            )
        }
    }
    
    private func unblock(userId: String) {
        Task {
            try await permissionsController.unblockUser(
                with: userId,
                callId: callId,
                callType: callType
            )
        }
    }
    
    private func execute(muteRequest: MuteRequest) {
        Task {
            try await permissionsController.muteUsers(
                with: muteRequest,
                callId: callId,
                callType: callType
            )
        }
    }
}
