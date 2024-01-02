//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SwiftUI
import ReplayKit

public struct BroadcastPickerView: UIViewRepresentable {
    
    let preferredExtension: String
    var size: CGFloat
    
    public init(preferredExtension: String, size: CGFloat = 30) {
        self.preferredExtension = preferredExtension
        self.size = size
    }
    
    public func makeUIView(context: Context) -> some UIView {
        let view = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: size, height: size))
        view.preferredExtension = preferredExtension
        view.showsMicrophoneButton = false
        return view
    }
    
    public func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}
