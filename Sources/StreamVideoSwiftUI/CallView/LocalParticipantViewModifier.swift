//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

@available(iOS 14.0, *)
public struct LocalParticipantViewModifier: ViewModifier {

    private let localParticipant: CallParticipant
    private var call: Call?
    private var showAllInfo: Bool
    @StateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings

    public init(
        localParticipant: CallParticipant,
        call: Call?,
        callSettings: Binding<CallSettings>,
        showAllInfo: Bool = false
    ) {
        self.localParticipant = localParticipant
        self.call = call
        _microphoneChecker = .init(wrappedValue: .init())
        self._callSettings = callSettings
        self.showAllInfo = showAllInfo
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                BottomView {
                    HStack {
                        ParticipantMicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent
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
                .onAppear { microphoneChecker.startListening() }
                .onDisappear { microphoneChecker.stopListening() }
            )
            .modifier(VideoCallParticipantOptionsModifier(participant: localParticipant, call: call))
            .modifier(VideoCallParticipantSpeakingModifier(participant: localParticipant, participantCount: participantCount))
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

    init(
        localParticipant: CallParticipant,
        call: Call?,
        callSettings: Binding<CallSettings>,
        showAllInfo: Bool = false
    ) {
        self.localParticipant = localParticipant
        self.call = call
        _microphoneChecker = .init(wrappedValue: .init())
        self._callSettings = callSettings
        self.showAllInfo = showAllInfo
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                BottomView {
                    HStack {
                        ParticipantMicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent
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
                .onAppear { microphoneChecker.startListening() }
                .onDisappear { microphoneChecker.stopListening() }
            )
            .modifier(VideoCallParticipantOptionsModifier(participant: localParticipant, call: call))
            .modifier(VideoCallParticipantSpeakingModifier(participant: localParticipant, participantCount: participantCount))
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

    var body: some View {
        MicrophoneCheckView(
            audioLevels: audioLevels,
            microphoneOn: microphoneOn,
            isSilent: isSilent
        )
        .accessibility(identifier: "microphoneCheckView")
    }
}
