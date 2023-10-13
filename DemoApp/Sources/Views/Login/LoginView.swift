//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct LoginView: View {

    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()
    @Injected(\.appearance) var appearance

    @State var addUserShown = false
    @State private var appState: AppState = .shared
    @State private var showJoinCallPopup = false
    
    init(completion: @escaping (UserCredentials) -> ()) {
        _viewModel = StateObject(wrappedValue: LoginViewModel())
        self.completion = completion
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    ForEach(appState.users) { user in
                        BuiltInUserView(
                            user: user,
                            viewModel: viewModel,
                            completion: completion
                        )
                    }

                    LoginItemView {
                        addUserShown = true
                    } title: {
                        Text("Add user")
                    } icon: {
                        Image(systemName: "plus")
                    }
                } header: {
                    Text("Built-In")
                }

                Section {
                    LoginItemView {
                        viewModel.login(user: .guest(UUID().uuidString), completion: completion)
                    } title: {
                        Text("Guest User")
                            .accessibility(identifier: "Login as Guest")
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.clock.fill")
                    }
                    
                    if isGoogleSignInAvailable {
                        LoginItemView {
                            Task {
                                let credentials = try await GoogleHelper.signIn()
                                completion(credentials)
                            }
                        } title: {
                            Text("Login with Stream account")
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.clock.fill")
                        }
                    }

                    LoginItemView {
                        showJoinCallPopup.toggle()
                    } title: {
                        Text("Join call")
                            .accessibility(identifier: "Join call anonymously")
                    } icon: {
                        Image(systemName: "phone.arrow.right.fill")
                    }
                } header: {
                    Text("Other")
                }
            }
            .listStyle(.plain)
        }
        .alignedToReadableContentGuide()
        .foregroundColor(appearance.colors.text)
        .overlay(
            appState.loading ? ProgressView() : nil
        )
        .sheet(isPresented: $addUserShown, onDismiss: {}) {
            AddUserView()
        }
        .halfSheetIfAvailable(isPresented: $showJoinCallPopup) {
            JoinCallView(viewModel: viewModel, completion: completion)
        }
        .navigationTitle("Select a user")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                DebugMenu()
            }
        }
    }

    private var isGoogleSignInAvailable: Bool {
        guard
            let clientId: String = AppEnvironment.value(for: .googleClientId),
            let reversedClientId: String = AppEnvironment.value(for: .googleReversedClientId),
            !clientId.isEmpty,
            !reversedClientId.isEmpty
        else{
            return false
        }

        return true
    }
}

struct LoginItemView<Title: View, Icon: View>: View {

    var action: () -> ()
    var title: () -> Title
    var icon: () -> Icon

    var body: some View {
        Button {
            action()
        } label: {
            Label {
                title()
            } icon: {
                icon()
            }
        }
        .padding(8)
    }
}

struct BuiltInUserView: View {

    var user: User
    var viewModel: LoginViewModel
    var completion: (UserCredentials) -> Void

    var body: some View {
        LoginItemView {
            viewModel.login(user: user, completion: completion)
        } title: {
            Text(user.name)
                .accessibility(identifier: "userName")
        } icon: {
            UserAvatar(imageURL: user.imageURL, size: 32)
                .accessibilityIdentifier("userAvatar")
        }
    }
}
