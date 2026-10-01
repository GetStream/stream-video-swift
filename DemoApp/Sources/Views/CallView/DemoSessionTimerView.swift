//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoSessionTimerView: View {
    
    @Injected(\.videoAppearance) var videoAppearance
    @Injected(\.formatters.mediaDuration) private var formatter: MediaDurationFormatter

    @ObservedObject var sessionTimer: SessionTimer
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: tokens.layout.spacingXs) {
                if let duration = formatter.format(sessionTimer.secondsUntilEnd) {
                    Text("Call will end in \(duration)")
                        .font(tokens.fonts.body.monospacedDigit())
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
                            .font(tokens.fonts.bodyBold)
                    })
                }
            }
            .foregroundColor(Color(tokens.colors.textPrimary))
            .padding(.horizontal, tokens.layout.spacingMd)
            .padding(.vertical, tokens.layout.spacingXxs)
            .background(Color(tokens.colors.backgroundCoreSurfaceDefault))
            .clipShape(Capsule())
            .frame(height: 60)
            .padding(.top, 80)
            
            Spacer()
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
