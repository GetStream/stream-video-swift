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
            CornerDraggableView(
                content: { content(for: $0) },
                proxy: proxy,
                onTap: {
                    viewModel.isMinimized = false
                }
            )
        }
    }
    
    func content(for availableFrame: CGRect) -> some View {
        Group {
            if !viewModel.participants.isEmpty {
                VideoCallParticipantView(
                    participant: viewModel.participants[0],
                    availableFrame: availableFrame,
                    contentMode: .scaleAspectFill,
                    customData: [:],
                    call: viewModel.call
                )
            } else {
                EmptyView()
            }
        }
    }
}
