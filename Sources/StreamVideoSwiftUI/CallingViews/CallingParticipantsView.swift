//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallingParticipantsView: View {
    
    @Injected(\.fonts) var fonts
    
    var participants: [Member]
    var caller: String = ""
    
    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .font(participants.count > 1 ? fonts.title2 : fonts.title)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
    }
    
    private var text: String {
        if participants.isEmpty {
            return caller
        } else if participants.count == 1 {
            return participants[0].user.name
        } else {
            return multipleParticipantsText
        }
    }
    
    private var multipleParticipantsText: String {
        if participants.count == 2 {
            return "\(participants[0].user.name) and \(participants[1].user.name)"
        } else if participants.count == 3 {
            return "\(participants[0].user.name), \(participants[1].user.name) and \(participants[2].user.name)"
        } else {
            let remaining = participants.count - 2
            return "\(participants[0].user.name), \(participants[1].user.name) and +\(remaining) more"
        }
    }
}
