//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct TrailingView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        HStack {
            Spacer()
            content()
        }
    }
}

struct TopView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        VStack {
            content()
            Spacer()
        }
    }
    
}

struct BottomView<Content: View>: View {
    
    var content: () -> Content
    
    var body: some View {
        VStack {
            Spacer()
            content()
        }
    }
    
}
