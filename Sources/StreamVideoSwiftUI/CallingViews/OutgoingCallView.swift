//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct OutgoingCallView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
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
    }
}

struct OutgoingCallBackground: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        ZStack {
            if viewModel.callSettings.videoOn && !isSimulator {
                LocalVideoView(callSettings: viewModel.callSettings) { view in
                    if let track = viewModel.localParticipant?.track {
                        view.add(track: track)
                    } else {
                        viewModel.renderLocalVideo(renderer: view)
                    }
                }
            } else if viewModel.participants.count == 1 {
                CallingScreenBackground(imageURL: viewModel.participants.first?.profileImageURL)
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
