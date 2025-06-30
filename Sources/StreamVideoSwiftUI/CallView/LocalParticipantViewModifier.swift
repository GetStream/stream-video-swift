//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

public struct LocalParticipantViewModifier: ViewModifier {

    var call: Call?
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>
    var microphoneChecker: MicrophoneChecker

    @State var participant: CallParticipant
    var participantPublisher: AnyPublisher<CallParticipant, Never>?

    @State var hasAudio: Bool
    var hasAudioPublisher: AnyPublisher<Bool, Never>?

    @State var participantsCount: Int
    var participantsCountPublisher: AnyPublisher<Int, Never>?

    public init(
        localParticipant: CallParticipant,
        call: Call?,
        callSettings: Binding<CallSettings>,
        showAllInfo: Bool = false,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.init(
            participant: localParticipant,
            call: call,
            showAllInfo: showAllInfo,
            decorations: decorations
        )
    }

    public init(
        participant: CallParticipant,
        call: Call?,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.call = call
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
        let microphoneChecker = MicrophoneChecker()
        self.microphoneChecker = microphoneChecker

        self.participant = participant
        participantPublisher = call?
            .state
            .$participantsMap
            .compactMap { $0[participant.sessionId] }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        hasAudio = call?.state.callSettings.audioOn ?? false
        hasAudioPublisher = call?
            .state
            .$callSettings
            .map(\.audioOn)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsCount = call?.state.participants.endIndex ?? 0
        participantsCountPublisher = call?
            .state
            .$participants
            .map(\.endIndex)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func body(content: Content) -> some View {
        content
            .overlay(participantInfoView)
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantsCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .onReceive(participantPublisher) { participant = $0 }
            .onReceive(participantsCountPublisher) { participantsCount = $0 }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @ViewBuilder
    var participantInfoView: some View {
        BottomView {
            HStack {
                MicrophoneCheckView(
                    audioLevels: microphoneChecker.audioLevels,
                    microphoneOn: hasAudio,
                    isSilent: microphoneChecker.isSilent,
                    isPinned: participant.isPinned
                )
                .accessibility(identifier: "microphoneCheckView")
                .onReceive(hasAudioPublisher) { hasAudio = $0 }

                Spacer()

                if showAllInfo {
                    ConnectionQualityIndicator(
                        connectionQuality: participant.connectionQuality
                    )
                }
            }
        }
    }
}

internal struct ParticipantMicrophoneCheckView: View {

    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool
    var isPinned: Bool

    var body: some View {
        MicrophoneCheckView(
            audioLevels: audioLevels,
            microphoneOn: microphoneOn,
            isSilent: isSilent,
            isPinned: isPinned
        )
        .accessibility(identifier: "microphoneCheckView")
    }
}
