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
        struct HLSStreamView: View {
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

    asyncContainer {
        try await call.join()

        if case .hls = call.state.playbackType {
            print("This viewer plays HLS")
        }
    }

    viewContainer {
        HLSVideoRendererView(call: call)
    }

    // Before: a viewer that shows the hosts over WebRTC.
    container {
        struct LivestreamView: View {
            let call: Call
            @ObservedObject var state: CallState

            var body: some View {
                GeometryReader { reader in
                    ParticipantsGridLayout(
                        call: call,
                        participants: state.participants,
                        availableFrame: reader.frame(in: .local),
                        onChangeTrackVisibility: { participant, isVisible in
                            Task {
                                await call.changeTrackVisibility(for: participant, isVisible: isVisible)
                            }
                        }
                    )
                }
            }
        }
    }

    // After: the same viewer with HLS. Lines that changed start with `HLS:`.
    container {
        struct LivestreamView: View {
            let call: Call
            @ObservedObject var state: CallState

            var body: some View {
                // HLS: switch on the playback type.
                switch state.playbackType {
                // HLS: show the HLS stream.
                case .hls:
                    // HLS: one renderer shows all hosts.
                    HLSVideoRendererView(call: call)
                // HLS: keep the WebRTC view for everything else.
                default:
                    GeometryReader { reader in
                        ParticipantsGridLayout(
                            call: call,
                            participants: state.participants,
                            availableFrame: reader.frame(in: .local),
                            onChangeTrackVisibility: { participant, isVisible in
                                Task {
                                    await call.changeTrackVisibility(for: participant, isVisible: isVisible)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    container {
        struct LivestreamView: View {
            let call: Call
            @ObservedObject var state: CallState

            var body: some View {
                switch state.playbackType {
                case .hls:
                    HLSVideoRendererView(call: call)
                default:
                    WebRTCLivestreamView(call: call)
                }
            }
        }
    }

    container {
        struct CustomHLSView: View {
            let call: Call
            @ObservedObject var state: CallState
            @State private var player: HLSPlayer?

            var body: some View {
                VideoPlayer(player: player)
                    // Ask again when the stream changes, or when the host
                    // returns from backstage.
                    .task(id: "\(state.playbackType) \(state.backstage)") {
                        player = await call.hlsPlayer()
                    }
            }
        }
    }

    asyncContainer {
        try await call.speaker.disableAudioOutput()
    }

    asyncContainer {
        let player = await call.hlsPlayer()
        player?.pause()
        player?.play()
        player?.playFromLiveEdge()
        player?.resumeFromLive = false
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

/// The WebRTC view of an existing app. The HLS examples use it as a stand-in.
private struct WebRTCLivestreamView: View {
    let call: Call

    var body: some View {
        EmptyView()
    }
}
