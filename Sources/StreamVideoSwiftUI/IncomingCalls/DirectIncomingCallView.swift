//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct DirectIncomingCallView: View {
    
    var participant: CallParticipant?
    var incomingCall: IncomingCall
    
    var body: some View {
        ZStack {
            if let participant = participant {
                IncomingCallParticipantView(participant: participant)
            } else {
                CircledTitleView(title: String(incomingCall.callerId.uppercased().first!))
            }
        }
    }
}
