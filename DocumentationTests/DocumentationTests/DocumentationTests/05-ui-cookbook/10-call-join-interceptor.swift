//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        @MainActor
        final class ParticipantReadyCallJoinInterceptor: CallJoinIntercepting {
            private let streamVideo: StreamVideo
            private let disposableBag = DisposableBag()
            private var ringingCallCancellable: AnyCancellable?
            private var customEventCancellable: AnyCancellable?
            private let customEventKey: String
            private let currentUserID: String

            private let hasOtherReadyParticipants = CurrentValueSubject<Bool, Never>(false)

            init(
                streamVideo: StreamVideo,
                customEventKey: String = "participant.ready"
            ) {
                self.streamVideo = streamVideo
                self.customEventKey = customEventKey
                self.currentUserID = streamVideo.state.user.id

                ringingCallCancellable = streamVideo
                    .state
                    .$ringingCall
                    .receive(on: DispatchQueue.main)
                    .removeDuplicates { $0?.cId == $1?.cId }
                    .sinkTask(storeIn: disposableBag) { @MainActor [weak self] ringingCall in
                        self?.didUpdate(ringingCall: ringingCall)
                    }
            }

            func callReadyToJoin(_ call: Call) async throws {
                guard customEventCancellable != nil else {
                    return
                }

                do {
                    try await call.sendCustomEvent([customEventKey: .string(currentUserID)])
                } catch {
                    // Keep the example non-blocking even if the readiness ping fails.
                }

                _ = try? await hasOtherReadyParticipants
                    .filter { $0 }
                    .nextValue()
            }

            private func didUpdate(ringingCall: Call?) {
                cancelCustomEventObservation()

                guard let ringingCall else {
                    return
                }

                customEventCancellable = ringingCall
                    .eventPublisher(for: CustomVideoEvent.self)
                    .compactMap { [customEventKey] in $0.custom[customEventKey]?.stringValue }
                    .filter { [currentUserID] in $0 != currentUserID }
                    .map { _ in true }
                    .sinkTask(
                        storeIn: disposableBag
                    ) { @MainActor [weak self] hasReadyParticipant in
                        self?.hasOtherReadyParticipants.send(hasReadyParticipant)
                    }
            }

            private func cancelCustomEventObservation() {
                customEventCancellable?.cancel()
                customEventCancellable = nil
                hasOtherReadyParticipants.send(false)
            }
        }

        let callViewModel = CallViewModel()
        callViewModel.callJoinInterceptor = ParticipantReadyCallJoinInterceptor(streamVideo: streamVideo)
    }

    container {
        @MainActor
        final class ParticipantReadyCallJoinInterceptor: CallJoinIntercepting {
            private let streamVideo: StreamVideo

            init(streamVideo: StreamVideo) {
                self.streamVideo = streamVideo
            }

            func callReadyToJoin(_ call: Call) async throws { /* Readiness work goes here. */ }
        }

        // Assign the interceptor at startup, where streamVideo is handed to
        // the adapter, so CallKit-answered calls honor it even on cold launch.
        @Injected(\.callKitAdapter) var callKitAdapter
        callKitAdapter.streamVideo = streamVideo
        callKitAdapter.callJoinInterceptor = ParticipantReadyCallJoinInterceptor(streamVideo: streamVideo)
    }
}
