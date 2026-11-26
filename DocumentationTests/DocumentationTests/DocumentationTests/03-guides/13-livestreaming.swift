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

        if case .hls(let url) = call.state.playbackType {
            print("The backend granted HLS playback from \(url)")
        }
    }

    container {
        struct LivestreamViewer: View {
            let call: Call
            @StateObject var state: CallState
            @State private var isMuted = false
            @State private var isPaused = false
            @State private var playback: HLSPlayback

            init(call: Call) {
                self.call = call
                _state = StateObject(wrappedValue: call.state)
                _playback = State(wrappedValue: HLSPlayback(call: call))
            }

            var body: some View {
                VStack {
                    videoView
                    controls
                }
                // Runs on appear, and again every time playbackType changes.
                .task(id: state.playbackType) { await applyControls() }
                .onDisappear { Task { await playback.release() } }
            }

            @ViewBuilder
            private var videoView: some View {
                switch state.playbackType {
                case .hls:
                    HLSVideoRendererView(call: call)
                default:
                    webRTCVideoView
                }
            }

            private var host: CallParticipant? {
                state.participants.first { $0.roles.contains("host") }
            }

            @ViewBuilder
            private var webRTCVideoView: some View {
                GeometryReader { reader in
                    if let host {
                        VideoRendererView(id: host.id, size: reader.size) { renderer in
                            renderer.handleViewRendering(for: host) { _, _ in }
                        }
                    } else {
                        Text("The host's video is not available")
                    }
                }
            }

            private var controls: some View {
                HStack(spacing: 24) {
                    Button {
                        Task { await setMuted(!isMuted) }
                    } label: {
                        Label(
                            isMuted ? "Unmute" : "Mute",
                            systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
                        )
                    }
                    Button {
                        Task { await setPaused(!isPaused) }
                    } label: {
                        Label(
                            isPaused ? "Resume" : "Pause",
                            systemImage: isPaused ? "play.fill" : "pause.fill"
                        )
                    }
                }
                .padding()
            }

            private func setMuted(_ muted: Bool) async {
                isMuted = muted
                if case .hls = state.playbackType {
                    await playback.setMuted(muted)
                } else {
                    do {
                        if muted {
                            try await call.speaker.disableAudioOutput()
                        } else {
                            try await call.speaker.enableAudioOutput()
                        }
                    } catch {
                        print("Could not change the audio output: \(error)")
                    }
                }
            }

            private func setPaused(_ paused: Bool) async {
                isPaused = paused
                if case .hls = state.playbackType {
                    await playback.setPaused(paused)
                } else {
                    host?.track?.isEnabled = !paused
                }
            }

            /// Applies the controls to the mode that is active now.
            private func applyControls() async {
                if case .hls = state.playbackType {
                    // A new HLS player starts unmuted and playing.
                    // acquire() makes sure that the player exists.
                    guard await playback.acquire() != nil else { return }
                    await playback.setMuted(isMuted)
                    if isPaused { await playback.setPaused(true) }
                } else {
                    await playback.release()
                    await setMuted(isMuted)
                    host?.track?.isEnabled = !isPaused
                }
            }
        }
    }

    container {
        struct CustomHLSView: View {
            let call: Call
            @StateObject var state: CallState
            @State private var player: AVPlayer?
            @State private var playback: HLSPlayback

            init(call: Call) {
                self.call = call
                _state = StateObject(wrappedValue: call.state)
                _playback = State(wrappedValue: HLSPlayback(call: call))
            }

            var body: some View {
                Group {
                    if let player {
                        VideoPlayer(player: player)
                    }
                }
                .task(id: state.playbackType) {
                    player = await playback.acquire()
                }
                .onDisappear {
                    Task { await playback.release() }
                }
            }
        }
    }

    asyncContainer {
        let playback = HLSPlayback(call: call)
        await playback.setMuted(true)
        await playback.setPaused(true)
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
