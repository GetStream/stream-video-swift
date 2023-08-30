//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct LoginView: View {

    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()
    
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
                        Button {
                            viewModel.login(user: user, completion: completion)
                        } label: {
                            Text(user.name)
                                .accessibility(identifier: "userName")
                        }
                        .padding(8)
                    }

                    Button {
                        addUserShown = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add user")
                        }
                    }
                    .padding(8)
                }

                Section {
                    Button {
                        viewModel.login(user: .guest(UUID().uuidString), completion: completion)
                    } label: {
                        Text("Guest User")
                            .accessibility(identifier: "Login as Guest")
                    }
                    .padding(.all, 8)

                    if AppEnvironment.configuration.isDebug {
                        Button {
                            showJoinCallPopup.toggle()
                        } label: {
                            Text("Anonymous User")
                                .accessibility(identifier: "Login as Anonymous")
                        }
                        .padding(.all, 8)
                    }
                } header: {
                    Text("Other")
                }
            }
        }
        .foregroundColor(.primary)
        .overlay(
            appState.loading ? ProgressView() : nil
        )
        .sheet(isPresented: $addUserShown, onDismiss: {}) {
            AddUserView()
        }
        .sheet(isPresented: $showJoinCallPopup) {
            JoinCallView(viewModel: viewModel, completion: completion)
        }
        .navigationTitle("Select a user")
        .toolbar {
             ToolbarItem(placement: .navigationBarTrailing) {
                 DebugMenu()
              }
          }
    }
}
struct DebugMenu: View {

    @Injected(\.colors) var colors

    @State private var loggedInView: AppEnvironment.LoggedInView = AppEnvironment.loggedInView {
        didSet { AppEnvironment.loggedInView = loggedInView }
    }

    @State private var baseURL: AppEnvironment.BaseURL = AppEnvironment.baseURL {
        didSet {
            switch baseURL {
            case .staging:
                AppEnvironment.baseURL = .staging
                AppEnvironment.apiKey = .staging
            case .production:
                AppEnvironment.baseURL = .production
                AppEnvironment.apiKey = .production
            }
        }
    }

    var body: some View {
        Menu {
            makeMenu(
                for: [.production, .staging],
                currentValue: baseURL,
                label: "Environment"
            ) { self.baseURL = $0 }

            makeMenu(
                for: [.simple, .detailed],
                currentValue: loggedInView,
                label: "LoggedIn View"
            ) { self.loggedInView = $0 }
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundColor(colors.text)
        }
    }

    @ViewBuilder
    private func makeMenu<Item: Debuggable>(
        for items: [Item],
        currentValue: Item,
        label: String,
        updater: @escaping (Item) -> Void
    ) -> some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    updater(item)
                } label: {
                    Label {
                        Text(item.title)
                    } icon: {
                        currentValue == item
                        ? AnyView(Image(systemName: "checkmark"))
                        : AnyView(EmptyView())
                    }
                }
            }
        } label: {
            Text(label)
        }
    }
}
