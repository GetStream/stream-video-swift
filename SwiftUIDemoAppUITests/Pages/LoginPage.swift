//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

enum LoginPage {
    
    static var users: XCUIElementQuery { app.buttons.matching(NSPredicate(format: "identifier LIKE 'userName'")) }
    
}
