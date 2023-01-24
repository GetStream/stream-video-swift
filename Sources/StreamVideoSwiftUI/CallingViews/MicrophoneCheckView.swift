//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct MicrophoneCheckView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo
    
    var decibels: [Float]
    var microphoneOn: Bool
    var hasDecibelValues: Bool
    let maxHeight: Float = 14
    
    var body: some View {
        HStack(spacing: 2) {
            Text(streamVideo.user.name)
                .font(.caption)
                .foregroundColor(.white)
                .bold()
                .padding(.trailing, 8)
            
            if microphoneOn && hasDecibelValues {
                ForEach(decibels, id: \.self) { decibel in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.primaryButtonBackground)
                            .frame(width: 2, height: height(for: decibel))
                    }
                    .frame(height: CGFloat(maxHeight))
                }
            } else {
                images.micTurnOff
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: CGFloat(maxHeight))
                    .foregroundColor(colors.accentRed)
            }
        }
        .padding(.all, 8)
        .background(Color.black.opacity(0.6).cornerRadius(8))
    }
    
    private func height(for decibel: Float) -> CGFloat {
        let value = abs(decibel)
        let ratio = value / 60.0
        let height = CGFloat(maxHeight - ratio * maxHeight)
        return max(height, 0.5)
    }
}
