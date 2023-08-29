//
//  DemoCallContentView.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import SwiftUI
import StreamVideoSwiftUI

struct DemoCallContentView: View {

    @ObservedObject var viewModel: CallViewModel
    var callId: String

    var body: some View {
        switch AppEnvironment.configuration {
        case .test:
            TestCallingView(viewModel: viewModel)
        case .debug:
            DebugCallingView(viewModel: viewModel)
        case .release:
            ReleaseCallingView(viewModel: viewModel, callId: callId)
        }
    }

}

