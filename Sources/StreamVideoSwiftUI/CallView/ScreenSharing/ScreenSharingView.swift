//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors

    var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var frame: CGRect
    var innerItemSpace: CGFloat
    var viewFactory: Factory
    var isZoomEnabled: Bool

    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

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
        if #available(iOS 14.0, *) {
            ScreensharingViewContent(
                callViewModel: viewModel,
                screenSharing: screenSharing,
                frame: frame,
                innerItemSpace: innerItemSpace,
                viewFactory: viewFactory,
                isZoomEnabled: isZoomEnabled
            )
        } else {
            ScreensharingViewContent_iOS13(
                callViewModel: viewModel,
                screenSharing: screenSharing,
                frame: frame,
                innerItemSpace: innerItemSpace,
                viewFactory: viewFactory,
                isZoomEnabled: isZoomEnabled
            )
        }
    }
}

extension ScreenSharingView {

    private final class ViewModel: ObservableObject, @unchecked Sendable {
        @Published private(set) var participants: [CallParticipant]
        @Published private(set) var hideUIElements: Bool

        let callViewModel: CallViewModel
        private let disposableBag = DisposableBag()

        @MainActor
        init(_ callViewModel: CallViewModel) {
            self.callViewModel = callViewModel
            participants = callViewModel.participants
            hideUIElements = callViewModel.hideUIElements

            callViewModel
                .$hideUIElements
                .removeDuplicates()
                .assign(to: \.hideUIElements, onWeak: self)
                .store(in: disposableBag)

            callViewModel
                .$callParticipants
                .compactMap { [weak callViewModel] _ in callViewModel?.participants }
                .removeDuplicates()
                .assign(to: \.participants, onWeak: self)
                .store(in: disposableBag)
        }
    }

    @available(iOS 14.0, *)
    struct ScreensharingViewContent: View {
        @Injected(\.colors) var colors

        var screenSharing: ScreenSharingSession
        var frame: CGRect
        var innerItemSpace: CGFloat
        var viewFactory: Factory
        var isZoomEnabled: Bool

        @StateObject private var viewModel: ViewModel

        init(
            callViewModel: CallViewModel,
            screenSharing: ScreenSharingSession,
            frame: CGRect,
            innerItemSpace: CGFloat,
            viewFactory: Factory,
            isZoomEnabled: Bool
        ) {
            _viewModel = .init(wrappedValue: .init(callViewModel))
            self.screenSharing = screenSharing
            self.frame = frame
            self.innerItemSpace = innerItemSpace
            self.viewFactory = viewFactory
            self.isZoomEnabled = isZoomEnabled
            orientationAdapter = orientationAdapter
        }

        private let identifier = UUID()
        @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

        var body: some View {
            VStack(spacing: innerItemSpace) {
                if !viewModel.hideUIElements, orientationAdapter.orientation.isPortrait || UIDevice.current.isIpad {
                    Text("\(screenSharing.participant.name) presenting")
                        .foregroundColor(colors.text)
                        .padding()
                        .accessibility(identifier: "participantPresentingLabel")
                }

                if isZoomEnabled, !viewModel.hideUIElements {
                    ZoomableScrollView { screenSharingView }
                } else {
                    screenSharingView
                }

                if !viewModel.hideUIElements {
                    HorizontalParticipantsListView(
                        viewFactory: viewFactory,
                        participants: viewModel.participants,
                        frame: participantsStripFrame,
                        call: viewModel.callViewModel.call,
                        showAllInfo: true
                    )
                }
            }
        }

        @ViewBuilder
        private var screenSharingView: some View {
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
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    struct ScreensharingViewContent_iOS13: View {
        @Injected(\.colors) var colors

        var screenSharing: ScreenSharingSession
        var frame: CGRect
        var innerItemSpace: CGFloat
        var viewFactory: Factory
        var isZoomEnabled: Bool

        @BackportStateObject private var viewModel: ViewModel

        init(
            callViewModel: CallViewModel,
            screenSharing: ScreenSharingSession,
            frame: CGRect,
            innerItemSpace: CGFloat,
            viewFactory: Factory,
            isZoomEnabled: Bool
        ) {
            _viewModel = .init(wrappedValue: .init(callViewModel))
            self.screenSharing = screenSharing
            self.frame = frame
            self.innerItemSpace = innerItemSpace
            self.viewFactory = viewFactory
            self.isZoomEnabled = isZoomEnabled
            orientationAdapter = orientationAdapter
        }

        private let identifier = UUID()
        @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]

        var body: some View {
            VStack(spacing: innerItemSpace) {
                if !viewModel.hideUIElements, orientationAdapter.orientation.isPortrait || UIDevice.current.isIpad {
                    Text("\(screenSharing.participant.name) presenting")
                        .foregroundColor(colors.text)
                        .padding()
                        .accessibility(identifier: "participantPresentingLabel")
                }

                if isZoomEnabled, !viewModel.hideUIElements {
                    ZoomableScrollView { screenSharingView }
                } else {
                    screenSharingView
                }

                if !viewModel.hideUIElements {
                    HorizontalParticipantsListView(
                        viewFactory: viewFactory,
                        participants: viewModel.participants,
                        frame: participantsStripFrame,
                        call: viewModel.callViewModel.call,
                        showAllInfo: true
                    )
                }
            }
        }

        @ViewBuilder
        private var screenSharingView: some View {
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
