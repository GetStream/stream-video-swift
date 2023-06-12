//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct JoiningCallView<CallControls: View>: View {
    
    var callControls: CallControls
    
    public init(callControls: CallControls) {
        self.callControls = callControls
    }
    
    public var body: some View {
        CallConnectingView(
            outgoingCallMembers: [],
            title: L10n.Call.Joining.title,
            callControls: callControls
        )
    }
}
