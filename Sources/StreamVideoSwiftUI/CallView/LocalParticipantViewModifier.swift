//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

@available(iOS 14.0, *)
public struct LocalParticipantViewModifier: ViewModifier {

    private let localParticipant: CallParticipant
    @StateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings

    init(
        localParticipant: CallParticipant,
        microphoneChecker: MicrophoneChecker,
        callSettings: Binding<CallSettings>
    ) {
        self.localParticipant = localParticipant
        _microphoneChecker = .init(wrappedValue: microphoneChecker)
        self._callSettings = callSettings
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                ParticipantMicrophoneCheckView(
                    audioLevels: microphoneChecker.audioLevels,
                    microphoneOn: callSettings.audioOn,
                    isSilent: microphoneChecker.isSilent
                )
                .onAppear { microphoneChecker.startListening() }
                .onDisappear { microphoneChecker.stopListening() }
            )
    }
}


@available(iOS, introduced: 13, obsoleted: 14)
public struct LocalParticipantViewModifier_iOS13: ViewModifier {

    private let localParticipant: CallParticipant
    @BackportStateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings

    init(
        localParticipant: CallParticipant,
        microphoneChecker: MicrophoneChecker,
        callSettings: Binding<CallSettings>
    ) {
        self.localParticipant = localParticipant
        _microphoneChecker = .init(wrappedValue: microphoneChecker)
        self._callSettings = callSettings
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                ParticipantMicrophoneCheckView(
                    audioLevels: microphoneChecker.audioLevels,
                    microphoneOn: callSettings.audioOn,
                    isSilent: microphoneChecker.isSilent
                )
                .onAppear { microphoneChecker.startListening() }
                .onDisappear { microphoneChecker.stopListening() }
            )
    }
}

internal struct ParticipantMicrophoneCheckView: View {

    var audioLevels: [Float]
    var microphoneOn: Bool
    var isSilent: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                MicrophoneCheckView(
                    audioLevels: audioLevels,
                    microphoneOn: microphoneOn,
                    isSilent: isSilent
                )
                .accessibility(identifier: "microphoneCheckView")
                Spacer()
            }
            .padding()
        }
    }
}
