//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoCallParticipantModifier: ViewModifier {

    var call: Call?
    var participant: CallParticipant
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.participant = participant
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }

    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
            .overlay(VideoCallParticipantInfoView(call: call, participant: participant, showAllInfo: showAllInfo))
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .modifier(VideoCallParticipantSpeakerViewModifier(call: call, participant: participant, decorations: decorations))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }
}

struct VideoCallParticipantSpeakerViewModifier: ViewModifier {

    var call: Call?
    var participant: CallParticipant
    var decorations: Set<VideoCallParticipantDecoration>

    func body(content: Content) -> some View {
        if let call {
            if #available(iOS 14.0, *) {
                VideoCallParticipantSpeakerContainerContentView(
                    viewModel: .init(call: call, participant: participant),
                    decorations: .init(decorations),
                    content: content
                )
            } else {
                VideoCallParticipantSpeakerContainerContentView_iOS13(
                    viewModel: .init(call: call, participant: participant),
                    decorations: decorations,
                    content: content
                )
            }
        }
    }
}

extension VideoCallParticipantSpeakerViewModifier {
    private final class ViewModel: ObservableObject, @unchecked Sendable {
        @Published private(set) var participant: CallParticipant
        @Published private(set) var participantsCount: Int
        private let call: Call
        private let disposableBag = DisposableBag()

        @MainActor
        init(call: Call, participant: CallParticipant,) {
            self.participant = participant
            self.call = call
            participantsCount = call.state.participants.endIndex

            call
                .state
                .$participants
                .receive(on: DispatchQueue.global(qos: .background))
                .compactMap { participants in participants.first(where: { $0.sessionId == participant.sessionId }) }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: \.participant, onWeak: self)
                .store(in: disposableBag)

            call
                .state
                .$participants
                .receive(on: DispatchQueue.main)
                .map(\.endIndex)
                .removeDuplicates()
                .assign(to: \.participantsCount, onWeak: self)
                .store(in: disposableBag)
        }
    }

    @available(iOS 14.0, *)
    private struct VideoCallParticipantSpeakerContainerContentView<Content: View>: View {
        @StateObject var viewModel: ViewModel
        var decorations: Set<VideoCallParticipantDecoration>
        var content: Content

        var body: some View {
            content
                .applyDecorationModifierIfRequired(
                    VideoCallParticipantSpeakingModifier(
                        participant: viewModel.participant,
                        participantCount: viewModel.participantsCount
                    ),
                    decoration: .speaking,
                    availableDecorations: decorations
                )
        }
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    private struct VideoCallParticipantSpeakerContainerContentView_iOS13<Content: View>: View {
        @BackportStateObject var viewModel: ViewModel
        var decorations: Set<VideoCallParticipantDecoration>
        var content: Content

        var body: some View {
            content
                .applyDecorationModifierIfRequired(
                    VideoCallParticipantSpeakingModifier(
                        participant: viewModel.participant,
                        participantCount: viewModel.participantsCount
                    ),
                    decoration: .speaking,
                    availableDecorations: decorations
                )
        }
    }
}
