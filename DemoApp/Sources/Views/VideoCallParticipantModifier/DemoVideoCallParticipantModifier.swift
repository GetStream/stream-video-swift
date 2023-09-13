import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoVideoCallParticipantModifier: ViewModifier {

    @State var popoverShown = false
    @State var statsShown = false

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
            .adjustVideoFrame(to: availableSize.width, ratio: ratio)
            .overlay(
                ZStack {
                    BottomView(content: {
                        HStack {
                            ParticipantInfoView(
                                participant: participant,
                                isPinned: participant.isPinned
                            )
                            
                            if showAllInfo {
                                Spacer()
                                ConnectionQualityIndicator(
                                    connectionQuality: participant.connectionQuality
                                )
                            }
                        }
                        .padding(.bottom, 2)
                    })
                    .padding(.all, showAllInfo ? 16 : 8)
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color.blue.opacity(0.7), lineWidth: 2)
                    }
                    
                    if popoverShown {
                        ParticipantPopoverView(
                            participant: participant,
                            call: call,
                            popoverShown: $popoverShown
                        ) {
                            PopoverButton(
                                title: "Show stats",
                                popoverShown: $popoverShown) {
                                    statsShown = true
                                }
                        }
                    }
                    
                    VStack(alignment: .center) {
                        Spacer()
                        if statsShown, let call {
                            ParticipantStatsView(call: call, participant: participant)
                                .padding(.bottom)
                        }
                    }
                }
            )
            .onTapGesture(count: 2, perform: {
                popoverShown = true
            })
            .onTapGesture(count: 1) {
                if popoverShown {
                    popoverShown = false
                }
                if statsShown {
                    statsShown = false
                }
            }
    }
    
    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}
