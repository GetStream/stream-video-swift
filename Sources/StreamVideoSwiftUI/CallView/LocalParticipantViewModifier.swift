//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

@available(iOS 14.0, *)
public struct LocalParticipantViewModifier: ViewModifier {

    @StateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings

    init(
        microphoneChecker: MicrophoneChecker,
        callSettings: Binding<CallSettings>
    ) {
        _microphoneChecker = .init(wrappedValue: microphoneChecker)
        self._callSettings = callSettings
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        MicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent
                        )
                        .accessibility(identifier: "microphoneCheckView")
                        Spacer()
                    }
                    .padding()
                    .onAppear { microphoneChecker.startListening() }
                    .onDisappear { microphoneChecker.stopListening() }
                }
            )
    }
}


@available(iOS, introduced: 13, obsoleted: 14)
public struct LocalParticipantViewModifier_iOS13: ViewModifier {

    @BackportStateObject private var microphoneChecker: MicrophoneChecker
    @Binding private var callSettings: CallSettings

    init(
        microphoneChecker: MicrophoneChecker,
        callSettings: Binding<CallSettings>
    ) {
        _microphoneChecker = .init(wrappedValue: microphoneChecker)
        self._callSettings = callSettings
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        MicrophoneCheckView(
                            audioLevels: microphoneChecker.audioLevels,
                            microphoneOn: callSettings.audioOn,
                            isSilent: microphoneChecker.isSilent
                        )
                        .accessibility(identifier: "microphoneCheckView")
                        Spacer()
                    }
                    .padding()
                    .onAppear { microphoneChecker.startListening() }
                    .onDisappear { microphoneChecker.stopListening() }
                }
            )
    }
}
