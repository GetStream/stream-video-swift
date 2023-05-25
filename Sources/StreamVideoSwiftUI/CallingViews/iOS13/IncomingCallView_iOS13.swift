//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS, introduced: 13, obsoleted: 14)
public struct IncomingCallView_iOS13: View {
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    @BackportStateObject var viewModel: IncomingViewModel
            
    var onCallAccepted: (String) -> Void
    var onCallRejected: (String) -> Void
    
    public init(
        callInfo: IncomingCall,
        onCallAccepted: @escaping (String) -> Void,
        onCallRejected: @escaping (String) -> Void
    ) {
        _viewModel = BackportStateObject(
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
        .onReceive(viewModel.$hideIncomingCallScreen, perform: { value in
            if value {
                onCallRejected(viewModel.callInfo.id)
            }
        })
        .onDisappear {
            viewModel.stopTimer()
        }
    }
}
