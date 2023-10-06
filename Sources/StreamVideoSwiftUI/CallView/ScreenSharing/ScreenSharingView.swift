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
    
    private var thumbnailBounds: CGRect {
        CGRect(x: 0, y: 0, width: 120, height: 120)
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
                ScrollView(.horizontal) {
                    HorizontalContainer {
                        ForEach(viewModel.participants) { participant in
                            viewFactory.makeVideoParticipantView(
                                participant: participant,
                                id: "\(participant.id)-screenshare-participant",
                                availableFrame: thumbnailBounds,
                                contentMode: .scaleAspectFill,
                                customData: [:],
                                call: viewModel.call
                            )
                            .modifier(
                                viewFactory.makeVideoCallParticipantModifier(
                                    participant: participant,
                                    call: viewModel.call,
                                    availableFrame: thumbnailBounds,
                                    ratio: 1,
                                    showAllInfo: false
                                )
                            )
                            .cornerRadius(8)
                            .accessibility(identifier: "screenSharingParticipantView")
                            .onAppear {
                                viewModel.changeTrackVisibility(for: participant, isVisible: true)
                            }
                            .onDisappear {
                                viewModel.changeTrackVisibility(for: participant, isVisible: false)
                            }
                        }
                    }
                    .frame(height: thumbnailBounds.size.height)
                    .cornerRadius(8)
                }
                .padding()
                .padding(.bottom)
                .accessibility(identifier: "screenSharingParticipantList")
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
