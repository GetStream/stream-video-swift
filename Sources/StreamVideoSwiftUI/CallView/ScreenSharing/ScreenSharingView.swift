//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
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
        viewFactory: Factory = DefaultViewFactory.shared,
        isZoomEnabled: Bool = true
    ) {
        self.viewModel = viewModel
        self.screenSharing = screenSharing
        self.frame = availableFrame
        self.innerItemSpace = innerItemSpace
        self.viewFactory = viewFactory
        self.isZoomEnabled = isZoomEnabled
    }

    public var body: some View {
        VStack(spacing: innerItemSpace) {
            if !viewModel.hideUIElements {
                Text("\(screenSharing.participant.name) presenting")
                    .foregroundColor(colors.text)
                    .padding()
                    .accessibility(identifier: "participantPresentingLabel")
            }

            Group {
                if isZoomEnabled, !viewModel.hideUIElements {
                    ZoomableScrollView { screensharingView }
                } else {
                    screensharingView
                }
            }
            .accessibility(identifier: "screenSharingView")


            if !viewModel.hideUIElements {
                HorizontalParticipantsListView(
                    viewFactory: viewFactory,
                    participants: viewModel.participants,
                    frame: participantsStripFrame,
                    call: viewModel.call,
                    itemsOnScreen: itemsVisibleOnScreen,
                    showAllInfo: true
                )
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
                log.info("Found \(track.kind) track:\(track.trackId) for \(screenSharing.participant.name) and will add on \(type(of: self)):\(identifier))", subsystems: .webRTC)
                view.add(track: track)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var videoSize: CGSize {
        if viewModel.hideUIElements {
            return .init(
                width: frame.width,
                height: frame.height - participantsStripFrame.height - innerItemSpace
            )
        } else {
            return .init(
                width: frame.width,
                height: frame.height - innerItemSpace
            )
        }
    }

    private var itemsVisibleOnScreen: CGFloat {
        if UIDevice.current.isIpad {
            return UIDevice.current.orientation == .portrait ? 3 : 4
        } else {
            return 2
        }
    }

    private var participantsStripFrame: CGRect {
        /// Each video tile has an aspect ratio of 3:4 with width as base. Given that each tile has the
        /// half width of the screen, the calculation below applies the aspect ratio to the expected width.
        let aspectRatio: CGFloat = UIDevice.current.isIpad ? 9 / 16 : 3 / 4
        let barHeight = (frame.width / itemsVisibleOnScreen) * aspectRatio
        return .init(
            origin: .init(x: frame.origin.x, y: frame.maxY - barHeight),
            size: CGSize(width: frame.width, height: barHeight)
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
