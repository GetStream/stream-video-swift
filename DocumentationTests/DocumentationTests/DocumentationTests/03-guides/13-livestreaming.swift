//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import StreamVideo
import StreamVideoSwiftUI
import StreamVideoUIKit
import SwiftUI

@MainActor
private func content() {
    container {
        struct HLSPlayerView: View {
            let hlsURL: URL

            var body: some View {
                VideoPlayer(player: AVPlayer(url: hlsURL))
            }
        }
    }

    asyncContainer {
        let response = try await call.startHLS()
        let hlsPlaylistURL = response.playlistUrl
    }

    container {
        struct LivestreamApp: App {
            @State var streamVideo: StreamVideo
            @State var call: Call
            
            init() {
                let streamVideo = StreamVideo(
                    apiKey: apiKey,
                    user: .init(id: "martin"),
                    token: .empty
                )
                let call = streamVideo.call(callType: "livestream", callId: "123")
                self.call = call
                self.streamVideo = streamVideo
            }
            
            var body: some Scene {
                WindowGroup {
                    LivestreamView(state: call.state)
                }
            }
        }
        
        struct LivestreamView: View {
            
            @StateObject var state: CallState
            
            var body: some View {
                VStack {
                    if state.backstage {
                        backstageView
                    } else if state.endedAt != nil {
                        callEndedView
                    } else {
                        livestreamInfoView
                        videoRendererView
                    }
                }
            }
            
            @ViewBuilder
            var backstageView: some View {
                if let startedAt = state.startsAt {
                    Text("Livestream starting at \(startedAt.formatted())")
                } else {
                    Text("Livestream starting soon")
                }
                if let session = state.session {
                    let waitingCount = session.participants.filter({ $0.role != "host" }).count
                    if waitingCount > 0 {
                        Text("\(waitingCount) participants waiting")
                            .font(.headline)
                            .padding(.horizontal)
                    }
                }
            }
            
            @State var recordings: [CallRecording]?
            
            @ViewBuilder
            var callEndedView: some View {
                Text("Call ended")
                    .onAppear {
                        if recordings == nil {
                            Task {
                                do {
                                    recordings = try await call.listRecordings()
                                } catch {
                                    print("Error fetching recordings: \(error)")
                                    recordings = []
                                }
                            }
                        }
                    }

                if let recordings, !recordings.isEmpty {
                    Text("Watch recordings:")
                    ForEach(recordings, id: \.self) { recording in
                        Button {
                            if let url = URL(string: recording.url), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(recording.url)
                        }
                    }
                }
            }
            
            @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

            @ViewBuilder
            var livestreamInfoView: some View {
                HStack {
                    if let duration = formatter.format(state.duration) {
                        Text("Live for \(duration)")
                            .font(.headline)
                            .padding(.horizontal)
                    }

                    Spacer()

                    Text("Live \(state.participantCount)")
                        .bold()
                        .padding(.all, 4)
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .opacity(state.backstage ? 0 : 1)
                        .padding(.horizontal)
                }
            }
            
            @ViewBuilder
            var videoRendererView: some View {
                GeometryReader { reader in
                    if let first = state.participants.first(where: { hostIds.contains($0.userId) }) {
                        VideoRendererView(id: first.id, size: reader.size) { renderer in
                            renderer.handleViewRendering(for: first) { _, _ in }
                        }
                    } else {
                        Text("The host's video is not available")
                    }
                }
                .padding()
            }

            var hostIds: [String] {
                state.members.filter { $0.role == "host" }.map(\.id)
            }
        }
    }
}
