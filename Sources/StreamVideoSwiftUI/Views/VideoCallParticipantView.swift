//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

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
            .debugViewRendering()
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
