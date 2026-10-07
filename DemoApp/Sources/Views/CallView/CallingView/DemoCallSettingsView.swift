//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

/// Shipping mic/camera row plus a demo-only encryption button.
struct DemoCallSettingsView: View {
    @Injected(\.images) private var images
    @Injected(\.layout) private var layout

    @Binding var callSettings: CallSettings

    var body: some View {
        HStack(spacing: layout.spacing2xl) {
            StatelessMicrophoneIconView(
                call: nil,
                callSettings: callSettings,
                size: layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.micTurnOn, iconStyle: .secondary),
                    disabled: .init(icon: images.micTurnOff, iconStyle: .disabled)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: !callSettings.audioOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }

            StatelessVideoIconView(
                call: nil,
                callSettings: callSettings,
                size: layout.buttonVisualHeightMd,
                controlStyle: .init(
                    enabled: .init(icon: images.videoTurnOn, iconStyle: .secondary),
                    disabled: .init(icon: images.videoTurnOff, iconStyle: .disabled)
                )
            ) {
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: !callSettings.videoOn,
                    speakerOn: callSettings.speakerOn
                )
            }

            DemoLobbyEncryptionButton()
        }
        .padding(layout.spacingMd)
    }
}

struct DemoLobbyEncryptionButton: View {
    @Injected(\.layout) private var layout

    @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            CallIconView(
                icon: Image(systemName: lockSymbol),
                size: layout.buttonVisualHeightMd,
                iconStyle: keys.wantsEncryption ? .secondary : .transparent
            )
        }
        .accessibility(identifier: "e2eeButton")
        .streamAccessibility(value: keys.wantsEncryption ? "1" : "0")
        .sheet(isPresented: $isPresented) {
            NavigationView {
                DemoLobbyEncryptionSection()
                    .navigationBarTitle("Encryption", displayMode: .inline)
                    .navigationBarItems(
                        trailing: Button("Done") { isPresented = false }
                    )
            }
            .navigationViewStyle(.stack)
        }
    }

    private var lockSymbol: String {
        if #available(iOS 16.0, *) {
            return "lock.shield"
        }
        return "lock.fill"
    }
}

struct DemoLobbyEncryptionSection: View {
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout
    @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared

    var body: some View {
        Form {
            Section(
                footer: Text(
                    "Anyone with this key can join. Don't share it in a public post."
                )
            ) {
                Toggle(isOn: enabledBinding) {
                    HStack(spacing: layout.spacingXs) {
                        Image(systemName: lockSymbol)
                            .foregroundColor(Color(colors.accentSuccess))
                        Text("End-to-end encrypted")
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(colors.accentSuccess)))
                .accessibility(identifier: "e2eeToggle")

                if keys.wantsEncryption {
                    HStack(spacing: layout.spacingXs) {
                        TextField("Shared key", text: passphraseBinding)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .accessibility(identifier: "e2eeKey")

                        Button(action: keys.generatePassphrase) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(
                                    Color(colors.textSecondary)
                                )
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .accessibilityLabel("Generate a new shared key")
                        .accessibility(identifier: "e2eeNewKey")
                    }
                }
            }
        }
    }

    private var lockSymbol: String {
        if #available(iOS 16.0, *) {
            return "lock.shield"
        }
        return "lock.fill"
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { keys.wantsEncryption },
            set: { enabled in
                if enabled {
                    if keys.shareKey.isEmpty {
                        keys.generatePassphrase()
                    }
                } else {
                    keys.clear()
                }
            }
        )
    }

    private var passphraseBinding: Binding<String> {
        Binding(
            get: { keys.passphrase },
            set: { keys.applyPassphraseField($0) }
        )
    }
}
