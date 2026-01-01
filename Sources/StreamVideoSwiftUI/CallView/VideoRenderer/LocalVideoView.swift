//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

public struct LocalVideoView<Factory: ViewFactory>: View {

    @Injected(\.streamVideo) var streamVideo

    private let callSettings: CallSettings
    private var viewFactory: Factory
    private var participant: CallParticipant
    private var idSuffix: String
    private var call: Call?
    private var availableFrame: CGRect

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        idSuffix: String = "local",
        callSettings: CallSettings,
        call: Call?,
        availableFrame: CGRect
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.idSuffix = idSuffix
        self.callSettings = callSettings
        self.call = call
        self.availableFrame = availableFrame
    }

    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: "\(streamVideo.user.id)-\(idSuffix)",
            availableFrame: availableFrame,
            contentMode: .scaleAspectFill,
            customData: [:],
            call: call
        )
        .adjustVideoFrame(to: availableFrame.width, ratio: availableFrame.width / availableFrame.height)
    }
}
