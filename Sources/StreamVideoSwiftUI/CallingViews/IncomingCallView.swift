//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct IncomingCallView: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    @StateObject var viewModel: IncomingViewModel
            
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void
    
    public init(
        callInfo: IncomingCall,
        onCallAccepted: @escaping (String) -> Void,
        onCallRejected: @escaping (String) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: IncomingViewModel(callInfo: callInfo)
        )
        self.onCallAccepted = onCallAccepted
        self.onCallRejected = onCallRejected
    }
    
    public var body: some View {
        IncomingCallViewContent(
            callParticipants: viewModel.callParticipants,
            callInfo: viewModel.callInfo,
            onCallAccepted: onCallAccepted,
            onCallRejected: onCallRejected
        )
        .onChange(of: viewModel.hideIncomingCallScreen) { newValue in
            if newValue {
                onCallRejected(viewModel.callInfo.id)
            }
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
}

struct IncomingCallViewContent: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    var callParticipants: [Member]
    var callInfo: IncomingCall
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if callParticipants.count > 1 {
                CallingGroupView(
                    participants: callParticipants
                )
            } else {
                AnimatingParticipantView(
                    participant: callParticipants.first,
                    caller: callInfo.caller.id
                )
            }
            
            CallingParticipantsView(
                participants: callParticipants,
                caller: callInfo.caller.id
            )
            .padding()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(L10n.Call.Incoming.title)
                    .applyCallingStyle()
                CallingIndicator()
            }
            
            Spacer()
            
            HStack {
                Spacing()
                
                Button {
                    onCallRejected(callInfo.id)
                } label: {
                    Image(systemName: "phone.down.circle.fill")
                        .applyCallButtonStyle(
                            color: Color.red,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)
                
                Spacing(size: 3)
                
                Button {
                    onCallAccepted(callInfo.id)
                } label: {
                    images.acceptCall
                        .applyCallButtonStyle(
                            color: Color.green,
                            backgroundType: .circle,
                            size: 80
                        )
                }
                .padding(.all, 8)
                
                Spacing()
            }
            .padding()
        }
        .background(
            CallBackground()
        )
        .onAppear {
            utils.callSoundsPlayer.playIncomingCallSound()
        }
        .onDisappear {
            utils.callSoundsPlayer.stopOngoingSound()
        }
    }
}
