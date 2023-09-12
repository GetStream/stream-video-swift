//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

internal struct DemoVideoCallParticipantView: View {

    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
    
    @State var statsShown = false

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
        .overlay(
            VStack(alignment: .center) {
                Spacer()
                if statsShown, let call {
                    ParticipantStatsView(call: call, participant: participant)
                }
                Button {
                    statsShown.toggle()
                } label: {
                    if let image = UIImage(systemName: "waveform.path.ecg.rectangle") {
                        CallIconView(icon: Image(uiImage: image))
                    } else {
                        Text("Stats")
                            .bold()
                    }
                }
                .padding(.bottom, 32)
            }
        )
    }
}
