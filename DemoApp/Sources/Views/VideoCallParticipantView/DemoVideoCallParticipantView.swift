//
//  AppVideoCallParticipantView.swift
//  StreamVideoCallApp
//
//  Created by Ilias Pavlidakis on 22/8/23.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

internal struct DemoVideoCallParticipantView: View {

    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    let participant: CallParticipant
    var id: String
    var availableSize: CGSize
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var customData: [String: RawJSON]
    var call: Call?

    init(
        participant: CallParticipant,
        id: String? = nil,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        customData: [String: RawJSON],
        call: Call?
    ) {
        self.participant = participant
        self.id = id ?? participant.id
        self.availableSize = availableSize
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.customData = customData
        self.call = call
    }

    var body: some View {
        VideoCallParticipantView(
            participant: participant,
            id: id,
            availableSize: availableSize,
            contentMode: contentMode,
            customData: customData,
            call: call
        )
        .modifier(ReactionsViewModifier(participant: participant, availableSize: availableSize))
    }
}
