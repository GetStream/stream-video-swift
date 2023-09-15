//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct VideoParticipantsView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    var availableSize: CGSize
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    @State private var orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
    
    public init(
        viewFactory: Factory,
        viewModel: CallViewModel,
        availableSize: CGSize,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor(CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
        self.availableSize = availableSize
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        ZStack {
            if viewModel.participantsLayout == .fullScreen, let first = viewModel.participants.first {
                ParticipantsFullScreenLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    size: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if viewModel.participantsLayout == .spotlight, let first = viewModel.participants.first {
                ParticipantsSpotlightLayout(
                    viewFactory: viewFactory,
                    participant: first,
                    call: viewModel.call,
                    participants: Array(viewModel.participants.dropFirst()),
                    size: availableSize,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridLayout(
                    viewFactory: viewFactory,
                    call: viewModel.call,
                    participants: viewModel.participants,
                    availableSize: availableSize,
                    orientation: orientation,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            }
        }
        .onRotate { newOrientation in
            orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        }
    }
}

public struct VideoCallParticipantModifier: ViewModifier {
            
    @State var popoverShown = false
    
    var participant: CallParticipant
    var call: Call?
    var availableSize: CGSize
    var ratio: CGFloat
    var showAllInfo: Bool
    
    public init(
        participant: CallParticipant,
        call: Call?,
        availableSize: CGSize,
        ratio: CGFloat,
        showAllInfo: Bool
    ) {
        self.participant = participant
        self.call = call
        self.availableSize = availableSize
        self.ratio = ratio
        self.showAllInfo = showAllInfo
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableSize.width, ratio: ratio)
            .overlay(
                ZStack {
                    BottomView(content: {
                        HStack {
                            ParticipantInfoView(
                                participant: participant,
                                isPinned: participant.isPinned
                            )
                            
                            if showAllInfo {
                                Spacer()
                                ConnectionQualityIndicator(
                                    connectionQuality: participant.connectionQuality
                                )
                            }
                        }
                        .padding(.bottom, 2)
                    })
                    .padding(.all, showAllInfo ? 16 : 8)
                    
                    if participant.isSpeaking && participantCount > 1 {
                        Rectangle()
                            .strokeBorder(Color.blue.opacity(0.7), lineWidth: 2)
                    }
                    
                    if popoverShown {
                        ParticipantPopoverView(
                            participant: participant,
                            call: call,
                            popoverShown: $popoverShown
                        )
                    }
                }
            )
            .onTapGesture(count: 2, perform: {
                popoverShown = true
            })
            .onTapGesture(count: 1) {
                if popoverShown {
                    popoverShown = false
                }
            }
    }
    
    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}

public struct VideoCallParticipantView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
        
    let participant: CallParticipant
    var id: String
    var availableSize: CGSize
    var contentMode: UIView.ContentMode
    var edgesIgnoringSafeArea: Edge.Set
    var customData: [String: RawJSON]
    var call: Call?
    
    public init(
        participant: CallParticipant,
        id: String? = nil,
        availableSize: CGSize,
        contentMode: UIView.ContentMode,
        edgesIgnoringSafeArea: Edge.Set = .all,
        customData: [String: RawJSON],
        call: Call?
    ) {
        self.participant = participant
        self.id = id ?? participant.id
        self.availableSize = availableSize
        self.contentMode = contentMode
        self.edgesIgnoringSafeArea = edgesIgnoringSafeArea
        self.customData = customData
        self.call = call
    }
    
    public var body: some View {
        VideoRendererView(
            id: id,
            size: availableSize,
            contentMode: contentMode,
            handleRendering: { [weak call] view in
                guard call != nil else { return }
                view.handleViewRendering(for: participant) { size, participant in
                    Task {
                        await call?.updateTrackSize(size, for: participant)
                    }
                }
            }
        )
        .opacity(showVideo ? 1 : 0)
        .edgesIgnoringSafeArea(edgesIgnoringSafeArea)
        .accessibility(identifier: "callParticipantView")
        .streamAccessibility(value: showVideo ? "1" : "0")
        .overlay(
            CallParticipantImageView(
                id: participant.id,
                name: participant.name,
                imageURL: participant.profileImageURL
            )
            .frame(width: availableSize.width)
            .opacity(showVideo ? 0 : 1)
        )
    }
    
    private var showVideo: Bool {
        participant.shouldDisplayTrack || customData["videoOn"]?.boolValue == true
    }
}

public struct ParticipantInfoView: View {
    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    
    var participant: CallParticipant
    var isPinned: Bool
    
    public init(participant: CallParticipant, isPinned: Bool) {
        self.participant = participant
        self.isPinned = isPinned
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            if isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            }
            Text(participant.name.isEmpty ? participant.id : participant.name)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(fonts.caption1)
                .accessibility(identifier: "participantName")
                        
            SoundIndicator(participant: participant)
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
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
            .foregroundColor(participant.hasAudio ? .white : colors.accentRed)
            .padding(.all, 4)
            .accessibility(identifier: "participantMic")
            .streamAccessibility(value: participant.hasAudio ? "1" : "0")
    }
    
}

public struct PopoverButton: View {
        
    var title: String
    @Binding var popoverShown: Bool
    var action: () -> ()
    
    public init(title: String, popoverShown: Binding<Bool>, action: @escaping () -> ()) {
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
