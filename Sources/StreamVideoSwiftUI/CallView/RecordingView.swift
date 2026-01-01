//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct RecordingView: View {
    
    public init() { /* Public init. */ }
    
    public var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(height: 12)
            Text(L10n.Call.Current.recording)
                .bold()
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
