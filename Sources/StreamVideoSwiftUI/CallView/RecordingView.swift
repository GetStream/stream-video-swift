//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct RecordingView: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.layout) var layout
    
    public init() { /* Public init. */ }
    
    public var body: some View {
        HStack(spacing: layout.spacingXs) {
            Circle()
                .fill(Color(colors.accentError))
                .frame(height: layout.iconSizeXs)
            Text(L10n.Call.Current.recording)
                .font(fonts.bodyBold)
                .foregroundColor(Color(colors.textOnAccent))
            Spacer()
        }
        .padding(.horizontal, layout.spacingXs)
    }
}
