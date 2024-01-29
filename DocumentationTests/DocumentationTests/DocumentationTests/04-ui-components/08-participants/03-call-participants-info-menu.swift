import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        let view = CallParticipantsInfoView(callViewModel: viewModel)
    }

    container {
        func makeParticipantsListView(
            viewModel: CallViewModel,
            availableFrame: CGRect
        ) -> some View {
            CustomCallParticipantsInfoView(
                callViewModel: viewModel,
                availableFrame: availableFrame
            )
        }
    }

    container {
        final class CustomUserProvider: UserListProvider {
            func loadNextUsers(pagination: Pagination) async throws -> [User] {
                // load the users, based on the pagination parameter provided
                return []
            }
        }
    }

    container {
        let utils = Utils(userListProvider: MockUserListProvider())
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)
    }
}
