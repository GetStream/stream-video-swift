//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct PopoverButton: View {
        
    var title: String
    @Binding var popoverShown: Bool
    var action: () -> Void
    
    public init(title: String, popoverShown: Binding<Bool>, action: @escaping () -> Void) {
        self.title = title
        _popoverShown = popoverShown
        self.action = action
    }
    
    public var body: some View {
        Button {
            action()
            popoverShown = false
        } label: {
            Text(title)
                .padding(.horizontal)
                .foregroundColor(.primary)
        }
    }
}
