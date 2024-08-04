//
//  View+PresetnDemoMoreMenu.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 6/8/24.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

extension View {

    @ViewBuilder
    func presentsMoreControls(viewModel: CallViewModel) -> some View {
        modifier(DemoMoreControlsViewModifier(viewModel: viewModel))
    }
}
