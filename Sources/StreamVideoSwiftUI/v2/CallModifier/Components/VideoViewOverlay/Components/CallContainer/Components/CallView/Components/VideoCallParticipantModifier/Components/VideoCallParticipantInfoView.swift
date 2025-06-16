//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct VideoCallParticipantInfoView: View {
    var call: Call?
    var participant: CallParticipant
    var showAllInfo: Bool

    var body: some View {
        if let call {
            if #available(iOS 14.0, *) {
                VideoCallParticipantInfoContentView(
                    call: call,
                    participant: participant,
                    showAllInfo: showAllInfo
                )
            } else {
                VideoCallParticipantInfoContentView_iOS13(
                    call: call,
                    participant: participant,
                    showAllInfo: showAllInfo
                )
            }
        }
    }
}

extension VideoCallParticipantInfoView {
    private final class ViewModel: ObservableObject, @unchecked Sendable {
        @Published private(set) var participant: CallParticipant
        private let call: Call
        private let disposableBag = DisposableBag()

        @MainActor
        init(call: Call, participant: CallParticipant,) {
            self.participant = participant
            self.call = call

            call
                .state
                .$participants
                .receive(on: DispatchQueue.global(qos: .background))
                .compactMap { participants in participants.first(where: { $0.sessionId == participant.sessionId }) }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: \.participant, onWeak: self)
                .store(in: disposableBag)
        }
    }

    @available(iOS 14.0, *)
    private struct VideoCallParticipantInfoContentView: View {

        var showAllInfo: Bool
        @StateObject var viewModel: ViewModel

        init(
            call: Call,
            participant: CallParticipant,
            showAllInfo: Bool
        ) {
            self.showAllInfo = showAllInfo
            _viewModel = .init(wrappedValue: .init(call: call, participant: participant))
        }

        var body: some View {
            BottomView {
                HStack {
                    ParticipantInfoView(
                        participant: viewModel.participant,
                        isPinned: viewModel.participant.isPinned
                    )

                    Spacer()

                    if showAllInfo {
                        ConnectionQualityIndicator(
                            connectionQuality: viewModel.participant.connectionQuality
                        )
                    }
                }
            }
        }
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    private struct VideoCallParticipantInfoContentView_iOS13: View {

        var showAllInfo: Bool
        @BackportStateObject var viewModel: ViewModel

        init(
            call: Call,
            participant: CallParticipant,
            showAllInfo: Bool
        ) {
            self.showAllInfo = showAllInfo
            _viewModel = .init(wrappedValue: .init(call: call, participant: participant))
        }

        var body: some View {
            BottomView {
                HStack {
                    ParticipantInfoView(
                        participant: viewModel.participant,
                        isPinned: viewModel.participant.isPinned
                    )

                    Spacer()

                    if showAllInfo {
                        ConnectionQualityIndicator(
                            connectionQuality: viewModel.participant.connectionQuality
                        )
                    }
                }
            }
        }
    }
}
