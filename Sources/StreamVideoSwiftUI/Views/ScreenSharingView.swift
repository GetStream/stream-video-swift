//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    @Injected(\.currentDevice) var currentDevice

    var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var frame: CGRect
    var innerItemSpace: CGFloat
    var viewFactory: Factory
    var isZoomEnabled: Bool

    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

    @State var hideUIElements: Bool
    var hideUIElementsPublisher: AnyPublisher<Bool, Never>

    @State var participants: [CallParticipant]
    var participantsPublisher: AnyPublisher<[CallParticipant], Never>?

    public init(
        viewModel: CallViewModel,
        screenSharing: ScreenSharingSession,
        availableFrame: CGRect,
        innerItemSpace: CGFloat = 8,
        isZoomEnabled: Bool = true
    ) where Factory == DefaultViewFactory {
        self.init(
            viewModel: viewModel,
            screenSharing: screenSharing,
            availableFrame: availableFrame,
            innerItemSpace: innerItemSpace,
            viewFactory: DefaultViewFactory.shared,
            isZoomEnabled: isZoomEnabled
        )
    }

    public init(
        viewModel: CallViewModel,
        screenSharing: ScreenSharingSession,
        availableFrame: CGRect,
        innerItemSpace: CGFloat = 8,
        viewFactory: Factory,
        isZoomEnabled: Bool = true
    ) {
        self.viewModel = viewModel
        self.screenSharing = screenSharing
        frame = availableFrame
        self.innerItemSpace = innerItemSpace
        self.viewFactory = viewFactory
        self.isZoomEnabled = isZoomEnabled

        hideUIElements = viewModel.hideUIElements
        hideUIElementsPublisher = viewModel
            .$hideUIElements
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participants = viewModel.participants
        participantsPublisher = viewModel
            .$participants
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .removeDuplicates(by: { lhs, rhs in
                let lhsSessionIds = lhs.map(\.sessionId)
                let rhsSessionIds = rhs.map(\.sessionId)
                return lhsSessionIds == rhsSessionIds
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var body: some View {
        VStack(spacing: innerItemSpace) {
            headerView
            middleView
            footerView
        }
        .onReceive(hideUIElementsPublisher) { hideUIElements = $0 }
        .onReceive(participantsPublisher) { participants = $0 }
        .debugViewRendering()
    }

    @ViewBuilder
    var headerView: some View {
        if !hideUIElements,
           (orientationAdapter.orientation.isPortrait || currentDevice.deviceType == .pad) {
            Text("\(screenSharing.participant.name) presenting")
                .foregroundColor(colors.text)
                .padding()
                .accessibility(identifier: "participantPresentingLabel")
        }
    }

    @ViewBuilder
    var middleView: some View {
        if isZoomEnabled, !hideUIElements {
            ZoomableScrollView { screensharingView }
        } else {
            screensharingView
        }
    }

    @ViewBuilder
    var footerView: some View {
        if !hideUIElements {
            HorizontalParticipantsListView(
                viewFactory: viewFactory,
                participants: participants,
                frame: participantsStripFrame,
                call: viewModel.call,
                showAllInfo: true
            )
        }
    }

    @ViewBuilder
    private var screensharingView: some View {
        VideoRendererView(
            id: "\(screenSharing.participant.id)-screenshare",
            size: videoSize,
            contentMode: .scaleAspectFit
        ) { view in
            if let track = screenSharing.participant.screenshareTrack {
                log.info(
                    "Found \(track.kind) track:\(track.trackId) for \(screenSharing.participant.name) and will add on \(type(of: self)))",
                    subsystems: .webRTC
                )
                view.add(track: track)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibility(identifier: "screenSharingView")
    }

    private var videoSize: CGSize {
        let height = frame.width * 9 / 16

        if viewModel.hideUIElements {
            return .init(
                width: frame.width,
                height: height - participantsStripFrame.height - innerItemSpace
            )
        } else {
            return .init(
                width: frame.width,
                height: height - innerItemSpace
            )
        }
    }

    private var participantsStripFrame: CGRect {
        let barHeight = frame.height / 4
        let barY = frame.maxY - barHeight
        return CGRect(
            x: frame.origin.x,
            y: barY,
            width: frame.width,
            height: barHeight
        )
    }
}
