//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoAddUserView: View {

    @Injected(\.videoAppearance) var videoAppearance
    @Environment(\.presentationMode) var presentationMode

    @State var name = ""
    @State var id = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: tokens.layout.spacingXs) {
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
            .padding(tokens.layout.spacingMd)
            .navigationTitle("Add a new User")
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var buttonDisabled: Bool {
        name.isEmpty || id.isEmpty
    }
}

@MainActor
struct DemoCustomEnvironmentView: View {

    @Injected(\.videoAppearance) var videoAppearance
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
        _baseURL = .init(initialValue: baseURL)
        _apiKey = .init(initialValue: apiKey)
        _token = .init(initialValue: token)
        _usesDefaultPushNotificationConfig = .init(initialValue: AppState.shared.pushNotificationConfiguration == .default)
        self.completionHandler = completionHandler
    }

    var body: some View {
        ScrollView {
            VStack(spacing: tokens.layout.spacingXs) {
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
        .padding(tokens.layout.spacingMd)
        .navigationTitle("Custom Environment")
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private var buttonDisabled: Bool {
        apiKey.isEmpty || token.isEmpty
    }

    @ViewBuilder
    private var pushNotificationConfiguration: some View {
        VStack(spacing: tokens.layout.spacingXs) {
            DemoCheckboxView(isChecked: $usesDefaultPushNotificationConfig) {
                Text("Use `.default` push notification configuration")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: usesDefaultPushNotificationConfig ? "checkmark.square" : "square")
            }
            .foregroundColor(
                Color(usesDefaultPushNotificationConfig ? tokens.colors.textPrimary : tokens.colors.textSecondary)
            )

            if !usesDefaultPushNotificationConfig {
                VStack(spacing: tokens.layout.spacingXs) {
                    TextField("Push Notification", text: $pushNotificationName)
                    TextField("VoIP Push Notification", text: $voIPPushNotificationName)
                }
                .textFieldStyle(DemoTextfieldStyle())
            }
        }
        .padding(.vertical, tokens.layout.spacingMd)
    }
}

struct DemoCheckboxView<Label: View, CheckIcon: View>: View {
    @Injected(\.videoAppearance) var videoAppearance

    @Binding var isChecked: Bool
    var label: () -> Label
    var icon: () -> CheckIcon

    var body: some View {
        Button {
            isChecked.toggle()
        } label: {
            HStack(spacing: tokens.layout.spacingXs) {
                label()
                    .frame(maxWidth: .infinity)
                icon()
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct DemoTextfieldStyle: TextFieldStyle {

    @Injected(\.videoAppearance) var videoAppearance

    @ViewBuilder
    private var clipShape: some Shape {
        RoundedRectangle(cornerRadius: tokens.layout.radiusMd)
    }

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(tokens.layout.spacingMd)
            .foregroundColor(Color(tokens.colors.inputTextDefault))
            .background(Color(tokens.colors.backgroundCoreSurfaceDefault))
            .overlay(clipShape.stroke(Color(tokens.colors.borderCoreDefault), lineWidth: 1))
            .clipShape(clipShape)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct DemoTextEditor: View {

    @Injected(\.videoAppearance) var videoAppearance

    var text: Binding<String>

    var placeholder: String

    private let notificationCenter: NotificationCenter = .default

    @ViewBuilder
    private var clipShape: some Shape {
        RoundedRectangle(cornerRadius: tokens.layout.radiusMd)
    }

    var body: some View {
        withPlaceholder {
            withClearBackgroundContent
                .lineLimit(4)
                .padding(tokens.layout.spacingMd)
                .foregroundColor(
                    Color(
                        text.wrappedValue == placeholder
                            ? tokens.colors.inputTextPlaceholder
                            : tokens.colors.inputTextDefault
                    )
                )
                .background(Color(tokens.colors.backgroundCoreSurfaceDefault))
                .overlay(clipShape.stroke(Color(tokens.colors.borderCoreDefault), lineWidth: 1))
                .clipShape(clipShape)
                .frame(height: 100)
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

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
