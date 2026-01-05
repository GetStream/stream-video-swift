//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {

    container {
        final class CustomCallViewModel: CallViewModel {
            var permissionRequest: PermissionRequestEvent?
            @Published var permissionPopupShown = false

            func subscribeForPermissionsRequests() {
                Task {
                    for await request in call!.subscribe(for: PermissionRequestEvent.self) {
                        self.permissionRequest = request
                    }
                }
            }

            func grantUserPermissions() async throws {
                guard let request = permissionRequest else { return }
                let permissionRequests = request.permissions.map { PermissionRequest(
                    permission: $0,
                    user: request.user.toUser,
                    requestedAt: request.createdAt
                ) }
                for permissionRequest in permissionRequests {
                    try await call?.grant(request: permissionRequest)
                }
            }
        }

        struct CustomView: View {
            @ObservedObject var viewModel: CustomCallViewModel
            var body: some View {
                YourHostView()
                    .alert(isPresented: $viewModel.permissionPopupShown) {
                        Alert(
                            title: Text("Permission request"),
                            message: Text("\(viewModel.permissionRequest?.user.name ?? "Someone") raised their hand to speak."),
                            primaryButton: .default(Text("Allow")) {
                                Task {
                                    try await viewModel.grantUserPermissions()
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
            }
        }
    }
}
