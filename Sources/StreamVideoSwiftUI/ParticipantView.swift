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

                    // Bottom user info bar
                    HStack {
                        Text("\(participant.name)")
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Button(action: {
                            viewModel.toggleCameraEnabled()
                        },
                        label: {
                            Image(systemName: "video.fill")
                                .renderingMode(viewModel.cameraTrackState.isPublished ? .original : .template)
                        })
                        .disabled(viewModel.cameraTrackState.isBusy)

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
