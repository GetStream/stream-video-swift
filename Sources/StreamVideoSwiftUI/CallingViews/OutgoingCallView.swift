//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct OutgoingCallView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    @ObservedObject var viewModel: CallViewModel
    
    public init(viewModel: CallViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()
                
                if viewModel.outgoingCallMembers.count > 1 {
                    CallingGroupView(
                        participants: viewModel.outgoingCallMembers
                    )
                } else {
                    AnimatingParticipantView(
                        participant: viewModel.outgoingCallMembers.first
                    )
                }
                
                CallingParticipantsView(
                    participants: viewModel.outgoingCallMembers
                )
                .padding()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(L10n.Call.Outgoing.title)
                        .applyCallingStyle()
                    CallingIndicator()
                }

                Spacer()
                       
                CallControlsView(viewModel: viewModel)
            }
        }
        .background(
            OutgoingCallBackground(viewModel: viewModel)
        )
        .onAppear {
            if streamVideo.videoConfig.playSounds {
                utils.callSoundsPlayer.playOutgoingCallSound()
            }
        }
        .onDisappear {
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }
}

struct OutgoingCallBackground: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        ZStack {
            if viewModel.outgoingCallMembers.count == 1 {
                CallingScreenBackground(imageURL: viewModel.outgoingCallMembers.first?.imageURL)
            } else {
                FallbackBackground()
            }
        }
    }
}

var isSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}
