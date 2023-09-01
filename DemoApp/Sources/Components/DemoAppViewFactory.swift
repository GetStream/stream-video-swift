//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import struct StreamChatSwiftUI.InjectedValues
import SwiftUI

final class DemoAppViewFactory: ViewFactory {

    static let shared = DemoAppViewFactory()

    @Injected(\.colors) var colors

    func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        DemoWaitingLocalUserView(viewFactory: self, viewModel: viewModel)
    }

    func makeUserAvatar(imageURL: URL?, size: CGFloat) -> AnyView {
        .init(UserAvatar(imageURL: imageURL, size: size))
    }

    func makeInnerWaitingLocalUserView(viewModel: CallViewModel) -> AnyView {
        .init(WaitingLocalUserView(viewModel: viewModel, viewFactory: self))
    }

    func makeCallView(viewModel: CallViewModel) -> DemoCallView<DemoAppViewFactory> {
        DemoCallView(
            viewFactory: self,
            microphoneChecker: MicrophoneChecker(),
            viewModel: viewModel
        )
    }

    func makeInnerCallView(viewModel: CallViewModel) -> AnyView {
        .init(StreamVideoSwiftUI.CallView(viewFactory: self, viewModel: viewModel))
    }

    func makeCallControlsView(viewModel: CallViewModel) -> some View {
        AppControlsWithChat(viewModel: viewModel)
    }

    func makeCallTopView(viewModel: CallViewModel) -> DemoCallTopView {
        DemoCallTopView(viewModel: viewModel)
    }

    func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        customData: [String : RawJSON],
        call: Call?
    ) -> DemoVideoCallParticipantView {
        DemoVideoCallParticipantView(
            participant: participant,
            id: id,
            availableSize: availableSize,
            contentMode: contentMode,
            customData: customData,
            call: call
        )
    }
}
