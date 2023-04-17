//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView: View {
    
    @ObservedObject var viewModel: CallViewModel
    var screenSharing: ScreensharingSession
    var availableSize: CGSize
    
    private let thumbnailSize: CGFloat = 120
        
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
                            VideoCallParticipantView(
                                participant: participant,
                                availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                                contentMode: .scaleAspectFill
                            ) { participant, view in
                                view.handleViewRendering(for: participant) { size, participant in
                                    viewModel.updateTrackSize(size, for: participant)
                                }
                            }
                            .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                            .cornerRadius(8)
                            .accessibility(identifier: "screenSharingParticipantView")
                            .onAppear {
                                viewModel.changeTrackVisbility(for: participant, isVisible: true)
                            }
                            .onDisappear {
                                viewModel.changeTrackVisbility(for: participant, isVisible: false)
                            }
                        }
                        
                        LocalVideoView(callSettings: viewModel.callSettings) { view in
                            if let track = viewModel.localParticipant?.track {
                                view.add(track: track)
                            } else {
                                viewModel.startCapturingLocalVideo()
                            }
                        }
                        .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                        .cornerRadius(8)
                    }
                    .frame(height: thumbnailSize)
                    .cornerRadius(8)
                }
                .padding()
                .padding(.bottom)
            }
        }
        .frame(
            width: viewModel.hideUIElements ? availableSize.width : nil,
            height: viewModel.hideUIElements ? availableSize.height : nil
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
        .onTapGesture {
            withAnimation {
                viewModel.hideUIElements.toggle()
            }
        }
        .id("\(viewModel.hideUIElements)")
        .rotationEffect(.degrees(viewModel.hideUIElements ? 90 : 0))
    }
    
    private var videoSize: CGSize {
        if viewModel.hideUIElements {
            return .init(width: availableSize.height, height: availableSize.width)
        } else {
            return availableSize
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
