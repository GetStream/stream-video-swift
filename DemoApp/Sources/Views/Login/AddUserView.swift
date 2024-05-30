//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct DemoAddUserView: View {

    @Injected(\.appearance) var appearance
    @Environment(\.presentationMode) var presentationMode

    @State var name = ""
    @State var id = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Group {
                        TextField("User id", text: $id)

                        TextField("Name", text: $name)
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
        name.isEmpty || id.isEmpty
    }
}

struct DemoCustomEnvironmentView: View {

    @Injected(\.appearance) var appearance
    @Environment(\.presentationMode) var presentationMode

    @State var baseURL: AppEnvironment.BaseURL
    @State var apiKey: String
    @State var token: String
    var completionHandler: (AppEnvironment.BaseURL, String, String) -> Void

    var body: some View {
        ScrollView {
            VStack {
                Picker("Base on which environment?", selection: $baseURL) {
                    Text(AppEnvironment.BaseURL.demo.title).tag(AppEnvironment.BaseURL.demo)
                    Text(AppEnvironment.BaseURL.pronto.title).tag(AppEnvironment.BaseURL.pronto)
                }
                .pickerStyle(.segmented)

                TextField("API Key", text: $apiKey)
                    .textFieldStyle(DemoTextfieldStyle())

                DemoTextEditor(text: $token, placeholder: "Token")

                Button {
                    completionHandler(baseURL, apiKey, token)
                } label: {
                    CallButtonView(
                        title: "Complete Setup",
                        isDisabled: buttonDisabled
                    )
                    .disabled(buttonDisabled)
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Custom Environment")
    }

    private var buttonDisabled: Bool {
        apiKey.isEmpty || token.isEmpty
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

struct DemoTextEditor: View {

    @Injected(\.appearance) var appearance

    var text: Binding<String>
    @State var cornerRadius: CGFloat = 8

    var placeholder: String

    private let notificationCenter: NotificationCenter = .default

    @ViewBuilder
    private var clipShape: some Shape { RoundedRectangle(cornerRadius: cornerRadius) }

    var body: some View {
        withPlaceholder {
            withClearBackgroundContent
                .lineLimit(4)
                .padding()
                .foregroundColor(
                    text.wrappedValue == placeholder
                        ? .init(appearance.colors.textLowEmphasis)
                        : appearance.colors.text
                )
                .background(Color(appearance.colors.background))
                .overlay(clipShape.stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))
                .clipShape(clipShape)
                .frame(height: 100)
        }
    }

    @ViewBuilder
    private var withClearBackgroundContent: some View {
        if #available(iOS 16.0, *) {
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
        } else {
            TextEditor(text: text)
        }
    }

    @ViewBuilder
    private func withPlaceholder(
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .onReceive(
                notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification),
                perform: { _ in
                    withAnimation {
                        if self.text.wrappedValue == placeholder {
                            self.text.wrappedValue = ""
                        }
                    }
                }
            )
            .onReceive(
                notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification),
                perform: { _ in
                    withAnimation {
                        if self.text.wrappedValue.isEmpty {
                            self.text.wrappedValue = placeholder
                        }
                    }
                }
            )
            .onAppear {
                if text.wrappedValue.isEmpty {
                    text.wrappedValue = placeholder
                }
            }
    }
}
