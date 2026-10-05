//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.layout) var layout

    @ObservedObject var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var frame: CGRect
    var innerItemSpace: CGFloat
    var viewFactory: Factory
    var isZoomEnabled: Bool

    private let identifier = UUID()
    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

    public init(
        viewModel: CallViewModel,
        screenSharing: ScreenSharingSession,
        availableFrame: CGRect,
        innerItemSpace: CGFloat = InjectedValues[\.layout].spacingXs,
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
        innerItemSpace: CGFloat = InjectedValues[\.layout].spacingXs,
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
        VStack(spacing: innerItemSpace) {
            if !viewModel.hideUIElements, orientationAdapter.orientation.isPortrait || UIDevice.current.isIpad {
                Text(L10n.Call.Current.presenting(screenSharing.participant.name))
                    .font(fonts.body)
                    .foregroundColor(Color(colors.textPrimary))
                    .padding(layout.spacingMd)
                    .accessibility(identifier: "participantPresentingLabel")
            }

            if isZoomEnabled, !viewModel.hideUIElements {
                ZoomableScrollView { screensharingView }
            } else {
                screensharingView
            }
            
            if !viewModel.hideUIElements {
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
        .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl))
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
    @Injected(\.layout) var layout
    
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        if #available(iOS 14.0, *) {
            LazyHStack(spacing: layout.spacingXs, content: content)
        } else {
            HStack(spacing: layout.spacingXs, content: content)
        }
    }
}
