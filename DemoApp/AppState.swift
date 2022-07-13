//
//  AppState.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.7.22.
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
