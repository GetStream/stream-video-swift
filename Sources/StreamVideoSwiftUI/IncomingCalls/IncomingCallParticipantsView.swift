//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct IncomingCallParticipantsView: View {
    
    @Injected(\.fonts) var fonts
    
    var participants: [CallParticipant]
    var callInfo: IncomingCall
    
    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .font(participants.count > 1 ? fonts.title2 : fonts.title)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
    }
    
    private var text: String {
        if participants.isEmpty {
            return callInfo.callerId
        } else if participants.count == 1 {
            return participants[0].name
        } else {
            return multipleParticipantsText
        }
    }
    
    private var multipleParticipantsText: String {
        if participants.count == 2 {
            return "\(participants[0].name) and \(participants[1].name)"
        } else if participants.count == 3 {
            return "\(participants[0].name), \(participants[1].name) and \(participants[2].name)"
        } else {
            let remaining = participants.count - 2
            return "\(participants[0].name), \(participants[1].name) and +\(remaining) more"
        }
    }
}
