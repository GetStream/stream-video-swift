//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

public struct VideoParticipantsView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var viewModel: CallViewModel
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void

    @State var participants: [CallParticipant]
    var participantsPublisher: AnyPublisher<[CallParticipant], Never>

    @State var participantsLayout: ParticipantsLayout
    var participantsLayoutPublisher: AnyPublisher<ParticipantsLayout, Never>

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel,
        availableFrame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableFrame = availableFrame
        self.onChangeTrackVisibility = onChangeTrackVisibility

        participants = viewModel.participants
        participantsPublisher = viewModel
            .$participants
            .receive(on: DispatchQueue.global(qos: .default))
            .removeDuplicates(by: { lhs, rhs in
                let lhsSessionIds = lhs.map(\.sessionId)
                let rhsSessionIds = rhs.map(\.sessionId)
                return lhsSessionIds == rhsSessionIds
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsLayout = viewModel.participantsLayout
        participantsLayoutPublisher = viewModel
            .$participantsLayout
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var body: some View {
        contentView
            .onReceive(participantsPublisher) { participants = $0 }
            .onReceive(participantsLayoutPublisher) { participantsLayout = $0 }
    }

    @ViewBuilder
    var contentView: some View {
        if participantsLayout == .fullScreen, let first = participants.first {
            ParticipantsFullScreenLayout(
                viewFactory: viewFactory,
                participant: first,
                call: viewModel.call,
                frame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        } else if participantsLayout == .spotlight, let first = participants.first {
            ParticipantsSpotlightLayout(
                viewFactory: viewFactory,
                participant: first,
                call: viewModel.call,
                participants: Array(participants.dropFirst()),
                frame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        } else {
            ParticipantsGridLayout(
                viewFactory: viewFactory,
                call: viewModel.call,
                participants: participants,
                availableFrame: availableFrame,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        }
    }
}

public enum VideoCallParticipantDecoration: Hashable, CaseIterable {
    case options
    case speaking
}

public struct VideoCallParticipantModifier: ViewModifier {

    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    @State var participant: CallParticipant
    var participantPublisher: AnyPublisher<CallParticipant, Never>?

    @State var participantsCount: Int
    var participantsCountPublisher: AnyPublisher<Int, Never>?

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)

        self.participant = participant
        participantPublisher = call?
            .state
            .$participantsMap
            .compactMap { $0[participant.sessionId] }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsCount = call?.state.participants.endIndex ?? 0
        participantsCountPublisher = call?
            .state
            .$participants
            .map(\.endIndex)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
            .overlay(participantInfoView)
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantsCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .onReceive(participantPublisher) { participant = $0 }
            .onReceive(participantsCountPublisher) { participantsCount = $0 }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @ViewBuilder
    var participantInfoView: some View {
        BottomView {
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
        }
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
}

public struct VideoCallParticipantSpeakingModifier: ViewModifier {

    @Injected(\.colors) var colors

    public var participant: CallParticipant
    public var participantCount: Int

    public init(
        participant: CallParticipant,
        participantCount: Int
    ) {
        self.participant = participant
        self.participantCount = participantCount
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if participant.isSpeaking, participantCount > 1 {
                        RoundedRectangle(cornerRadius: 16).strokeBorder(
                            colors.participantSpeakingHighlightColor,
                            lineWidth: 2
                        )
                    }
                }
            )
    }
}

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

    @State private var track: RTCVideoTrack?
    var trackPublisher: AnyPublisher<RTCVideoTrack?, Never>?

    @State private var showVideo: Bool
    var showVideoPublisher: AnyPublisher<Bool, Never>?

    @State private var isUsingFrontCameraForLocalUser: Bool = false
    var isUsingFrontCameraForLocalUserPublisher: AnyPublisher<Bool, Never>?

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

        track = participant.track
        trackPublisher = call?
            .state
            .$participantsMap
            .map { $0[participant.sessionId]?.track }
            .removeDuplicates(by: { $0?.trackId == $1?.trackId })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        showVideo = participant.shouldDisplayTrack || customData["videoOn"]?.boolValue == true
        showVideoPublisher = call?
            .state
            .$participantsMap
            .map { $0[participant.sessionId]?.shouldDisplayTrack ?? false }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        if participant.sessionId == call?.state.localParticipant?.sessionId {
            isUsingFrontCameraForLocalUser = call?.state.callSettings.cameraPosition == .front
            isUsingFrontCameraForLocalUserPublisher = call?
                .state
                .$callSettings
                .map { $0.cameraPosition == .front }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }

    public var body: some View {
        contentView
            .onReceive(trackPublisher) { track = $0 }
            .onReceive(showVideoPublisher) { showVideo = $0 }
            .onReceive(isUsingFrontCameraForLocalUserPublisher) { isUsingFrontCameraForLocalUser = $0 }
            .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
            .accessibility(identifier: "callParticipantView")
            .streamAccessibility(value: showVideo ? "1" : "0")
            .id(participant.sessionId)
    }

    @ViewBuilder
    var contentView: some View {
        if showVideo, track != nil {
            if isUsingFrontCameraForLocalUser {
                videoRendererView
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                videoRendererView
            }
        } else {
            placeholderView
        }
    }

    @ViewBuilder
    var videoRendererView: some View {
        if let track {
            TrackVideoRendererView(
                track: track,
                contentMode: contentMode
            ) { [weak call, participant] size in
                Task { [weak call] in
                    await call?.updateTrackSize(size, for: participant)
                }
            }
        }
    }

    @ViewBuilder
    var placeholderView: some View {
        CallParticipantImageView(
            viewFactory: viewFactory,
            id: participant.id,
            name: participant.name,
            imageURL: participant.profileImageURL
        )
        .frame(width: availableFrame.width, height: availableFrame.height)
    }
}

public struct ParticipantInfoView: View {
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    var participant: CallParticipant
    var isPinned: Bool
    var maxHeight: CGFloat

    public init(
        participant: CallParticipant,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.participant = participant
        self.isPinned = isPinned
        self.maxHeight = CGFloat(maxHeight)
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

            SoundIndicator(participant: participant)
                .frame(maxHeight: maxHeight)
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
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
