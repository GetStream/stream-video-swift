//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct LoginView: View {

    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> Void
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

    @State var addUserShown = false
    @ObservedObject private var appState: AppState = .shared
    @State private var showJoinCallPopup = false
    @State private var error: Error?

    init(completion: @escaping (UserCredentials) -> Void) {
        _viewModel = StateObject(wrappedValue: LoginViewModel())
        self.completion = completion
    }

    func delete(at offsets: IndexSet) {
        var users = AppState.shared.users
        users.remove(atOffsets: offsets)
        AppState.shared.users = users
    }

    var body: some View {
        VStack(spacing: layout.spacingXs) {
            List {
                Section {
                    ForEach(appState.users) { user in
                        BuiltInUserView(
                            user: user,
                            viewModel: viewModel,
                            completion: completion
                        )
                        .deleteDisabled(User.builtIn.first { $0.id == user.id } != nil)
                    }
                    .onDelete(perform: delete)

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
                        viewModel.login(
                            user: .guest(String(String.unique.prefix(8))),
                            completion: completion
                        )
                    } title: {
                        Text("Guest User")
                            .accessibility(identifier: "Login as Guest")
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.clock.fill")
                    }
                    
                    if isGoogleSignInAvailable {
                        LoginItemView {
                            viewModel.ssoLogin { result in
                                switch result {
                                case let .success(credentials):
                                    completion(credentials)
                                case let .failure(failure):
                                    log.error(failure)
                                    error = failure
                                }
                                AppState.shared.loading = false
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
        .foregroundColor(Color(colors.textPrimary))
        .overlay(
            appState.loading ? ProgressView() : nil
        )
        .sheet(isPresented: $addUserShown, onDismiss: {}) {
            DemoAddUserView()
        }
        .halfSheet(isPresented: $showJoinCallPopup) {
            JoinCallView(viewModel: viewModel, completion: completion)
        }
        .navigationTitle("Select a user")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                DebugMenu()
            }
        }
        .alert(isPresented: .constant(error != nil), content: {
            Alert(
                title: Text("Error"),
                message: Text(error!.localizedDescription),
                dismissButton: .cancel { error = nil }
            )
        })
        .background(Color(colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
        .onReceive(appState.$deeplinkInfo) { [weak viewModel] deeplinkInfo in
            guard appState.userState == .notLoggedIn, deeplinkInfo != .empty else { return }
            viewModel?.login(
                user: User(id: String(String.unique.prefix(8))),
                completion: completion
            )
        }
    }

    private var isGoogleSignInAvailable: Bool {
        guard
            let clientId: String = AppEnvironment.value(for: .googleClientId),
            let reversedClientId: String = AppEnvironment.value(for: .googleReversedClientId),
            !clientId.isEmpty,
            !reversedClientId.isEmpty
        else {
            return false
        }

        return true
    }
}

struct LoginItemView<Title: View, Icon: View>: View {

    @Injected(\.layout) private var layout

    var selected: Binding<Bool>
    var action: () -> Void
    var title: Title
    var icon: Icon

    init(
        selected: Binding<Bool> = .constant(false),
        action: @escaping () -> Void,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder icon: @escaping () -> Icon
    ) {
        self.selected = selected
        self.action = action
        self.title = title()
        self.icon = icon()
    }

    var body: some View {
        HStack(spacing: layout.spacingXs) {
            Button {
                action()
            } label: {
                Label {
                    title
                } icon: {
                    icon
                }
            }

            if selected.wrappedValue {
                Spacer()
                Image(systemName: "checkmark")
            }
        }
        .padding(layout.spacingXs)
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
            AppUserView(user: user)
        }
    }
}

struct AppUserView: View {

    @Injected(\.colors) private var colors
    var user: User
    var size: CGFloat = 32
    var overrideUserName: String?

    var body: some View {
        if user.imageURL != nil {
            DemoAppViewFactory
                .shared
                .makeUserAvatar(options: .init(user: user, size: size))
                .accessibilityIdentifier("userAvatar")
        } else if let firstCharacter = (overrideUserName ?? user.name).first {
            Text(String(firstCharacter))
                .fontWeight(.medium)
                .foregroundColor(Color(colors.textPrimary))
                .frame(width: size, height: size)
                .background(Color(colors.backgroundCoreSurfaceDefault))
                .clipShape(Circle())
                .accessibilityIdentifier("userAvatar")
        }
    }
}
