//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

class AppState: ObservableObject {
    
    @Published var userState: UserState = .notLoggedIn
    @Published var deeplinkCallId: String?
    @Published var activeCallController: CallController?
    @Published var currentUser: User?
    
    var streamVideo: StreamVideo?
    
    static let shared = AppState()
    
    private init() {}
}

enum UserState {
    case notLoggedIn
    case loggedIn
}
