//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LocalParticipantViewModifier: ViewModifier {

    private let localParticipant: CallParticipant
    private var call: Call?
    private var showAllInfo: Bool
    @StateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings
    private var decorations: Set<VideoCallParticipantDecoration>

    public init(
        localParticipant: CallParticipant,
        call: Call?,
        callSettings: Binding<CallSettings>,
        showAllInfo: Bool = false,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.localParticipant = localParticipant
        self.call = call
        let microphoneCheckerInstance = MicrophoneChecker()
        _microphoneChecker = .init(wrappedValue: microphoneCheckerInstance)
        _callSettings = callSettings
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                BottomView {
                    HStack {
                        ParticipantMicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent,
                            isPinned: localParticipant.isPinned
                        )

                        if showAllInfo {
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: localParticipant.connectionQuality
                            )
                        }
                    }
                }
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: localParticipant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: localParticipant, participantCount: participantCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}

@available(iOS, introduced: 13, obsoleted: 14)
public struct LocalParticipantViewModifier_iOS13: ViewModifier {

    private let localParticipant: CallParticipant
    private var call: Call?
    private var showAllInfo: Bool
    @BackportStateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings
    private var decorations: Set<VideoCallParticipantDecoration>

    init(
        localParticipant: CallParticipant,
        call: Call?,
        callSettings: Binding<CallSettings>,
        showAllInfo: Bool = false,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.localParticipant = localParticipant
        self.call = call
        _microphoneChecker = .init(wrappedValue: .init())
        _callSettings = callSettings
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                BottomView {
                    HStack {
                        ParticipantMicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent,
                            isPinned: localParticipant.isPinned
                        )

                        if showAllInfo {
                            Spacer()
                            ConnectionQualityIndicator(
                                connectionQuality: localParticipant.connectionQuality
                            )
                        }
                    }
                    .padding(.bottom, 2)
                }
                .padding(.all, showAllInfo ? 16 : 8)
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: localParticipant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: localParticipant, participantCount: participantCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
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
