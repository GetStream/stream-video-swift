//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct ParticipantView: View {

    @ObservedObject var viewModel: CallViewModel
    var participant: RoomParticipant

    var onTap: ((_ participant: RoomParticipant) -> Void)?

    @State private var isRendering: Bool = false

    var body: some View {
        GeometryReader { geometry in

            ZStack(alignment: .bottom) {
                // Background color
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()

                // VideoView for the Participant
                if let publication = participant.mainVideoPublication,
                   !publication.muted,
                   let track = publication.track as? StreamVideoTrack {
                    ZStack(alignment: .topLeading) {
                        StreamVideoView(track)
                    }
                } else if let publication = participant.mainVideoPublication as? StreamRemoteTrackPublication,
                          case .notAllowed = publication.subscriptionState {
                    // Show no permission icon
                } else {
                    // Show no camera icon
                }

                VStack(alignment: .trailing, spacing: 0) {
                    // Show the sub-video view
                    if let subVideoTrack = participant.subVideoTrack {
                        StreamVideoView(subVideoTrack)
                            .background(Color.black)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.3)
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .cornerRadius(8)
            // Glow the border when the participant is speaking
            .overlay(
                participant.isSpeaking ?
                    RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.blue, lineWidth: 5.0)
                    : nil
            )
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    // Pass the tap event
                    onTap?(participant)
                }
        )
    }
}
