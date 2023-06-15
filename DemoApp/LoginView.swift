//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct LoginView: View {
    
    @StateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()
    
    @State var addUserShown = false
    
    init(completion: @escaping (UserCredentials) -> ()) {
        _viewModel = StateObject(wrappedValue: LoginViewModel())
        self.completion = completion
    }
    
    var body: some View {
        VStack {
            Text("Select a user")
                .font(.title)
                .bold()

            List {
                Section {
                    ForEach(viewModel.users) { user in
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

                    Button {
                        viewModel.login(user: .anonymous, completion: completion)
                    } label: {
                        Text("Anonymous User")
                            .accessibility(identifier: "Login as Anonymous")
                    }
                    .padding(.all, 8)
                } header: {
                    Text("Other")
                }
            }
        }
        .foregroundColor(.primary)
        .overlay(
            viewModel.loading ? ProgressView() : nil
        )
        .sheet(isPresented: $addUserShown, onDismiss: {
            viewModel.users = User.builtInUsers
        }) {
            AddUserView()
        }
    }
}
