//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

struct CallingParticipantsView: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout
    
    var participants: [Member]
    var caller: String = ""
    
    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .font(
                participants.count > 1
                    ? fonts.title2
                    : fonts.title
            )
            .foregroundColor(Color(colors.textOnAccent))
            .padding(.horizontal, layout.spacing2xl)
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
