//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct AddUserView: View {

    @Injected(\.appearance) var appearance
    @Environment(\.presentationMode) var presentationMode
    
    @State var name = ""
    @State var id = ""
    @State var token = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Group {
                        TextField("User id", text: $id)

                        TextField("Name", text: $name)

                        TextField("Token", text: $token)
                    }

                    Button {
                        let userInfo = User(
                            id: id,
                            name: name,
                            imageURL: nil,
                            customData: [:]
                        )
                        AppState.shared.users.append(userInfo)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        CallButtonView(
                            title: "Add User",
                            isDisabled: buttonDisabled
                        )
                        .disabled(buttonDisabled)
                    }
                }
                .textFieldStyle(DemoTextfieldStyle())
            }
            .padding()
            .navigationTitle("Add a new User")
        }
    }
    
    private var buttonDisabled: Bool {
        name.isEmpty || id.isEmpty || token.isEmpty
    }
}

struct DemoTextfieldStyle: TextFieldStyle {

    @Injected(\.appearance) var appearance

    @State var cornerRadius: CGFloat = 8

    @ViewBuilder
    private var clipShape: some Shape { RoundedRectangle(cornerRadius: cornerRadius) }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .foregroundColor(appearance.colors.text)
            .background(Color(appearance.colors.background))
            .overlay(clipShape.stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))
            .clipShape(clipShape)
    }
}
