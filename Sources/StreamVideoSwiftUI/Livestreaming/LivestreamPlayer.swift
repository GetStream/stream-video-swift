//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LivestreamPlayer: View {
    
    @Injected(\.colors) var colors
    
    var onFullScreenStateChange: ((Bool) -> ())?
    
    @StateObject var state: CallState
    @StateObject var viewModel: LivestreamPlayerViewModel
    
    public init(
        type: String,
        id: String,
        audioOn: Bool = false,
        showParticipantCount: Bool = true,
        onFullScreenStateChange: ((Bool) -> ())? = nil
    ) {
        let viewModel = LivestreamPlayerViewModel(
            type: type,
            id: id,
            audioOn: audioOn,
            showParticipantCount: showParticipantCount
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        _state = StateObject(wrappedValue: viewModel.call.state)
        self.onFullScreenStateChange = onFullScreenStateChange
    }
    
    public var body: some View {
        ZStack {
            if viewModel.loading {
                ProgressView()
            } else if state.backstage {
                Text(L10n.Call.Livestream.notStarted)
            } else {
                ZStack {
                    GeometryReader { reader in
                        if let participant = state.participants.first {
                            VideoCallParticipantView(
                                participant: participant,
                                availableSize: reader.size,
                                contentMode: .scaleAspectFit,
                                customData: [:],
                                call: viewModel.call
                            )
                            .onTapGesture {
                                viewModel.update(controlsShown: true)
                            }
                            .overlay(
                                viewModel.controlsShown ? LivestreamPlayPauseButton(
                                    viewModel: viewModel
                                ) {
                                    participant.track?.isEnabled = !viewModel.streamPaused
                                    if !viewModel.streamPaused {
                                        viewModel.update(controlsShown: false)
                                    }
                                } : nil
                            )
                        }
                    }

                    if viewModel.controlsShown || !viewModel.fullScreen {
                        VStack {
                            Spacer()
                            HStack(spacing: 16) {
                                LivestreamDurationView(duration: viewModel.duration(from: state))
                                if viewModel.showParticipantCount {
                                    LivestreamParticipantsView(
                                        participantsCount: Int(viewModel.call.state.participantCount)
                                    )
                                }                                
                                Spacer()
                                FullScreenButton(viewModel: viewModel)
                            }
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(colors.text)
                        }
                    }
                }
                .onChange(of: viewModel.fullScreen) { newValue in
                    onFullScreenStateChange?(newValue)
                }
            }
        }
        .onAppear {
            viewModel.joinLivestream()
        }
        .alert(isPresented: $viewModel.errorAlertShown, content: {
            return Alert.defaultErrorAlert
        })
    }
}

struct LivestreamPlayPauseButton: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: LivestreamPlayerViewModel
    var trackUpdate: () -> ()
    
    var body: some View {
        Button {
            viewModel.update(streamPaused: !viewModel.streamPaused)
            trackUpdate()
        } label: {
            Image(systemName: viewModel.streamPaused ? "play.fill" : "pause.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60)
                .foregroundColor(colors.text)
        }

    }
    
}

struct LivestreamParticipantsView: View {
    
    var participantsCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: "person")
            Text("\(participantsCount)")
                .font(.headline)
        }
        .padding(.all, 8)
        .background(Color.black.opacity(0.4))
        .cornerRadius(8)
    }
    
}

struct LivestreamDurationView: View {
    
    let duration: String?
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 8)
            
            if let duration {
                Text(duration)
                    .font(.headline.monospacedDigit())
            }
        }
    }
}

struct FullScreenButton: View {
    
    @ObservedObject var viewModel: LivestreamPlayerViewModel
    
    var body: some View {
        Button {
            withAnimation {
                viewModel.update(fullScreen: !viewModel.fullScreen)
            }
        } label: {
            Image(systemName: "viewfinder")
                .padding(.all, 8)
        }
    }
}
