//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

@available(iOS 14.0, *)
public struct LocalParticipantViewModifier: ViewModifier {

    private let localParticipant: CallParticipant
    @StateObject var microphoneChecker = InjectedValues[\.microphoneChecker]
    @Binding private var callSettings: CallSettings

    @State private var audioLevels: [Float] = []

    public init(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>
    ) {
        self.localParticipant = localParticipant
        self._callSettings = callSettings
        self.audioLevels = microphoneChecker.audioLevels
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                ParticipantMicrophoneCheckView(
                    audioLevels: microphoneChecker.audioLevels,
                    microphoneOn: callSettings.audioOn,
                    isSilent: microphoneChecker.isSilent
                )
                .onReceive(microphoneChecker.$audioLevels) { audioLevels = $0 }
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
        callSettings: Binding<CallSettings>
    ) {
        self.localParticipant = localParticipant
        _microphoneChecker = .init(wrappedValue: .init())
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
