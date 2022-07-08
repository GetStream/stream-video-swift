import SwiftUI
import LiveKit

struct ParticipantView: View {

    var room: VideoRoom
    @ObservedObject var participant: ObservableParticipant

    var onTap: ((_ participant: ObservableParticipant) -> Void)?

    @State private var isRendering: Bool = false
    @State private var dimensions: Dimensions?
    @State private var trackStats: TrackStats?

    var body: some View {
        GeometryReader { geometry in

            ZStack(alignment: .bottom) {
                // Background color
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()

                // VideoView for the Participant
                if let publication = participant.mainVideoPublication,
                   !publication.muted,
                   let track = publication.track as? VideoTrack {
                    ZStack(alignment: .topLeading) {
                        SwiftUIVideoView(track,
                                         layoutMode: .fill,
                                         mirrorMode: .auto,
                                         debugMode: false,
                                         dimensions: $dimensions,
                                         trackStats: $trackStats)
                    }
                } else if let publication = participant.mainVideoPublication as? RemoteTrackPublication,
                          case .notAllowed = publication.subscriptionState {
                    // Show no permission icon
                } else {
                    // Show no camera icon
                }

                VStack(alignment: .trailing, spacing: 0) {
                    // Show the sub-video view
                    if let subVideoTrack = participant.subVideoTrack {
                        SwiftUIVideoView(subVideoTrack,
                                         layoutMode: .fill,
                                         mirrorMode: .auto
                        )
                        .background(Color.black)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(geometry.size.width, geometry.size.height) * 0.3)
                        .cornerRadius(8)
                        .padding()
                    }

                    // Bottom user info bar
                    HStack {
                        Text("\(participant.identity)") //  (\(participant.publish ?? "-"))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Button(action: {
                            room.toggleCameraEnabled()
                        },
                        label: {
                            Image(systemName: "video.fill")
                                .renderingMode(room.cameraTrackState.isPublished ? .original : .template)
                        })
                        // disable while publishing/un-publishing
                        .disabled(room.cameraTrackState.isBusy)

                        if participant.connectionQuality == .excellent {
                            Image(systemName: "wifi")
                                .foregroundColor(.green)
                        } else if participant.connectionQuality == .good {
                            Image(systemName: "wifi")
                                .foregroundColor(Color.orange)
                        } else if participant.connectionQuality == .poor {
                            Image(systemName: "wifi")
                                .foregroundColor(Color.red)
                        }

                    }.padding(5)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color.black.opacity(0.5))
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
        }.gesture(TapGesture()
                    .onEnded { _ in
                        // Pass the tap event
                        onTap?(participant)
                    })
    }
}
