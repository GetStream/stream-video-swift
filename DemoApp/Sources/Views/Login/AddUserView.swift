//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

@MainActor
struct DemoCustomEnvironmentView: View {

    @Injected(\.appearance) var appearance
    @Environment(\.presentationMode) var presentationMode

    @State var baseURL: AppEnvironment.BaseURL
    @State var apiKey: String
    @State var token: String
    @State var usesDefaultPushNotificationConfig = false
    @State var pushNotificationName: String = AppState.shared.pushNotificationConfiguration.pushProviderInfo.name
    @State var voIPPushNotificationName: String = AppState.shared.pushNotificationConfiguration.voipPushProviderInfo.name
    var completionHandler: (AppEnvironment.BaseURL, String, String) -> Void

    init(
        baseURL: AppEnvironment.BaseURL,
        apiKey: String,
        token: String,
        completionHandler: @escaping (AppEnvironment.BaseURL, String, String) -> Void
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.token = token
        usesDefaultPushNotificationConfig = AppState.shared.pushNotificationConfiguration == .default
        self.completionHandler = completionHandler
    }

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

                pushNotificationConfiguration

                Button {
                    AppState.shared.pushNotificationConfiguration = usesDefaultPushNotificationConfig
                        ? .default
                        : .init(
                            pushProviderInfo: .init(name: pushNotificationName, pushProvider: .apn),
                            voipPushProviderInfo: .init(name: voIPPushNotificationName, pushProvider: .apn)
                        )
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

    @ViewBuilder
    private var pushNotificationConfiguration: some View {
        VStack {
            DemoCheckboxView(isChecked: $usesDefaultPushNotificationConfig) {
                Text("Use `.default` push notification configuration")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: usesDefaultPushNotificationConfig ? "checkmark.square" : "square")
            }
            .foregroundColor(usesDefaultPushNotificationConfig ? appearance.colors.text : .init(appearance.colors.textLowEmphasis))

            if !usesDefaultPushNotificationConfig {
                VStack {
                    TextField("Push Notification", text: $pushNotificationName)
                    TextField("VoIP Push Notification", text: $voIPPushNotificationName)
                }
                .textFieldStyle(DemoTextfieldStyle())
            }
        }
        .padding(.vertical, 16)
    }
}

@MainActor
struct DemoSFUOverrideView: View {

    @Injected(\.appearance) var appearance
    @Environment(\.presentationMode) var presentationMode

    @State var edgeName: String
    @State var twirpConfiguration: SFUOverrideConfiguration.TwirpConfiguration
    @State private var configuration: SFUOverrideConfiguration
    var completionHandler: (SFUOverrideConfiguration) -> Void

    init(
        configuration: SFUOverrideConfiguration,
        completionHandler: @escaping (SFUOverrideConfiguration) -> Void
    ) {
        self.configuration = configuration
        self.edgeName = configuration.edgeName
        self.twirpConfiguration = configuration.twirpConfiguration
        self.completionHandler = completionHandler
    }

    var body: some View {
        ScrollView {
            VStack {
                TextField("Edge Name", text: $edgeName)
                    .textFieldStyle(DemoTextfieldStyle())

                if !edgeName.isEmpty {
                    Group {
                        urlPreview
                        wsEndpointPreview
                    }
                    .padding(.vertical)
                }

                Button {
                    completionHandler(configuration)
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
        .onChange(of: edgeName) { edgeName in
            self.configuration = .init(
                edgeName: edgeName,
                twirpConfiguration: twirpConfiguration
            )
        }
        .onChange(of: twirpConfiguration) { twirpConfiguration in
            self.configuration = .init(
                edgeName: edgeName,
                twirpConfiguration: twirpConfiguration
            )
        }
    }

    private var buttonDisabled: Bool {
        edgeName.isEmpty || URL(string: configuration.url) == nil || URL(string: configuration.ws) == nil
    }

    @ViewBuilder
    private var urlPreview: some View {
        let value = configuration.url
        let isValid = URL(string: value) != nil
        HStack {
            Menu {
                Button { twirpConfiguration = .none } label: { Label { Text("None") } icon: { if twirpConfiguration == .none { Image(systemName: "checkmark") } } }
                Button { twirpConfiguration = .http } label: { Label { Text("HTTP") } icon: { if twirpConfiguration == .http { Image(systemName: "checkmark") } } }
                Button { twirpConfiguration = .https } label: { Label { Text("HTTPS") } icon: { if twirpConfiguration == .https { Image(systemName: "checkmark") } } }
            } label: { Label { EmptyView() } icon: { Image(systemName: "gearshape.fill") }.layoutPriority(2).foregroundColor(.white) }

            TextField("", text: .constant(value))
                .disabled(true)
                .textFieldStyle(DemoTextfieldStyle())

            Image(systemName: isValid ? "checkmark" : "xmark")
                .foregroundColor(.white)
                .padding(4)
                .background(isValid ? Color.green : .red)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var wsEndpointPreview: some View {
        let value = configuration.ws
        let isValid = URL(string: value) != nil
        HStack {
            TextField("", text: .constant(value))
                .disabled(true)
                .textFieldStyle(DemoTextfieldStyle())

            Image(systemName: isValid ? "checkmark" : "xmark")
                .foregroundColor(.white)
                .padding(4)
                .background(isValid ? Color.green : .red)
                .clipShape(Circle())
        }
    }
}

struct DemoCheckboxView<Label: View, CheckIcon: View>: View {
    @Binding var isChecked: Bool
    var label: () -> Label
    var icon: () -> CheckIcon

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: 8) {
                label()
                    .frame(maxWidth: .infinity)
                icon()
            }
        }
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
