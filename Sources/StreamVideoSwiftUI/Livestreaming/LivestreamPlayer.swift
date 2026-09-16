//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamCoreUI
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
    
    @Injected(\.videoAppearance) var videoAppearance

    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    var viewFactory: Factory
    
    /// The policy that defines how users join the livestream.
    var joinPolicy: JoinPolicy
    
    /// Indicates whether a button to leave the livestream is shown.
    var showsLeaveCallButton: Bool
    
    /// A callback triggered when the fullscreen state changes.
    var onFullScreenStateChange: ((Bool) -> Void)?
    
    /// The state object representing the call's current state.
    @ObservedObject var state: CallState
    
    @State var call: Call
    
    @State var muted: Bool = false
    
    @State var mutedOnJoin = false
    
    @State var controlsShown = false
    
    @State var streamPaused = false
    
    @State var fullScreen = false
    
    @State var showParticipantCount: Bool
    
    @State var timerCancellable: AnyCancellable?
    
    @State var countdown: TimeInterval
    
    @State var livestreamState: LivestreamState

    @State var controlsTask: Task<Void, Never>?
    
    @State var recordings: [CallRecording]?

    private let disposableBag = DisposableBag()

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
        let call = InjectedValues[\.streamVideo].call(callType: type, callId: id)
        self.call = call
        livestreamState = LivestreamState(call: call)
        countdown = 0
        self.muted = muted
        self.showParticipantCount = showParticipantCount
        _state = ObservedObject(wrappedValue: call.state)
        self.joinPolicy = joinPolicy
        self.showsLeaveCallButton = showsLeaveCallButton
        self.onFullScreenStateChange = onFullScreenStateChange
        call.updateParticipantsSorting(with: livestreamOrAudioRoomSortPreset)
    }
    
    internal init(
        viewFactory: Factory = DefaultViewFactory.shared,
        call: Call,
        countdown: TimeInterval = 0,
        livestreamState: LivestreamState? = nil,
        muted: Bool = false,
        showParticipantCount: Bool = true,
        joinPolicy: JoinPolicy = .auto,
        showsLeaveCallButton: Bool = false,
        recordings: [CallRecording]? = nil,
        onFullScreenStateChange: ((Bool) -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        self.call = call
        self.countdown = countdown
        self.livestreamState = livestreamState ?? LivestreamState(call: call)
        self.muted = muted
        self.recordings = recordings
        self.showParticipantCount = showParticipantCount
        _state = ObservedObject(wrappedValue: call.state)
        self.joinPolicy = joinPolicy
        self.showsLeaveCallButton = showsLeaveCallButton
        self.onFullScreenStateChange = onFullScreenStateChange
        call.updateParticipantsSorting(with: livestreamOrAudioRoomSortPreset)
    }
    
    public var body: some View {
        ZStack {
            if livestreamState == .error {
                errorView
            } else if livestreamState == .joining {
                loadingView
            } else if livestreamState == .backstage {
                notStartedView
            } else if livestreamState == .ended {
                endedView
            } else {
                videoRenderer
                livestreamControls
            }
        }
        .onChange(of: state.participants, perform: { newValue in
            if muted && (newValue.first(where: { $0.hasVideo && $0.track != nil }) != nil) {
                muteLivestreamOnJoin()
            }
        })
        .onChange(of: call.state.backstage) { _ in
            livestreamState = LivestreamState(call: call)
            if
                let startsAt = state.startsAt,
                livestreamState == .backstage,
                timerCancellable == nil {
                timerCancellable = Foundation
                    .Timer
                    .publish(every: 1, on: .main, in: .default)
                    .autoconnect()
                    .sinkTask(storeIn: disposableBag) { @MainActor _ in
                        countdown = startsAt.timeIntervalSinceNow
                        if countdown <= 0 {
                            stopTimer()
                            countdown = 0
                        }
                    }
            } else if livestreamState == .live {
                stopTimer()
            }
        }
        .onChange(of: controlsShown) { _ in
            if controlsShown {
                controlsTask?.cancel()
                controlsTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    try? Task.checkCancellation()
                    if !streamPaused {
                        self.controlsShown = false
                    }
                }
            }
        }
        .onAppear {
            switch joinPolicy {
            case .none:
                break
            case .auto:
                joinLivestream()
            }
        }
        .onDisappear {
            switch joinPolicy {
            case .none:
                break
            case .auto:
                leaveLivestream()
            }
        }
    }
    
    func toggleAudioOutput() {
        Task(disposableBag: disposableBag) {
            do {
                if !muted {
                    try await call.speaker.disableAudioOutput()
                } else {
                    try await call.speaker.enableAudioOutput()
                }
                muted.toggle()
            } catch {
                log.error(error)
            }
        }
    }
    
    func muteLivestreamOnJoin() {
        guard !mutedOnJoin else { return }
        Task(disposableBag: disposableBag) {
            do {
                try await call.speaker.disableAudioOutput()
                mutedOnJoin = true
            } catch {
                log.error(error)
            }
        }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var errorView: some View {
        Text(L10n.Call.Livestream.error)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(tokens.colors.textPrimary))
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }
    
    @ViewBuilder
    private var notStartedView: some View {
        VStack(spacing: tokens.layout.spacingMd) {
            if countdown > 0 {
                Text(L10n.Call.Livestream.countdown)
                Text(formatter.format(countdown) ?? "")
                    .font(tokens.fonts.title.monospacedDigit())
                    .bold()
            } else {
                Text(L10n.Call.Livestream.notStarted)
                    .multilineTextAlignment(.center)
            }
            if let session = state.session {
                let waitingCount = session.participants.count
                if waitingCount > 0 {
                    Text("\(waitingCount) \(L10n.Call.Livestream.earlyParticipants)")
                        .font(tokens.fonts.subheadline)
                        .foregroundColor(
                            Color(tokens.colors.textSecondary)
                        )
                }
            }
        }
        .foregroundColor(Color(tokens.colors.textPrimary))
        .padding(tokens.layout.spacingMd)
    }
    
    @ViewBuilder
    private var endedView: some View {
        VStack(spacing: tokens.layout.spacing2xl) {
            Text(L10n.Call.Livestream.ended)
                .multilineTextAlignment(.center)
                .foregroundColor(
                    Color(tokens.colors.textPrimary)
                )
                .onAppear {
                    if recordings == nil {
                        Task {
                            do {
                                recordings = try await call.listRecordings()
                            } catch {
                                log.error("Error fetching recordings: \(error)")
                                recordings = []
                            }
                        }
                    }
                }
            
            if let recordings, !recordings.isEmpty {
                VStack(spacing: tokens.layout.spacingXs) {
                    Text(L10n.Call.Livestream.recordings)
                        .font(tokens.fonts.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(
                            Color(tokens.colors.textPrimary)
                        )
                    
                    ForEach(recordings, id: \.self) { recording in
                        Button {
                            if let url = URL(string: recording.url), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(recording.url)
                                .font(tokens.fonts.subheadline)
                                .foregroundColor(
                                    Color(tokens.colors.textSecondary)
                                )
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var videoRenderer: some View {
        GeometryReader { reader in
            if let participant = state.participants.first(where: { $0.track != nil }) {
                VideoCallParticipantView(
                    viewFactory: viewFactory,
                    participant: participant,
                    availableFrame: reader.frame(in: .global),
                    contentMode: .scaleAspectFit,
                    customData: [:],
                    call: call
                )
                .onTapGesture {
                    controlsShown = true
                }
                .overlay(
                    controlsShown ? LivestreamPlayPauseButton(
                        streamPaused: $streamPaused
                    ) {
                        participant.track?.isEnabled = !streamPaused
                        if !streamPaused {
                            controlsShown = false
                        }
                    } : nil
                )
            } else {
                VStack(alignment: .center) {
                    Text(L10n.Call.Livestream.hostVideoUnavailable)
                        .multilineTextAlignment(.center)
                        .foregroundColor(
                            Color(tokens.colors.textPrimary)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(tokens.layout.spacingMd)
            }
        }
        .onChange(of: fullScreen) { onFullScreenStateChange?($0) }
    }
    
    @ViewBuilder
    private var livestreamControls: some View {
        if controlsShown || !fullScreen {
            VStack {
                Spacer()
                HStack(spacing: tokens.layout.spacingXs) {
                    LiveIndicator()
                    if showParticipantCount {
                        LivestreamParticipantsView(
                            participantsCount:
                            Int(state.participantCount)
                        )
                    }
                    Spacer()
                    LivestreamButton(
                        imageName: !muted
                            ? "speaker.wave.2.fill"
                            : "speaker.slash.fill"
                    ) {
                        toggleAudioOutput()
                    }
                    LivestreamButton(imageName: "viewfinder") {
                        fullScreen.toggle()
                    }
                    if showsLeaveCallButton {
                        LivestreamButton(
                            imageName: "phone.down.fill"
                        ) {
                            leaveLivestream()
                        }
                    }
                }
                .padding(tokens.layout.spacingMd)
                .background(
                    Color(tokens.colors.backgroundCoreOverlayDark)
                        .edgesIgnoringSafeArea(.all)
                )
                .foregroundColor(
                    Color(tokens.colors.textOnAccent)
                )
                .overlay(
                    LivestreamDurationView(
                        duration: formatter.format(state.duration)
                    )
                )
            }
        }
    }
    
    func joinLivestream() {
        Task(disposableBag: disposableBag) {
            do {
                livestreamState = .joining
                try await call.join(callSettings: CallSettings(audioOn: false, videoOn: false))
                livestreamState = call.state.backstage ? .backstage : .live
            } catch {
                livestreamState = .error
                log.error("Error joining livestream")
            }
        }
    }
    
    func leaveLivestream() {
        call.leave()
        disposableBag.removeAll()
        livestreamState = .initial
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct LiveIndicator: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
    var body: some View {
        Text(L10n.Call.Livestream.live)
            .font(tokens.fonts.headline)
            .padding(.vertical, tokens.layout.spacingXxs)
            .padding(.horizontal, tokens.layout.spacingXs)
            .foregroundColor(
                Color(tokens.colors.textOnAccent)
            )
            .background(
                Color(tokens.colors.buttonPrimaryBackground)
            )
            .cornerRadius(tokens.layout.radiusMd)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct LivestreamPlayPauseButton: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
    @Binding var streamPaused: Bool
    var trackUpdate: () -> Void
    
    var body: some View {
        Button {
            streamPaused = !streamPaused
            trackUpdate()
        } label: {
            Image(systemName: streamPaused ? "play.fill" : "pause.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60)
                .foregroundColor(
                    Color(videoAppearance.tokens.colors.textOnAccent)
                )
        }
    }
}

struct LivestreamParticipantsView: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
    var participantsCount: Int
    
    var body: some View {
        HStack(spacing: tokens.layout.spacingXxs) {
            Image(systemName: "eye")
            Text("\(participantsCount)")
                .font(tokens.fonts.headline)
        }
        .padding(.all, tokens.layout.spacingXs)
        .cornerRadius(tokens.layout.radiusMd)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct LivestreamDurationView: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
    let duration: String?
    
    var body: some View {
        HStack(spacing: tokens.layout.spacingXxs) {
            Circle()
                .fill(Color(tokens.colors.accentError))
                .frame(
                    width: tokens.layout.spacingXs,
                    height: tokens.layout.spacingXs
                )
            
            if let duration {
                Text(duration)
                    .font(tokens.fonts.headline.monospacedDigit())
                    .foregroundColor(
                        Color(tokens.colors.textOnAccent)
                    )
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct LivestreamButton: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    
    var imageName: String
    var action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            Image(systemName: imageName)
                .padding(.all, tokens.layout.spacingXxs)
                .frame(
                    width: tokens.layout.iconSizeLg,
                    height: tokens.layout.iconSizeLg
                )
                .background(
                    Color(tokens.colors.backgroundCoreOverlayDarkStrong)
                )
                .cornerRadius(tokens.layout.radiusMd)
        }
        .padding(.horizontal, tokens.layout.spacingXxxs)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

enum LivestreamState {
    case initial
    case backstage
    case live
    case error
    case joining
    case ended
}

extension LivestreamState {
    @MainActor init(call: Call) {
        if call.state.backstage == true {
            self = .backstage
        } else if call.state.endedAt != nil {
            self = .ended
        } else {
            self = .live
        }
    }
}

extension LivestreamState {
    var canJoinCall: Bool {
        switch self {
        case .backstage, .error, .initial:
            return true
        default:
            return false
        }
    }
}
