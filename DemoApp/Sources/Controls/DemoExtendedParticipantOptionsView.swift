//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

/// Menu-driving subset of call / participant data (excludes audio levels, connection quality, etc.) so the ellipsis UI does not flash on unrelated WebRTC updates.
private struct DemoParticipantMenuModel: Equatable {
    let name: String
    let id: String
    let userId: String
    let sessionId: String
    let hasVideo: Bool
    let hasAudio: Bool
    let videoTrackEnabled: Bool
    let audioTrackEnabled: Bool
    let isPinned: Bool
    let isPinnedRemotely: Bool
    let isLocalParticipant: Bool
    let canPinForEveryone: Bool
    let canKick: Bool
    let canMuteUsers: Bool

    init(participant: CallParticipant, localSessionId: String, ownCapabilities: [OwnCapability]) {
        name = participant.name
        id = participant.id
        userId = participant.userId
        sessionId = participant.sessionId
        hasVideo = participant.hasVideo
        hasAudio = participant.hasAudio
        videoTrackEnabled = participant.track?.isEnabled ?? false
        audioTrackEnabled = participant.audioTrack?.isEnabled ?? false
        isPinned = participant.isPinned
        isPinnedRemotely = participant.isPinnedRemotely
        isLocalParticipant = participant.sessionId == localSessionId
        canPinForEveryone = ownCapabilities.contains(.pinForEveryone)
        canKick = ownCapabilities.contains(.kickUser)
        canMuteUsers = ownCapabilities.contains(.muteUsers)
    }

    /// Stable identity for forcing Menu refresh only when menu-affecting fields change.
    var presentationIdentity: String {
        [
            id,
            name,
            "\(hasVideo)",
            "\(hasAudio)",
            "\(videoTrackEnabled)",
            "\(audioTrackEnabled)",
            "\(isPinned)",
            "\(isPinnedRemotely)",
            "\(isLocalParticipant)",
            "\(canPinForEveryone)",
            "\(canKick)",
            "\(canMuteUsers)"
        ].joined(separator: "|")
    }
}

/// Demo-only extended participant menu (SDK `…` is disabled via decorations).
struct DemoExtendedParticipantOptionsView: View {

    @Injected(\.appearance) private var appearance

    @ObservedObject private var tileState = DemoParticipantTileState.shared

    private let fallbackParticipant: CallParticipant
    private let call: Call

    @State private var menuModel: DemoParticipantMenuModel
    @State private var presentActionSheet = false

    init(participant: CallParticipant, call: Call) {
        fallbackParticipant = participant
        self.call = call
        let initialParticipant = call.state.participantsMap[participant.id] ?? participant
        _menuModel = State(
            initialValue: DemoParticipantMenuModel(
                participant: initialParticipant,
                localSessionId: call.state.sessionId,
                ownCapabilities: call.state.ownCapabilities
            )
        )
    }

    private func liveParticipant() -> CallParticipant {
        call.state.participantsMap[fallbackParticipant.id] ?? fallbackParticipant
    }

    private func refreshMenuModelFromCallState() {
        let next = DemoParticipantMenuModel(
            participant: liveParticipant(),
            localSessionId: call.state.sessionId,
            ownCapabilities: call.state.ownCapabilities
        )
        if next != menuModel {
            menuModel = next
        }
    }

    /// Includes tile aspect so the aspect row label updates without subscribing to full ``CallState``.
    private var menuPresentationIdentity: String {
        let layoutDefault = tileState.layoutDefault(for: menuModel.id)
        let aspect = tileState.resolvedContentMode(
            for: menuModel.id,
            layoutFromCallSite: layoutDefault
        )
        return menuModel.presentationIdentity + "|aspect:\(aspect.rawValue)"
    }

    private var menuElements: [(title: String, action: () -> Void)] {
        var items = [(title: String, action: () -> Void)]()

        if menuModel.hasVideo, let track = liveParticipant().track {
            let enabled = track.isEnabled
            items.append((
                enabled ? DemoParticipantMenuStrings.muteVideo : DemoParticipantMenuStrings.unmuteVideo,
                {
                    track.isEnabled = !enabled
                    refreshMenuModelFromCallState()
                }
            ))
        }

        if menuModel.hasAudio, let audioTrack = liveParticipant().audioTrack {
            let enabled = audioTrack.isEnabled
            items.append((
                enabled ? DemoParticipantMenuStrings.muteAudio : DemoParticipantMenuStrings.unmuteAudio,
                {
                    audioTrack.isEnabled = !enabled
                    refreshMenuModelFromCallState()
                }
            ))
        }

        if menuModel.hasVideo {
            let layout = tileState.layoutDefault(for: menuModel.id)
            let resolved = tileState.resolvedContentMode(for: menuModel.id, layoutFromCallSite: layout)
            let aspectTitle = resolved == .scaleAspectFill
                ? DemoParticipantMenuStrings.useAspectFit
                : DemoParticipantMenuStrings.useAspectFill
            items.append((aspectTitle, {
                tileState.toggleVideoAspectMode(for: menuModel.id)
            }))
        }

        if menuModel.isPinned {
            items.append((DemoParticipantMenuStrings.unpinUser, { unpin() }))
        } else {
            items.append((DemoParticipantMenuStrings.pinUser, { pin() }))
        }

        if menuModel.canPinForEveryone {
            if menuModel.isPinnedRemotely {
                items.append((DemoParticipantMenuStrings.unpinForEveryone, { unpinForEveryone() }))
            } else {
                items.append((DemoParticipantMenuStrings.pinForEveryone, { pinForEveryone() }))
            }
        }

        if menuModel.canKick {
            items.append((DemoParticipantMenuStrings.kickUser, { kickUser() }))
        }

        if !menuModel.isLocalParticipant, menuModel.hasVideo, menuModel.canMuteUsers {
            items.append((DemoParticipantMenuStrings.stopTheirVideo, { stopTheirVideo() }))
        }

        if !menuModel.isLocalParticipant, menuModel.hasAudio, menuModel.canMuteUsers {
            items.append((DemoParticipantMenuStrings.stopTheirMicrophone, { stopTheirMicrophone() }))
        }

        return items
    }

    var body: some View {
        Group {
            if #available(iOS 14.0, *) {
                Menu {
                    ForEach(Array(menuElements.enumerated()), id: \.offset) { _, element in
                        Button(
                            action: element.action,
                            label: { Text(element.title) }
                        )
                    }
                } label: { optionsButtonView }
                    .id(menuPresentationIdentity)
            } else {
                Button {
                    presentActionSheet = true
                } label: {
                    optionsButtonView
                }
                .actionSheet(isPresented: $presentActionSheet) {
                    ActionSheet(
                        title: Text(menuModel.name),
                        buttons: menuElements
                            .map { ActionSheet.Button.default(Text($0.title), action: $0.action) } + [ActionSheet.Button.cancel()]
                    )
                }
                .id(menuPresentationIdentity)
            }
        }
        .onAppear {
            refreshMenuModelFromCallState()
        }
        .onReceive(
            Publishers.CombineLatest3(
                call.state.$participantsMap,
                call.state.$ownCapabilities,
                call.state.$sessionId
            )
            .receive(on: DispatchQueue.main)
            .map { map, capabilities, localSessionId in
                let participant = map[fallbackParticipant.id] ?? fallbackParticipant
                return DemoParticipantMenuModel(
                    participant: participant,
                    localSessionId: localSessionId,
                    ownCapabilities: capabilities
                )
            }
            .removeDuplicates()
        ) { newModel in
            menuModel = newModel
        }
    }

    @ViewBuilder
    private var optionsButtonView: some View {
        Image(systemName: "ellipsis")
            .foregroundColor(appearance.colors.white)
            .padding(8)
            .background(appearance.colors.participantInfoBackgroundColor)
            .clipShape(Circle())
    }

    private func pin() {
        Task {
            do {
                try await call.pin(sessionId: menuModel.sessionId)
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }

    private func unpin() {
        Task {
            do {
                try await call.unpin(sessionId: menuModel.sessionId)
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }

    private func pinForEveryone() {
        Task {
            do {
                _ = try await call.pinForEveryone(
                    userId: menuModel.userId,
                    sessionId: menuModel.id
                )
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }

    private func unpinForEveryone() {
        Task {
            do {
                _ = try await call.unpinForEveryone(
                    userId: menuModel.userId,
                    sessionId: menuModel.id
                )
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }

    private func kickUser() {
        Task {
            do {
                _ = try await call.kickUser(userId: menuModel.userId)
            } catch {
                log.error(error)
            }
        }
    }

    private func stopTheirVideo() {
        Task {
            do {
                _ = try await call.mute(userId: menuModel.userId, audio: false, video: true)
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }

    private func stopTheirMicrophone() {
        Task {
            do {
                _ = try await call.mute(userId: menuModel.userId, audio: true, video: false)
                refreshMenuModelFromCallState()
            } catch {
                log.error(error)
            }
        }
    }
}

private enum DemoParticipantMenuStrings {
    static let muteVideo = "Mute video"
    static let unmuteVideo = "Unmute video"
    static let muteAudio = "Mute audio"
    static let unmuteAudio = "Unmute audio"
    static let useAspectFill = "Use aspect fill"
    static let useAspectFit = "Use aspect fit"
    static let pinUser = "Pin user"
    static let unpinUser = "Unpin user"
    static let pinForEveryone = "Pin for everyone"
    static let unpinForEveryone = "Unpin for everyone"
    static let kickUser = "Kick user"
    static let stopTheirVideo = "Stop their video"
    static let stopTheirMicrophone = "Stop their microphone"
}
