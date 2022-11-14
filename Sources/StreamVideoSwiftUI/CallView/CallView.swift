//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct CallView<Factory: ViewFactory>: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    private let padding: CGFloat = 16
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewFactory: Factory, viewModel: CallViewModel) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { reader in
            ZStack {
                viewFactory.makeVideoParticipantsView(
                    participants: viewModel.participants,
                    availableSize: reader.size,
                    onViewRendering: handleViewRendering(_:participant:),
                    onChangeTrackVisibility: viewModel.changeTrackVisbility(for:isVisible:)
                )
                
                VStack {
                    Spacer()
                    if let event = viewModel.participantEvent {
                        Text("\(event.user) \(event.action.display) the call.")
                            .padding(8)
                            .foregroundColor(colors.text)
                            .modifier(ShadowViewModifier())
                            .padding()
                    }
                    
                    viewFactory.makeCallControlsView(viewModel: viewModel)
                }
                
                TopRightView {
                    VStack(alignment: .trailing, spacing: padding) {
                        Button {
                            viewModel.participantsShown.toggle()
                        } label: {
                            images.participants
                                .padding(.horizontal)
                                .padding(.horizontal, 2)
                                .foregroundColor(.white)
                        }
                        
                        LocalVideoView(callSettings: viewModel.callSettings, showBackground: false) { view in
                            if let track = viewModel.localParticipant?.track {
                                view.add(track: track)
                            } else {
                                viewModel.renderLocalVideo(renderer: view)
                            }
                        }
                        .frame(width: reader.size.width / 4 + padding, height: reader.size.width / 3 + padding)
                        .background(Color.red)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .opacity(viewModel.localParticipant != nil ? 1 : 0)
                    }
                }
                
                if viewModel.participantsShown {
                    viewFactory.makeTrailingTopView(
                        viewModel: viewModel,
                        availableSize: reader.size
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private var participants: [CallParticipant] {
        viewModel.participants
    }
    
    private func handleViewRendering(_ view: VideoRenderer, participant: CallParticipant) {
        if let track = participant.track, participant.id != streamVideo.user.id {
            log.debug("adding track to a view \(view)")
            view.add(track: track)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let prev = participant.trackSize
                if prev != view.bounds.size {
                    let updated = participant.withUpdated(trackSize: view.bounds.size)
                    viewModel.callParticipants[participant.id] = updated
                }
            }
        }
    }
}

public struct CallParticipantsInfoView: View {
    
    private let padding: CGFloat = 16
    
    @ObservedObject var viewModel: CallViewModel
    var availableSize: CGSize
    
    public var body: some View {
        VStack {
            CallParticipantsView(
                viewModel: viewModel,
                maxHeight: availableSize.height - padding
            )
            .padding()
            .padding(.vertical, padding / 2)
            
            Spacer()
        }
    }
}
