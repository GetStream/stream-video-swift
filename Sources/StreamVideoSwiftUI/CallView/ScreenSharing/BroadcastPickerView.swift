//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import ReplayKit

struct BroadcastPickerView: UIViewRepresentable {
    
    let preferredExtension: String
    var size: CGFloat = 30
    
    func makeUIView(context: Context) -> some UIView {
        let view = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: size, height: size))
        view.preferredExtension = preferredExtension
        view.showsMicrophoneButton = false
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}
