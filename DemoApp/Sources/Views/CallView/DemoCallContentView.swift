//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideoSwiftUI

struct DemoCallContentView: View {

    @ObservedObject var viewModel: CallViewModel
    var callId: String

    var body: some View {
        switch (AppEnvironment.configuration.isRelease, AppEnvironment.loggedInView) {
        case (true, _):
            ReleaseCallingView(viewModel: viewModel, callId: callId)
        case (false, .simple):
            DebugCallingView(viewModel: viewModel)
        case (false, .detailed):
            TestCallingView(viewModel: viewModel)
        }
    }

}

