//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct Spacing: View {
    
    var size = 1
    
    var body: some View {
        ForEach(0..<size, id: \.self) { _ in
            Spacer()
        }
    }
}
