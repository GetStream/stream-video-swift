//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
final class CallParticipantsInfoViewModel: ObservableObject {

    @Injected(\.streamVideo) var streamVideo

    @Published var inviteParticipantsShown = false
    @Published private(set) var participants: [CallParticipant]

    private lazy var muteAudioAction = CallParticipantMenuAction(
        id: "mute-audio-user",
        title: "Mute user",
        requiredCapability: .muteUsers,
        iconName: "speaker.slash",
        action: { [weak self] in self?.muteAudio(for: $0) },
        confirmationPopup: nil,
        isDestructive: false
    )

    private lazy var muteVideoAction = CallParticipantMenuAction(
        id: "mute-video-user",
        title: "Disable video",
        requiredCapability: .muteUsers,
        iconName: "video.slash",
        action: { [weak self] in self?.muteVideo(for: $0) },
        confirmationPopup: nil,
        isDestructive: false
    )

    private lazy var unblockAction = CallParticipantMenuAction(
        id: "unblock-user",
        title: "Unblock user",
        requiredCapability: .blockUsers,
        iconName: "person.badge.plus",
        action: { [weak self] in self?.unblock(userId: $0) },
        confirmationPopup: nil,
        isDestructive: false
    )

    private lazy var blockAction = CallParticipantMenuAction(
        id: "block-user",
        title: "Block user",
        requiredCapability: .blockUsers,
        iconName: "person.badge.minus",
        action: { [weak self] in self?.block(userId: $0) },
        confirmationPopup: nil,
        isDestructive: false
    )

    let callViewModel: CallViewModel

    var call: Call? { callViewModel.call }
    var inviteParticipantsButtonShown: Bool {
        callViewModel.call?.currentUserHasCapability(.updateCallMember) == true
    }

    private let disposableBag = DisposableBag()

    init(_ callViewModel: CallViewModel) {
        self.callViewModel = callViewModel
        participants = Array(callViewModel.callParticipants.values)

        callViewModel
            .$callParticipants
            .map { Array($0.values).sorted(by: { $0.name < $1.name }) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.participants, onWeak: self)
            .store(in: disposableBag)
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
        executeMute(userId: userId, audio: true, video: false)
    }

    private func muteVideo(for userId: String) {
        executeMute(userId: userId, audio: false, video: true)
    }

    private func block(userId: String) {
        guard let call else { return }
        Task {
            do {
                try await call.blockUser(with: userId)
            } catch {
                log.error(error)
            }
        }
    }

    private func unblock(userId: String) {
        guard let call else { return }
        Task {
            do {
                try await call.unblockUser(with: userId)
            } catch {
                log.error(error)
            }
        }
    }

    private func executeMute(userId: String, audio: Bool = true, video: Bool = true) {
        guard let call else { return }
        Task {
            do {
                try await call.mute(userId: userId, audio: audio, video: video)
            } catch {
                log.error(error)
            }
        }
    }
}
