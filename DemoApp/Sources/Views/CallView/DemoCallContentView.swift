//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallContentView: View {

    @ObservedObject var viewModel: CallViewModel
    var callId: String
    var loggedInView: AppEnvironment.LoggedInView

    var body: some View {
        Group {
            switch (AppEnvironment.configuration.isRelease, loggedInView) {
            case (true, _):
                SimpleCallingView(viewModel: viewModel, callId: callId)
            case (false, .simple):
                SimpleCallingView(viewModel: viewModel, callId: callId)
            case (false, .detailed):
                DetailedCallingView(viewModel: viewModel, callId: callId)
            }
        }
    }
}
