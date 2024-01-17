//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct JoiningCallView<CallControls: View, CallTopView: View>: View {

    var callTopView: CallTopView
    var callControls: CallControls
    
    public init(
        callTopView: CallTopView,
        callControls: CallControls
    ) {
        self.callTopView = callTopView
        self.callControls = callControls
    }
    
    public var body: some View {
        CallConnectingView(
            outgoingCallMembers: [],
            title: L10n.Call.Joining.title,
            callControls: callControls,
            callTopView: callTopView
        )
    }
}
