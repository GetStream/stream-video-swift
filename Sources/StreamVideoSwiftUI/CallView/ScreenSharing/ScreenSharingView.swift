//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @ObservedObject var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var availableFrame: CGRect
    var viewFactory: Factory

    private let thumbnailSize: CGFloat = 120
    private var thumbnailBounds: CGRect {
        CGRect(x: 0, y: 0, width: thumbnailSize, height: thumbnailSize)
    }

    public init(
        viewModel: CallViewModel,
        screenSharing: ScreenSharingSession,
        availableFrame: CGRect,
        viewFactory: Factory = DefaultViewFactory.shared
    ) {
        self.viewModel = viewModel
        self.screenSharing = screenSharing
        self.availableFrame = availableFrame
        self.viewFactory = viewFactory
    }

    public var body: some View {
        VStack(alignment: .leading) {
            if !viewModel.hideUIElements {
                Text("\(screenSharing.participant.name) presenting")
                    .foregroundColor(.white)
                    .padding()
                    .padding(.top, 40)
                    .accessibility(identifier: "participantPresentingLabel")
            }

            if viewModel.hideUIElements {
                screensharingView.accessibility(identifier: "screenSharingView")
            } else {
                ZoomableScrollView {
                    screensharingView.accessibility(identifier: "screenSharingView")
                }
            }

            if !viewModel.hideUIElements {
                viewFactory.makeBottomParticipantsBarLayoutComponent(
                    participants: viewModel.participants,
                    availableFrame: .init(
                        origin: .init(x: availableFrame.origin.x, y: availableFrame.maxY - thumbnailSize),
                        size: CGSize(width: availableFrame.size.width, height: thumbnailSize)
                    ),
                    call: viewModel.call,
                    onChangeTrackVisibility: { [weak viewModel] in
                        viewModel?.changeTrackVisibility(for: $0, isVisible: $1)
                    }
                )
            }
        }
        .frame(
            width: viewModel.hideUIElements ? availableFrame.size.width : nil,
            height: viewModel.hideUIElements ? availableFrame.size.height : nil
        )
        .background(Color.black)
    }

    private var screensharingView: some View {
        VideoRendererView(
            id: "\(screenSharing.participant.id)-screenshare",
            size: videoSize,
            contentMode: .scaleAspectFit
        ) { view in
            if let track = screenSharing.participant.screenshareTrack {
                log.debug("adding screensharing track to a view \(view)")
                view.add(track: track)
            }
        }
        .frame(
            width: viewModel.hideUIElements ? videoSize.width : nil,
            height: viewModel.hideUIElements ? videoSize.height : nil
        )
    }

    private var videoSize: CGSize {
        if viewModel.hideUIElements {
            return .init(width: availableFrame.size.height, height: availableFrame.size.width)
        } else {
            return availableFrame.size
        }
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
