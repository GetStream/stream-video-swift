//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

class AppState: ObservableObject {
    
    @Published var userState: UserState = .notLoggedIn
    
    static let shared = AppState()
    
    private init() {}
}

enum UserState {
    case notLoggedIn
    case loggedIn
}
