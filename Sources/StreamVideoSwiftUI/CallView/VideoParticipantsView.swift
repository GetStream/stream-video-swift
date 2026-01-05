//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

public struct VideoParticipantsView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor (CallParticipant, Bool) -> Void

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        ZStack {
            if viewModel.participantsLayout == .fullScreen, let first = viewModel.participants.first {
                ParticipantsFullScreenLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    frame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if viewModel.participantsLayout == .spotlight, let first = viewModel.participants.first {
                ParticipantsSpotlightLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    participants: Array(viewModel.participants.dropFirst()),
                    frame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridLayout(
                    viewFactory: viewFactory,
                    call: viewModel.call,
                    participants: viewModel.participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
    }
}

public enum VideoCallParticipantDecoration: Hashable, CaseIterable {
    case options
    case speaking
}

public struct VideoCallParticipantModifier: ViewModifier {

    var participant: CallParticipant
    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.participant = participant
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
            .overlay(
                ZStack {
                    BottomView(content: {
                        HStack {
                            ParticipantInfoView(
                                participant: participant,
                                isPinned: participant.isPinned
                            )
                            
                            Spacer()

                            if showAllInfo {
                                ConnectionQualityIndicator(
                                    connectionQuality: participant.connectionQuality
                                )
                            }
                        }
                    })
                }
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}

extension View {

    @ViewBuilder
    public func applyDecorationModifierIfRequired<Modifier: ViewModifier>(
        _ modifier: @autoclosure () -> Modifier,
        decoration: VideoCallParticipantDecoration,
        availableDecorations: Set<VideoCallParticipantDecoration>
    ) -> some View {
        if availableDecorations.contains(decoration) {
            self.modifier(modifier())
        } else {
            self
        }
    }
}

@MainActor
public struct VideoCallParticipantOptionsModifier: ViewModifier {

    @Injected(\.appearance) var appearance

    @State private var presentActionSheet: Bool = false

    public var participant: CallParticipant
    public var call: Call?

    public init(
        participant: CallParticipant,
        call: Call?
    ) {
        self.participant = participant
        self.call = call
    }

    private var elements: [(title: String, action: () -> Void)] {
        var result = [(title: String, action: () -> Void)]()

        if participant.isPinned {
            result.append((title: L10n.Call.Current.unpinUser, action: { unpin() }))
        } else {
            result.append((title: L10n.Call.Current.pinUser, action: { pin() }))
        }

        if call?.state.ownCapabilities.contains(.pinForEveryone) == true {
            if participant.isPinnedRemotely {
                result.append((title: L10n.Call.Current.unpinForEveryone, action: { unpinForEveryone() }))
            } else {
                result.append((title: L10n.Call.Current.pinForEveryone, action: { pinForEveryone() }))
            }
        }

        if call?.state.ownCapabilities.contains(.kickUser) == true {
            result.append((title: L10n.Call.Current.kickUser, action: { kickUser() }))
        }

        return result
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                TopLeftView {
                    contentView
                }
                .padding(4)
            )
    }

    @ViewBuilder
    private var optionsButtonView: some View {
        Image(systemName: "ellipsis")
            .foregroundColor(.white)
            .padding(8)
            .background(appearance.colors.participantInfoBackgroundColor)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var contentView: some View {
        if #available(iOS 14.0, *) {
            Menu {
                ForEach(elements, id: \.title) { element in
                    Button(
                        action: element.action,
                        label: { Text(element.title) }
                    )
                }
            } label: { optionsButtonView }
        } else {
            Button {
                presentActionSheet.toggle()
            } label: {
                optionsButtonView
            }
            .actionSheet(isPresented: $presentActionSheet) {
                ActionSheet(
                    title: Text("\(participant.name)"),
                    buttons: elements
                        .map { ActionSheet.Button.default(Text($0.title), action: $0.action) } + [ActionSheet.Button.cancel()]
                )
            }
        }
    }

    private func unpin() {
        Task {
            do {
                try await call?.unpin(
                    sessionId: participant.sessionId
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func pin() {
        Task {
            do {
                try await call?.pin(
                    sessionId: participant.sessionId
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func unpinForEveryone() {
        Task {
            do {
                _ = try await call?.unpinForEveryone(
                    userId: participant.userId,
                    sessionId: participant.id
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func pinForEveryone() {
        Task {
            do {
                _ = try await call?.pinForEveryone(
                    userId: participant.userId,
                    sessionId: participant.id
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func kickUser() {
        Task {
            do {
                _ = try await call?.kickUser(userId: participant.userId)
            } catch {
                log.error(error)
            }
        }
    }
}

public struct VideoCallParticipantSpeakingModifier: ViewModifier {

    @Injected(\.colors) var colors

    public var participant: CallParticipant
    public var participantCount: Int
    public var cornerRadius: CGFloat

    public init(
        participant: CallParticipant,
        participantCount: Int,
        cornerRadius: CGFloat = 16
    ) {
        self.participant = participant
        self.participantCount = participantCount
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                participant.isSpeaking && participantCount > 1 ?
                    RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(
                        colors.participantSpeakingHighlightColor,
                        lineWidth: 2
                    ) : nil
            )
    }
}

@MainActor
public struct VideoCallParticipantView<Factory: ViewFactory>: View {

    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var viewFactory: Factory
    let participant: CallParticipant
    var id: String
    var availableFrame: CGRect
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var customData: [String: RawJSON]
    var call: Call?
    private var isLocalParticipant: Bool
    private var callSettingsPublisher: AnyPublisher<CallSettings, Never>?
    @State private var callSettings: CallSettings?
    @ObservedObject private var permissions = InjectedValues[\.permissions]

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        id: String? = nil,
        availableFrame: CGRect,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        customData: [String: RawJSON],
        call: Call?
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.id = id ?? participant.id
        self.availableFrame = availableFrame
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.customData = customData
        self.call = call
        isLocalParticipant = participant.sessionId == call?.state.localParticipant?.sessionId
        callSettings = call?.state.callSettings
        callSettingsPublisher = (participant.sessionId == call?.state.localParticipant?.sessionId)
            ? call?.state.$callSettings.eraseToAnyPublisher()
            : nil
    }

    public var body: some View {
        rendererViewWithCameraPositionAwareness
            .opacity(showVideo ? 1 : 0)
            .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
            .accessibility(identifier: "callParticipantView")
            .streamAccessibility(value: showVideo ? "1" : "0")
            .overlay(overlayView)
    }

    @ViewBuilder
    private var rendererViewWithCameraPositionAwareness: some View {
        if isLocalParticipant {
            Group {
                if callSettings?.cameraPosition == .front {
                    rendererView
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    rendererView
                }
            }
            .onReceive(callSettingsPublisher) { callSettings = $0 }
        } else {
            rendererView
        }
    }

    @ViewBuilder
    private var rendererView: some View {
        VideoRendererView(
            id: id,
            size: availableFrame.size,
            contentMode: contentMode,
            showVideo: showVideo,
            handleRendering: { [weak call, participant] view in
                guard call != nil else { return }
                view.handleViewRendering(for: participant) { [weak call] size, participant in
                    Task { [weak call] in
                        await call?.updateTrackSize(size, for: participant)
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var overlayView: some View {
        CallParticipantImageView(
            viewFactory: viewFactory,
            id: participant.id,
            name: participant.name,
            imageURL: participant.profileImageURL
        )
        .opacity(showVideo ? 0 : 1)
    }

    private var showVideo: Bool {
        if isLocalParticipant {
            return callSettings?.videoOn == true && permissions.hasCameraPermission
        } else {
            return participant.shouldDisplayTrack
        }
    }
}

public struct ParticipantInfoView: View {
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    var participant: CallParticipant
    var isPinned: Bool
    var maxHeight: CGFloat
    var paddingsConfig: EdgeInsets

    public init(
        participant: CallParticipant,
        isPinned: Bool,
        maxHeight: Float = 14,
        paddingsConfig: EdgeInsets = .participantInfoView
    ) {
        self.participant = participant
        self.isPinned = isPinned
        self.maxHeight = CGFloat(maxHeight)
        self.paddingsConfig = paddingsConfig
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            }
            Text(participant.name.isEmpty ? participant.id : participant.name)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(fonts.caption1)
                .minimumScaleFactor(0.7)
                .accessibility(identifier: "participantName")

            if participant.pausedTracks.contains(.video) {
                Image(systemName: "wifi.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            }

            SoundIndicator(participant: participant)
                .frame(maxHeight: maxHeight)
        }
        .padding(paddingsConfig)
        .frame(height: 28)
        .cornerRadius(
            8,
            corners: [.topRight],
            backgroundColor: colors.participantInfoBackgroundColor
        )
    }
}

public struct SoundIndicator: View {
            
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    let participant: CallParticipant
    
    public init(participant: CallParticipant) {
        self.participant = participant
    }
    
    public var body: some View {
        (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(participant.hasAudio ? .white : colors.inactiveCallControl)
            .accessibility(identifier: "participantMic")
            .streamAccessibility(value: participant.hasAudio ? "1" : "0")
    }
}

public struct PopoverButton: View {
        
    var title: String
    @Binding var popoverShown: Bool
    var action: () -> Void
    
    public init(title: String, popoverShown: Binding<Bool>, action: @escaping () -> Void) {
        self.title = title
        _popoverShown = popoverShown
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
            popoverShown = false
        } label: {
            Text(title)
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
    }
}
