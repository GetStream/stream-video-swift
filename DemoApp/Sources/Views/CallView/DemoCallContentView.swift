//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
            SimpleCallingView(viewModel: viewModel, callId: callId)
        case (false, .simple):
            SimpleCallingView(viewModel: viewModel, callId: callId)
        case (false, .detailed):
            DetailedCallingView(viewModel: viewModel)
        }
    }
}

