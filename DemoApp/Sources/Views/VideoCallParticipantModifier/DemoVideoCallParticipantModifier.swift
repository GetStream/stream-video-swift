import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoVideoCallParticipantModifier: ViewModifier {

    @State var popoverShown = false

    var participant: CallParticipant
    var call: Call?
    var availableSize: CGSize
    var ratio: CGFloat
    var showAllInfo: Bool

    init(
        participant: CallParticipant,
        call: Call?,
        availableSize: CGSize,
        ratio: CGFloat,
        showAllInfo: Bool
    ) {
        self.participant = participant
        self.call = call
        self.availableSize = availableSize
        self.ratio = ratio
        self.showAllInfo = showAllInfo
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                VideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableSize: availableSize,
                    ratio: ratio,
                    showAllInfo: showAllInfo
                ))
            .modifier(ReactionsViewModifier(participant: participant, availableSize: availableSize))
    }
}
