//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallingParticipantView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var participant: Member?
    var caller: String = ""
    
    var body: some View {
        ZStack {
            if let participant = participant {
                IncomingCallParticipantView(
                    viewFactory: viewFactory,
                    participant: participant
                )
            } else {
                CircledTitleView(title: caller.isEmpty ? "" : String(caller.uppercased().first!))
            }
        }
    }
}
