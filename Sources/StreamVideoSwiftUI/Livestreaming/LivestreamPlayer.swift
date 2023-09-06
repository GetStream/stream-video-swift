//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LivestreamPlayer: View {
    
    @Injected(\.colors) var colors
    
    var controlsColor: Color
    var onFullScreenStateChange: ((Bool) -> ())?
    
    @StateObject var state: CallState
    @StateObject var viewModel: LivestreamPlayerViewModel
    
    public init(
        type: String,
        id: String,
        muted: Bool = false,
        showParticipantCount: Bool = true,
        controlsColor: Color = .white,
        onFullScreenStateChange: ((Bool) -> ())? = nil
    ) {
        let viewModel = LivestreamPlayerViewModel(
            type: type,
            id: id,
            muted: muted,
            showParticipantCount: showParticipantCount
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        _state = StateObject(wrappedValue: viewModel.call.state)
        self.controlsColor = controlsColor
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
                                    viewModel: viewModel,
                                    controlsColor: controlsColor
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
                            HStack(spacing: 8) {
                                LiveIndicator(controlsColor: controlsColor)
                                if viewModel.showParticipantCount {
                                    LivestreamParticipantsView(
                                        participantsCount: Int(viewModel.call.state.participantCount)
                                    )
                                }
                                Spacer()
                                LivestreamButton(
                                    imageName: !viewModel.muted ? "speaker.wave.2.fill" : "speaker.slash.fill"
                                ) {
                                    viewModel.toggleAudioOutput()
                                }
                                LivestreamButton(imageName: "viewfinder") {
                                    viewModel.update(fullScreen: !viewModel.fullScreen)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                            .foregroundColor(controlsColor)
                            .overlay(
                                LivestreamDurationView(
                                    duration: viewModel.duration(from: state),
                                    controlsColor: controlsColor
                                )
                            )
                        }
                    }
                }
                .onChange(of: viewModel.fullScreen) { newValue in
                    onFullScreenStateChange?(newValue)
                }
            }
        }
        .onChange(of: state.participants, perform: { newValue in
            if viewModel.muted && newValue.first?.track != nil {
                viewModel.muteLivestreamOnJoin()
            }
        })
        .onAppear {
            viewModel.joinLivestream()
        }
        .alert(isPresented: $viewModel.errorAlertShown, content: {
            return Alert.defaultErrorAlert
        })
    }
}

struct LiveIndicator: View {
    
    @Injected(\.colors) var colors
    var controlsColor: Color
    
    var body: some View {
        Text(L10n.Call.Livestream.live)
            .font(.headline)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundColor(controlsColor)
            .background(colors.primaryButtonBackground)
            .cornerRadius(8)
    }
    
}

struct LivestreamPlayPauseButton: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: LivestreamPlayerViewModel
    var controlsColor: Color
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
                .foregroundColor(controlsColor)
        }

    }
}

struct LivestreamParticipantsView: View {
    
    var participantsCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: "eye")
            Text("\(participantsCount)")
                .font(.headline)
        }
        .padding(.all, 8)
        .cornerRadius(8)
    }
}

struct LivestreamDurationView: View {
    
    let duration: String?
    var controlsColor: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 8)
            
            if let duration {
                Text(duration)
                    .font(.headline.monospacedDigit())
                    .foregroundColor(controlsColor)
            }
        }
    }
}

struct LivestreamButton: View {
    
    private let buttonSize: CGFloat = 32
    
    var imageName: String
    var action: () -> ()
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: imageName)
                .padding(.all, 4)
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
        }
        .padding(.horizontal, 2)        
    }
}
