//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A SwiftUI view that renders a livestream video player for managing and
/// displaying a livestream.
///
/// `LivestreamPlayer` provides features such as participant video rendering,
/// audio output toggling, fullscreen mode, and participant count display.
/// The view reacts dynamically to the state of the associated call and allows
/// customisation of its behaviour through policies and callback actions.
@available(iOS 14.0, *)
public struct LivestreamPlayer<Factory: ViewFactory>: View {

    /// Determines the join behavior for the livestream.
    public enum JoinPolicy {
        /// No automatic action; users must manually join the livestream.
        case none
        /// Automatically joins the livestream on appearance and leave on disappearance.
        case auto
    }

    /// Accesses the color palette from the app's dependency injection.
    @Injected(\.colors) var colors

    var viewFactory: Factory

    /// The policy that defines how users join the livestream.
    var joinPolicy: JoinPolicy

    /// Indicates whether a button to leave the livestream is shown.
    var showsLeaveCallButton: Bool

    /// A callback triggered when the fullscreen state changes.
    var onFullScreenStateChange: ((Bool) -> Void)?

    /// The state object representing the call's current state.
    @StateObject var state: CallState

    /// The view model managing the livestream's behavior and state.
    @StateObject var viewModel: LivestreamPlayerViewModel

    /// Initializes a `LivestreamPlayer` with the specified parameters.
    ///
    /// - Parameters:
    ///   - type: The type of the livestream (e.g., meeting or webinar).
    ///   - id: The unique identifier for the livestream.
    ///   - muted: Indicates whether the livestream starts muted. Defaults to `false`.
    ///   - showParticipantCount: Whether to show the count of participants. Defaults to `true`.
    ///   - joinPolicy: The policy dictating how users join the livestream. Defaults to `.auto`.
    ///   - showsLeaveCallButton: Whether to show a button to leave the call. Defaults to `false`.
    ///   - onFullScreenStateChange: A callback for fullscreen state changes.
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        type: String,
        id: String,
        muted: Bool = false,
        showParticipantCount: Bool = true,
        joinPolicy: JoinPolicy = .auto,
        showsLeaveCallButton: Bool = false,
        onFullScreenStateChange: ((Bool) -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        let viewModel = LivestreamPlayerViewModel(
            type: type,
            id: id,
            muted: muted,
            showParticipantCount: showParticipantCount
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        _state = StateObject(wrappedValue: viewModel.call.state)
        self.joinPolicy = joinPolicy
        self.showsLeaveCallButton = showsLeaveCallButton
        self.onFullScreenStateChange = onFullScreenStateChange
    }

    public var body: some View {
        ZStack {
            if viewModel.errorShown {
                Text(L10n.Call.Livestream.error)
            } else if viewModel.loading {
                ProgressView()
            } else if state.backstage {
                Text(L10n.Call.Livestream.notStarted)
            } else {
                ZStack {
                    GeometryReader { reader in
                        if let participant = state.participants.first {
                            VideoCallParticipantView(
                                viewFactory: viewFactory,
                                participant: participant,
                                availableFrame: reader.frame(in: .global),
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
                                    participant.track?.isEnabled =
                                        !viewModel.streamPaused
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
                                LiveIndicator()
                                if viewModel.showParticipantCount {
                                    LivestreamParticipantsView(
                                        participantsCount:
                                        Int(
                                            viewModel.call.state
                                                .participantCount
                                        )
                                    )
                                }
                                Spacer()
                                LivestreamButton(
                                    imageName: !viewModel.muted
                                        ? "speaker.wave.2.fill"
                                        : "speaker.slash.fill"
                                ) {
                                    viewModel.toggleAudioOutput()
                                }
                                LivestreamButton(imageName: "viewfinder") {
                                    viewModel.update(
                                        fullScreen:
                                        !viewModel.fullScreen
                                    )
                                }
                                if showsLeaveCallButton {
                                    LivestreamButton(
                                        imageName: "phone.down.fill"
                                    ) {
                                        viewModel.leaveLivestream()
                                    }
                                }
                            }
                            .padding()
                            .background(
                                colors.livestreamBackground
                                    .edgesIgnoringSafeArea(.all)
                            )
                            .foregroundColor(colors.livestreamCallControlsColor)
                            .overlay(
                                LivestreamDurationView(
                                    duration: viewModel.duration(from: state)
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
            switch joinPolicy {
            case .none:
                break
            case .auto:
                viewModel.joinLivestream()
            }
        }
        .onDisappear {
            switch joinPolicy {
            case .none:
                break
            case .auto:
                viewModel.leaveLivestream()
            }
        }
    }
}

struct LiveIndicator: View {
    
    @Injected(\.colors) var colors
    
    var body: some View {
        Text(L10n.Call.Livestream.live)
            .font(.headline)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .foregroundColor(colors.livestreamCallControlsColor)
            .background(colors.primaryButtonBackground)
            .cornerRadius(8)
    }
}

struct LivestreamPlayPauseButton: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: LivestreamPlayerViewModel
    var trackUpdate: () -> Void
    
    var body: some View {
        Button {
            viewModel.update(streamPaused: !viewModel.streamPaused)
            trackUpdate()
        } label: {
            Image(systemName: viewModel.streamPaused ? "play.fill" : "pause.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60)
                .foregroundColor(colors.livestreamCallControlsColor)
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
    
    @Injected(\.colors) var colors
    
    let duration: String?
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 8)
            
            if let duration {
                Text(duration)
                    .font(.headline.monospacedDigit())
                    .foregroundColor(colors.livestreamCallControlsColor)
            }
        }
    }
}

struct LivestreamButton: View {
    
    @Injected(\.colors) var colors

    private let buttonSize: CGFloat = 32
    
    var imageName: String
    var action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: imageName)
                .padding(.all, 4)
                .frame(width: buttonSize, height: buttonSize)
                .background(colors.participantInfoBackgroundColor)
                .cornerRadius(8)
        }
        .padding(.horizontal, 2)
    }
}
