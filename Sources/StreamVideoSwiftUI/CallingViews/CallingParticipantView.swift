//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallingParticipantView: View {
    
    var participant: CallParticipant?
    var caller: String = ""
    
    var body: some View {
        ZStack {
            if let participant = participant {
                IncomingCallParticipantView(participant: participant)
            } else {
                CircledTitleView(title: caller.isEmpty ? "" : String(caller.uppercased().first!))
            }
        }
    }
}
