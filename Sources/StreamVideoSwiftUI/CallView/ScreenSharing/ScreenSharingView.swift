//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @ObservedObject var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var frame: CGRect
    var innerItemSpace: CGFloat
    var viewFactory: Factory

    private let identifier = UUID()

    public init(
        viewModel: CallViewModel,
        screenSharing: ScreenSharingSession,
        availableFrame: CGRect,
        innerItemSpace: CGFloat = 8,
        viewFactory: Factory = DefaultViewFactory.shared
    ) {
        self.viewModel = viewModel
        self.screenSharing = screenSharing
        self.frame = availableFrame
        self.innerItemSpace = innerItemSpace
        self.viewFactory = viewFactory
    }

    public var body: some View {
        VStack(spacing: innerItemSpace) {
            if !viewModel.hideUIElements {
                Text("\(screenSharing.participant.name) presenting")
                    .foregroundColor(.white)
                    .padding()
                    .accessibility(identifier: "participantPresentingLabel")
            }

            if viewModel.hideUIElements {
                screensharingView
                    .accessibility(identifier: "screenSharingView")
            } else {
                ZoomableScrollView {
                    screensharingView
                        .accessibility(identifier: "screenSharingView")
                }
            }

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
        .frame(
            width: viewModel.hideUIElements ? videoSize.width : nil,
            height: viewModel.hideUIElements ? videoSize.height : nil
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var videoSize: CGSize {
        if viewModel.hideUIElements {
            return .init(
                width: frame.size.height,
                height: frame.size.width
            )
        } else {
            return frame.size
        }
    }

    private var itemsVisibleOnScreen: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIDevice.current.orientation == .portrait ? 3 : 4
        } else {
            return 2
        }
    }

    private var participantsStripFrame: CGRect {
        /// Each video tile has an aspect ratio of 3:4 with width as base. Given that each tile has the
        /// half width of the screen, the calculation below applies the aspect ratio to the expected width.
        let aspectRatio: CGFloat = UIDevice.current.userInterfaceIdiom == .pad 
        ? 9 / 16
        : 3 / 4
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
