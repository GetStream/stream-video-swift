//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoSessionTimerView: View {
    
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    @ObservedObject var sessionTimer: SessionTimer
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: layout.spacingXs) {
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
                            .font(fonts.bodyBold)
                    })
                }
            }
            .foregroundColor(Color(colors.textPrimary))
            .padding(.horizontal, layout.spacingMd)
            .padding(.vertical, layout.spacingXxs)
            .background(Color(colors.backgroundCoreSurfaceDefault))
            .clipShape(Capsule())
            .frame(height: 60)
            .padding(.top, 80)
            
            Spacer()
        }
    }
}
