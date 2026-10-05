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
    
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
            .foregroundColor(Color(colors.textPrimary))
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }
    
    @ViewBuilder
    private var notStartedView: some View {
        VStack(spacing: layout.spacingMd) {
            if countdown > 0 {
                Text(L10n.Call.Livestream.countdown)
                Text(formatter.format(countdown) ?? "")
                    .font(fonts.title.monospacedDigit())
                    .bold()
            } else {
                Text(L10n.Call.Livestream.notStarted)
                    .multilineTextAlignment(.center)
            }
            if let session = state.session {
                let waitingCount = session.participants.count
                if waitingCount > 0 {
                    Text("\(waitingCount) \(L10n.Call.Livestream.earlyParticipants)")
                        .font(fonts.subheadline)
                        .foregroundColor(
                            Color(colors.textSecondary)
                        )
                }
            }
        }
        .foregroundColor(Color(colors.textPrimary))
        .padding(layout.spacingMd)
    }
    
    @ViewBuilder
    private var endedView: some View {
        VStack(spacing: layout.spacing2xl) {
            Text(L10n.Call.Livestream.ended)
                .multilineTextAlignment(.center)
                .foregroundColor(
                    Color(colors.textPrimary)
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
                VStack(spacing: layout.spacingXs) {
                    Text(L10n.Call.Livestream.recordings)
                        .font(fonts.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(
                            Color(colors.textPrimary)
                        )
                    
                    ForEach(recordings, id: \.self) { recording in
                        Button {
                            if let url = URL(string: recording.url), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(recording.url)
                                .font(fonts.subheadline)
                                .foregroundColor(
                                    Color(colors.textSecondary)
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
                VStack(alignment: .center, spacing: layout.spacingXs) {
                    Text(L10n.Call.Livestream.hostVideoUnavailable)
                        .multilineTextAlignment(.center)
                        .foregroundColor(
                            Color(colors.textPrimary)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(layout.spacingMd)
            }
        }
        .onChange(of: fullScreen) { onFullScreenStateChange?($0) }
    }
    
    @ViewBuilder
    private var livestreamControls: some View {
        if controlsShown || !fullScreen {
            VStack(spacing: layout.spacingXs) {
                Spacer()
                HStack(spacing: layout.spacingXs) {
                    LiveIndicator()
                    if showParticipantCount {
                        LivestreamParticipantsView(
                            participantsCount:
                            Int(state.participantCount)
                        )
                    }
                    Spacer()
                    LivestreamButton(
                        image: muted
                            ? images.speakerOff
                            : images.speakerWave
                    ) {
                        toggleAudioOutput()
                    }
                    LivestreamButton(image: images.viewfinder) {
                        fullScreen.toggle()
                    }
                    if showsLeaveCallButton {
                        LivestreamButton(
                            image: images.hangup
                        ) {
                            leaveLivestream()
                        }
                    }
                }
                .padding(layout.spacingMd)
                .background(
                    Color(colors.backgroundCoreOverlayDark)
                        .edgesIgnoringSafeArea(.all)
                )
                .foregroundColor(
                    Color(colors.textOnAccent)
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
}

struct LiveIndicator: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    var body: some View {
        Text(L10n.Call.Livestream.live)
            .font(fonts.headline)
            .padding(.vertical, layout.spacingXxs)
            .padding(.horizontal, layout.spacingXs)
            .foregroundColor(
                Color(colors.textOnAccent)
            )
            .background(
                Color(colors.buttonPrimaryBackground)
            )
            .cornerRadius(layout.radiusMd)
    }
}

struct LivestreamPlayPauseButton: View {
    
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    @Binding var streamPaused: Bool
    var trackUpdate: () -> Void
    
    var body: some View {
        Button {
            streamPaused = !streamPaused
            trackUpdate()
        } label: {
            (streamPaused ? images.play : images.pause)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60)
                .foregroundColor(
                    Color(colors.textOnAccent)
                )
        }
    }
}

struct LivestreamParticipantsView: View {
    
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    var participantsCount: Int
    
    var body: some View {
        HStack(spacing: layout.spacingXxs) {
            images.eye
            Text("\(participantsCount)")
                .font(fonts.headline)
        }
        .padding(.all, layout.spacingXs)
        .cornerRadius(layout.radiusMd)
    }
}

struct LivestreamDurationView: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    let duration: String?
    
    var body: some View {
        HStack(spacing: layout.spacingXxs) {
            Circle()
                .fill(Color(colors.accentError))
                .frame(
                    width: layout.spacingXs,
                    height: layout.spacingXs
                )
            
            if let duration {
                Text(duration)
                    .font(fonts.headline.monospacedDigit())
                    .foregroundColor(
                        Color(colors.textOnAccent)
                    )
            }
        }
    }
}

struct LivestreamButton: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout
    
    var image: Image
    var action: () -> Void
    
    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            image
                .padding(.all, layout.spacingXxs)
                .frame(
                    width: layout.iconSizeLg,
                    height: layout.iconSizeLg
                )
                .background(
                    Color(colors.backgroundCoreOverlayDarkStrong)
                )
                .cornerRadius(layout.radiusMd)
        }
        .padding(.horizontal, layout.spacingXxxs)
    }
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
