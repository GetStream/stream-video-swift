//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct RecordingView: View {
    
    @Injected(\.colors) var colors
    
    public init() { /* Public init. */}
    
    public var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(height: 12)
            Text(L10n.Call.Current.recording)
                .bold()
                .foregroundColor(colors.text)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
