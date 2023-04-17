//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct MinimizedCallView: View {
    @ObservedObject var viewModel: CallViewModel
    
    @State var callViewPlacement = CallViewPlacement.topTrailing
    
    @State private var dragAmount = CGSize.zero
        
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { proxy in
            CornerDragableView(
                content: content(for: proxy),
                proxy: proxy,
                onTap: {
                    viewModel.isMinimized = false
                }
            )
        }
    }
    
    func content(for proxy: GeometryProxy) -> some View {
        Group {
            if !viewModel.participants.isEmpty {
                VideoCallParticipantView(
                    participant: viewModel.participants[0],
                    availableSize: proxy.size,
                    contentMode: .scaleAspectFill
                ) { participant, view in
                    view.handleViewRendering(for: participant) { size, participant in
                        viewModel.updateTrackSize(size, for: participant)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}
