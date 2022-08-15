//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct RoomView<Factory: ViewFactory>: View {
    
    @Injected(\.images) var images
    
    @ObservedObject private var viewModel: CallViewModel
    private var viewFactory: Factory
    
    public init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if let focusParticipant = viewModel.focusParticipant {
                    ParticipantView(viewModel: viewModel, participant: focusParticipant) { _ in
                        viewModel.focusParticipant = nil
                    }
                } else {
                    ParticipantLayout(viewModel.allParticipants.values, spacing: 5) { participant in
                        ParticipantView(viewModel: viewModel, participant: participant) { participant in
                            viewModel.focusParticipant = participant
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
                
            TopView {
                VStack {
                    TrailingView {
                        Button {
                            viewModel.participantsShown.toggle()
                        } label: {
                            images.participants
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
            }

            VStack {
                Spacer()
                if let event = viewModel.participantEvent {
                    Text("\(event.user) \(event.action.display) the call.")
                        .padding(8)
                        .foregroundColor(.white)
                        .modifier(ShadowViewModifier())
                        .padding()
                }
                
                viewFactory.makeCallControlsView(viewModel: viewModel)
            }
            
            if viewModel.participantsShown {
                GeometryReader { reader in
                    VStack {
                        CallParticipantsView(
                            viewModel: viewModel,
                            maxHeight: reader.size.height - 16
                        )
                        .padding()
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
    }
    
    private var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
}

extension RoomView where Factory == DefaultViewFactory {
    public init(
        viewModel: CallViewModel
    ) {
        self.init(viewFactory: DefaultViewFactory.shared, viewModel: viewModel)
    }
}
