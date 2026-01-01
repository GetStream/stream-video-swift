//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct JoiningCallView<CallControls: View, CallTopView: View, Factory: ViewFactory>: View {

    var viewFactory: Factory
    var callTopView: CallTopView
    var callControls: CallControls
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        callTopView: CallTopView,
        callControls: CallControls
    ) {
        self.viewFactory = viewFactory
        self.callTopView = callTopView
        self.callControls = callControls
    }
    
    public var body: some View {
        CallConnectingView(
            viewFactory: viewFactory,
            outgoingCallMembers: [],
            title: L10n.Call.Joining.title,
            callControls: callControls,
            callTopView: callTopView
        )
    }
}
