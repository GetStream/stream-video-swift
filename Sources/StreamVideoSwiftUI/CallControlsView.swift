//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

public struct CallControlsView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    public var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                viewModel.toggleCameraEnabled()
            },
            label: {
                Image(systemName: viewModel.cameraTrackState.isPublished ? "video.slash.fill" : "video.fill")
                    .applyCallButtonStyle(color: .black, backgroundType: .none)
            })
            .disabled(viewModel.cameraTrackState.isBusy)
            
            Spacer()
            
            Button(action: {
                viewModel.toggleMicrophoneEnabled()
            },
            label: {
                Image(systemName: viewModel.microphoneTrackState.isPublished ? "mic.slash.circle.fill" : "mic.circle.fill")
                    .applyCallButtonStyle(color: .black)
            })
            .disabled(viewModel.microphoneTrackState.isBusy)
            
            Spacer()
            
            Button(action: {
                viewModel.toggleCameraPosition()
            },
            label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    .applyCallButtonStyle(color: .black, backgroundType: .rectangle)
            })
            
            Spacer()
            
            Button {
                viewModel.leaveCall()
            } label: {
                Image(systemName: "phone.circle.fill")
                    .applyCallButtonStyle(color: Color(.systemRed))
            }
            .padding(.all, 8)
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
        )
    }
}
