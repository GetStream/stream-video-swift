//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct CallParticipantsView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    @State private var contentSize: CGSize = .zero
    
    var maxWidth: CGFloat?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                CallParticipantsSection(
                    participants: viewModel.onlineParticipants,
                    sectionTitle: "On the call"
                )
                
                CallParticipantsSection(
                    participants: viewModel.offlineParticipants,
                    sectionTitle: "Offline"
                )
            }
            .padding()
            .overlay(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        contentSize = geo.size
                    }
                }
            )
        }
        .modifier(ShadowViewModifier())
        .frame(maxWidth: maxWidth, maxHeight: contentSize.height)
    }
}

struct CallParticipantsSection: View {
    
    var participants: [CallParticipant]
    var sectionTitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sectionTitle)
                .font(.title2)
            ForEach(participants) { participant in
                CallParticipantView(participant: participant)
            }
        }
        .foregroundColor(.white)
    }
    
}

struct CallParticipantView: View {
    
    var participant: CallParticipant
    
    var body: some View {
        HStack {
            Text(participant.name)
            Spacer()
            if participant.isOnline {
                Image(systemName: participant.hasAudio ? "mic" : "mic.slash")
                Image(systemName: participant.hasVideo ? "video" : "video.slash")
            }
        }
    }
    
}
