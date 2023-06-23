//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallTopView: View {
            
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            Button {
                withAnimation {
//                    viewModel.isMinimized = true
                    NotificationCenter.default.post(name: NSNotification.Name("simulateGoAway"), object: nil)
                }
            } label: {
//                Image(systemName: "chevron.left")
//                    .foregroundColor(colors.textInverted)
//                    .padding()
                Text("Migrate")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .accessibility(identifier: "minimizeCallViewButton")
            
            if viewModel.recordingState == .recording {
                RecordingView()
                    .accessibility(identifier: "recordingLabel")
            }

            Spacer()
            
            
            if #available(iOS 14, *) {
                LayoutMenuView(viewModel: viewModel)
                    .opacity(viewModel.screensharingSession != nil ? 0 : 1)
                    .accessibility(identifier: "viewMenu")
                
                Button {
                    viewModel.participantsShown.toggle()
                } label: {
                    images.participants
                        .padding(.horizontal)
                        .padding(.horizontal, 2)
                        .foregroundColor(.white)
                }
                .accessibility(identifier: "participantMenu")
            }
        }
    }
}
