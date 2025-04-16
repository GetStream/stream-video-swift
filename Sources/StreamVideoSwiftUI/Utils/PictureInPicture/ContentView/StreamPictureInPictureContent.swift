//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

enum StreamPictureInPictureContentState: Equatable, CustomStringConvertible {
    case inactive
    case participant(Call?, CallParticipant, RTCVideoTrack?)
    case screenSharing(Call?, CallParticipant, RTCVideoTrack)
    case reconnecting

    var description: String {
        switch self {
        case .inactive:
            return ".inactive"
        case let .participant(call, participant, track):
            return ".participant(cId:\(call?.cId ?? "-"), name:\(participant.name), track:\(track?.trackId ?? "-"))"
        case let .screenSharing(call, participant, track):
            return ".screenSharing(cId:\(call?.cId ?? "-"), name:\(participant.name), track:\(track.trackId))"
        case .reconnecting:
            return ".reconnecting"
        }
    }

    static func == (
        lhs: StreamPictureInPictureContentState,
        rhs: StreamPictureInPictureContentState
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive):
            return true

        case (let .participant(lhsCall, lhsParticipant, lhsTrack), let .participant(rhsCall, rhsParticipant, rhsTrack)):
            return lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (let .screenSharing(lhsCall, lhsParticipant, lhsTrack), let .screenSharing(rhsCall, rhsParticipant, rhsTrack)):
            return lhsCall?.cId == rhsCall?.cId
                && lhsParticipant == rhsParticipant
                && lhsTrack == rhsTrack

        case (.reconnecting, .reconnecting):
            return true

        default:
            return false
        }
    }
}

struct StreamPictureInPictureContent: View {

    @Injected(\.appearance) private var appearance

    private let store: PictureInPictureStore

    @State private var state: StreamPictureInPictureContentState
    @State private var viewFactory: AnyViewFactory

    init(
        store: PictureInPictureStore
    ) {
        self.store = store
        viewFactory = store.state.viewFactory
        state = store.state.content
    }

    var body: some View {
        ZStack {
            Color(appearance.colors.participantBackground)
                .edgesIgnoringSafeArea(.all)

            contentView
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(store.publisher(for: \.viewFactory)) { viewFactory = $0 }
        .onReceive(store.publisher(for: \.content)) { state = $0 }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .inactive:
            EmptyView()
        case let .participant(_, participant, track):
            StreamPictureInPictureVideoParticipantView(
                store: store,
                viewFactory: viewFactory,
                participant: participant,
                track: track
            )
        case let .screenSharing(_, participant, track):
            StreamPictureInPictureScreenSharingView(
                store: store,
                viewFactory: viewFactory,
                participant: participant,
                track: track
            )
        case .reconnecting:
            PictureInPictureReconnectionView()
        }
    }
}
