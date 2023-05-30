//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

class DemoAppViewFactory: ViewFactory {
    
    static let shared = DemoAppViewFactory()
    
    func makeWaitingLocalUserView(viewModel: CallViewModel) -> some View {
        CustomWaitingLocalUserView(viewModel: viewModel, viewFactory: self)
    }
    
    /*
    func makeVideoParticipantView(
        participant: CallParticipant,
        id: String,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        customData: [String: RawJSON],
        onViewUpdate: @escaping (CallParticipant, VideoRenderer) -> Void
    ) -> some View {
        CustomVideoCallParticipantView(
            participant: participant,
            id: id,
            availableSize: availableSize,
            contentMode: contentMode,
            onViewUpdate: onViewUpdate
        )
    }
    */
}
