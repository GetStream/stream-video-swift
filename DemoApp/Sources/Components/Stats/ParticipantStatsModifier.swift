//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct ParticipantStatsModifier: ViewModifier {

    @State private var presentStats = false

    var call: Call?
    var participant: CallParticipant

    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        contentView
                    }

                    Spacer()
                }
                .padding(6)
            )
    }

    @ViewBuilder
    private var contentView: some View {
        if call != nil {
            Button {
                presentStats = true
            } label: {
                Image(systemName: "info")
                    .foregroundColor(.white)
                    .padding(9)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .clipped()
            }
            .popover(isPresented: $presentStats) {
                if let call {
                    NavigationView {
                        Group {
                            GeometryReader { proxy in
                                if proxy.frame(in: .global) != .zero {
                                    ParticipantStatsView(
                                        call: call,
                                        participant: participant,
                                        presentationBinding: $presentStats,
                                        availableFrame: proxy.frame(in: .global)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(minWidth: 300, minHeight: 400)
                }
            }
        } else {
            EmptyView()
        }
    }
}

extension View {

    @ViewBuilder
    func participantStats(
        call: Call?,
        participant: CallParticipant
    ) -> some View {
        modifier(ParticipantStatsModifier(call: call, participant: participant))
    }
}
