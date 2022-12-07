//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenSharingView: View {
    
    @StateObject var viewModel: CallViewModel
    var screenSharing: ScreensharingSession
    var availableSize: CGSize
    
    private let thumbnailSize: CGFloat = 120
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text("\(screenSharing.participant.name) presenting")
                .foregroundColor(.white)
                .padding()
                .padding(.top, 40)
            ZoomableScrollView {
                VideoRendererView(
                    id: screenSharing.participant.id,
                    size: availableSize,
                    contentMode: .scaleAspectFit
                ) { view in
                    if let track = screenSharing.participant.screenshareTrack {
                        log.debug("adding screensharing track to a view \(view)")
                        view.add(track: track)
                    }
                }
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.participants) { participant in
                        VideoCallParticipantView(
                            participant: participant,
                            availableSize: .init(width: thumbnailSize, height: thumbnailSize)
                        ) { participant, view in
                            if let track = participant.track {
                                view.add(track: track)
                            }
                        }
                        .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                        .cornerRadius(8)
                        
                        LocalVideoView(callSettings: viewModel.callSettings) { view in
                            if let track = viewModel.localParticipant?.track {
                                view.add(track: track)
                            } else {
                                viewModel.renderLocalVideo(renderer: view)
                            }
                        }
                        .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                        .cornerRadius(8)
                    }
                }
                .frame(height: thumbnailSize)
                .cornerRadius(8)
            }
            .padding()
            
            Spacer(minLength: thumbnailSize)
        }
        .background(Color.black)
    }
}
