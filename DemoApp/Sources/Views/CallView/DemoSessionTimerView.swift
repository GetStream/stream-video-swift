//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoSessionTimerView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    @ObservedObject var sessionTimer: SessionTimer
    
    var body: some View {
        VStack {
            HStack {
                if let duration = formatter.format(sessionTimer.secondsUntilEnd) {
                    Text("Call will end in \(duration)")
                        .font(fonts.body.monospacedDigit())
                        .minimumScaleFactor(0.2)
                        .lineLimit(1)
                } else {
                    Text("Call will end soon")
                }
                Divider()
                if sessionTimer.showExtendCallDurationButton {
                    Button(action: {
                        sessionTimer.extendCallDuration()
                    }, label: {
                        Text("Extend for \(Int(sessionTimer.extensionTime / 60)) min")
                            .bold()
                    })
                }
            }
            .foregroundColor(Color(colors.callDurationColor))
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(colors.participantBackground))
            .clipShape(Capsule())
            .frame(height: 60)
            .padding(.top, 80)
            
            Spacer()
        }
    }
}
