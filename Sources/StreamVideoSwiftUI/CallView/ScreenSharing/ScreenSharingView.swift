//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import Combine

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    @Injected(\.currentDevice) var currentDevice
    @Injected(\.orientationAdapter) var orientationAdapter

    var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var frame: CGRect
    var innerItemSpace: CGFloat
    var viewFactory: Factory
    var isZoomEnabled: Bool

    private let identifier = UUID()

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
    }

    public var body: some View {
        PublisherSubscriptionView(
            initial: viewModel.hideUIElements,
            publisher: viewModel.$hideUIElements.eraseToAnyPublisher()
        ) { hideUIElements in
            VStack(spacing: innerItemSpace) {
                isPresentingLabelView(hideUIElements: hideUIElements)
                
                if isZoomEnabled, !hideUIElements {
                    ZoomableScrollView { screensharingView }
                } else {
                    screensharingView
                }
                
                if !hideUIElements {
                    HorizontalParticipantsListView(
                        viewFactory: viewFactory,
                        participants: viewModel.participants,
                        frame: participantsStripFrame,
                        call: viewModel.call,
                        showAllInfo: true
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func isPresentingLabelView(hideUIElements: Bool) -> some View {
        PublisherSubscriptionView(
            initial: !hideUIElements && (orientationAdapter.orientation.isPortrait || currentDevice.deviceType == .pad),
            publisher: orientationAdapter.$orientation.map { $0.isPortrait }.eraseToAnyPublisher()
        ) { isPortrait in
            if !hideUIElements, (isPortrait || currentDevice.deviceType == .pad) {
                Text("\(screenSharing.participant.name) presenting")
                    .foregroundColor(colors.text)
                    .padding()
                    .accessibility(identifier: "participantPresentingLabel")
            } else {
                EmptyView()
            }
        }
    }

    private var screensharingView: some View {
        VideoRendererView(
            id: "\(screenSharing.participant.id)-screenshare",
            size: videoSize,
            contentMode: .scaleAspectFit
        ) { view in
            if let track = screenSharing.participant.screenshareTrack {
                log.info(
                    "Found \(track.kind) track:\(track.trackId) for \(screenSharing.participant.name) and will add on \(type(of: self)):\(identifier))",
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

struct HorizontalContainer<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 14.0, *) {
            LazyHStack(content: content)
        } else {
            HStack(content: content)
        }
    }
}
