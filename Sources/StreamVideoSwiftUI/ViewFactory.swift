//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public protocol ViewFactory: AnyObject {
    
    associatedtype CallControlsViewType: View
    func makeCallControlsView(viewModel: CallViewModel) -> CallControlsViewType
}

extension ViewFactory {
    
    public func makeCallControlsView(viewModel: CallViewModel) -> some View {
        CallControlsView(viewModel: viewModel)
    }
}

public class DefaultViewFactory: ViewFactory {
    
    private init() { /* Private init. */ }
    
    public static let shared = DefaultViewFactory()
}
