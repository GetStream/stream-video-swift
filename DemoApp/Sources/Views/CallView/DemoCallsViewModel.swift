//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

@MainActor
class DemoCallsViewModel: ObservableObject {
    @Published var streamEmployees = [StreamEmployee]()
    
    func loadEmployees() {
        Task {
            self.streamEmployees = try await GoogleHelper.loadUsers()
        }
    }
}
