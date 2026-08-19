//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CommonCrypto
import Foundation
import StreamVideo
import SwiftUI

extension AppEnvironment {

    /// Debug-menu storage for framed AES-GCM shared keys used when preparing a call.
    @MainActor
    final class EncryptionKeys: ObservableObject {
        static let shared = EncryptionKeys()

        enum Prompt: String, Identifiable, Equatable, Sendable {
            case oneKey
            case manyKeys

            var id: String { rawValue }
        }

        /// Shared keys in trailer order (`keyIndex` 0, 1, 2, …). Empty means E2EE is off.
        @Published var values: [Data] = []
        /// Passphrase or hex shown in the lobby field and invite URL. Empty when using many keys.
        @Published var passphrase: String = ""
        @Published var prompt: Prompt?

        var menuTitle: String {
            switch values.count {
            case 0:
                return "Encryption Key"
            case 1:
                return "Encryption Key (1)"
            default:
                return "Encryption Key (\(values.count))"
            }
        }

        var wantsEncryption: Bool {
            !values.isEmpty || !shareKey.isEmpty
        }

        var shareKey: String {
            let trimmed = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
            return values.first.map(DemoHex.string(from:)) ?? ""
        }

        /// Get-or-create override so new calls are created with `auto-on`.
        var encryptionRequest: EncryptionSettingsRequest? {
            wantsEncryption ? .init(mode: .autoOn) : nil
        }

        /// Parses pasted hex or a web-style passphrase into shared keys.
        func apply(_ raw: String, from prompt: Prompt) throws {
            let keys: [Data]
            switch prompt {
            case .oneKey:
                keys = [try DemoHex.material(from: raw)]
            case .manyKeys:
                keys = try DemoHex.keys(from: raw)
            }
            try Self.validate(keys)
            values = keys
            passphrase = prompt == .oneKey
                ? raw.trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            self.prompt = nil
            log.debug(
                "Demo encryption keys saved: \(keys.count) key(s), \(keys[0].count) bytes.",
                subsystems: .webRTC
            )
        }

        func applyPassphraseField(_ raw: String) {
            passphrase = raw
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                values = []
                return
            }
            values = (try? [DemoHex.material(from: trimmed)]) ?? []
        }

        func generatePassphrase() {
            try? apply(DemoPassphrase.random(), from: .oneKey)
        }

        func applyDeeplink(_ info: DeeplinkInfo) {
            guard let key = info.encryptionKey?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !key.isEmpty
            else { return }
            applyPassphraseField(key)
        }

        func inviteURL(callId: String, callType: String) -> URL {
            var url = AppEnvironment.baseURL.joinLink(callId, callType: callType)
            let key = shareKey
            if !key.isEmpty {
                url = url.addQueryParameter("encryption_key", value: key)
            }
            return url
        }

        func clear() {
            values = []
            passphrase = ""
            prompt = nil
        }

        /// Asks the root debug menu to show the hex editor after UIMenu dismisses.
        func request(_ prompt: Prompt) {
            Task { @MainActor [weak self] in
                try await Task.sleep(nanoseconds: 350_000_000)
                self?.prompt = prompt
            }
        }

        /// Attaches ``EncryptionManager`` with the stored shared keys before join.
        ///
        /// When the list is empty, detaches any manager left on the cached
        /// ``Call`` so join reports `e2ee: false`. Uses AES-128 or AES-256
        /// from the first key's length; mixed lengths are rejected.
        func attachIfNeeded(to call: Call, userId: String) async {
            if !passphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               values.isEmpty {
                applyPassphraseField(passphrase)
            }
            let keys = values
            guard !keys.isEmpty else {
                try? await call.setE2EEManager(nil)
                log.debug(
                    "Demo E2EE skipped: no encryption keys.",
                    subsystems: .webRTC
                )
                return
            }

            do {
                try Self.validate(keys)
                let algorithm: E2EEAlgorithm = keys[0].count == 32 ? .aes256Gcm : .aes128Gcm
                let e2ee = try EncryptionManager(userId: userId, algorithm: algorithm)
                for (index, rawKey) in keys.enumerated() {
                    try e2ee.setSharedKey(index, rawKey: rawKey)
                }
                try await call.setE2EEManager(e2ee)
                log.debug(
                    "Demo E2EE attached with \(keys.count) shared key(s).",
                    subsystems: .webRTC
                )
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }

        private static func validate(_ keys: [Data]) throws {
            let lengths = Set(keys.map(\.count))
            guard lengths.count == 1, let length = lengths.first else {
                throw EncryptionKeyError.mixedLength
            }
            guard length == 16 || length == 32 else {
                throw EncryptionKeyError.wrongLength(length)
            }
        }
    }
}

extension DebugMenu {

    /// Feature-flag entry for pasting one shared key or many (comma / newline separated).
    struct EncryptionKeyMenuView: View {

        @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared

        var body: some View {
            Menu {
                Button {
                    keys.clear()
                } label: {
                    label("None", selected: keys.values.isEmpty)
                }

                Button {
                    keys.request(.oneKey)
                } label: {
                    label("One Key", selected: keys.values.count == 1)
                }

                Button {
                    keys.request(.manyKeys)
                } label: {
                    label("Many Keys", selected: keys.values.count > 1)
                }
            } label: {
                Text(keys.menuTitle)
            }
        }

        @ViewBuilder
        private func label(_ title: String, selected: Bool) -> some View {
            Label {
                Text(title)
            } icon: {
                if selected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    /// Sheet editor. Alert `TextField` bindings often don't commit before OK.
    struct EncryptionKeyEditorView: View {

        let prompt: AppEnvironment.EncryptionKeys.Prompt

        @ObservedObject private var keys = AppEnvironment.EncryptionKeys.shared
        @Environment(\.presentationMode) private var presentationMode
        @State private var text = ""
        @State private var errorMessage: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                Button {
                    save()
                } label: {
                    CallButtonView(title: "Save", isDisabled: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle(prompt == .oneKey ? "Encryption Key" : "Encryption Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        keys.prompt = nil
                    }
                }
            }
            .onAppear {
                switch prompt {
                case .oneKey:
                    text = keys.values.first.map(DemoHex.string(from:)) ?? ""
                case .manyKeys:
                    text = keys.values.map(DemoHex.string(from:)).joined(separator: ",")
                }
            }
        }

        private var subtitle: String {
            switch prompt {
            case .oneKey:
                return "32/64-char hex, or a passphrase (same PBKDF2 as web)."
            case .manyKeys:
                return "Comma or newline separated hex or passphrases. Trailer index is 0, 1, 2, …"
            }
        }

        private func save() {
            do {
                try keys.apply(text, from: prompt)
                presentationMode.wrappedValue.dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private enum EncryptionKeyError: LocalizedError {
    case empty
    case mixedLength
    case wrongLength(Int)
    case derivationFailed

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Paste a hex key or passphrase first."
        case .mixedLength:
            return "All keys must be the same length."
        case let .wrongLength(count):
            return "Key is \(count) bytes. Need 16 (AES-128) or 32 (AES-256)."
        case .derivationFailed:
            return "Could not derive a key from that passphrase."
        }
    }
}

/// Hex and passphrase helpers for debug-menu AES-GCM keys.
///
/// Passphrases match the web demo: PBKDF2-HMAC-SHA256, salt `stream-e2ee`,
/// 100_000 iterations, 16-byte AES-128.
enum DemoHex {
    private static let passphraseSalt = Data("stream-e2ee".utf8)
    private static let passphraseIterations: UInt32 = 100_000
    private static let passphraseKeyLength = 16

    static func data(from string: String) -> Data? {
        var hex = string.filter { !$0.isWhitespace }
        if hex.hasPrefix("0x") || hex.hasPrefix("0X") {
            hex.removeFirst(2)
        }
        guard hex.count.isMultiple(of: 2), !hex.isEmpty else { return nil }
        var data = Data()
        data.reserveCapacity(hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    /// 16/32-byte hex, otherwise the web PBKDF2 passphrase derivation.
    static func material(from string: String) throws -> Data {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw EncryptionKeyError.empty }
        if let data = data(from: trimmed), data.count == 16 || data.count == 32 {
            return data
        }
        return try deriveKeyFromPassphrase(trimmed)
    }

    static func keys(from string: String) throws -> [Data] {
        let tokens = string
            .split { $0.isNewline || $0 == "," || $0 == ";" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { throw EncryptionKeyError.empty }
        return try tokens.map { try material(from: $0) }
    }

    static func string(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    static func deriveKeyFromPassphrase(_ passphrase: String) throws -> Data {
        var password = Array(passphrase.utf8)
        var salt = Array(passphraseSalt)
        var derived = [UInt8](repeating: 0, count: passphraseKeyLength)
        let status = password.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                derived.withUnsafeMutableBytes { derivedBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: CChar.self).baseAddress,
                        password.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        passphraseIterations,
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        passphraseKeyLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw EncryptionKeyError.derivationFailed }
        return Data(derived)
    }
}

/// Three hyphenated words, same shape as the web dogfood passphrase.
enum DemoPassphrase {
    static let words = [
        "able", "acid", "anger", "apple", "arrow", "beach", "berry", "bird",
        "blade", "brave", "brick", "brook", "cider", "cloud", "coral", "crane",
        "creek", "delta", "dune", "eagle", "ember", "field", "flame", "flint",
        "frost", "glade", "grove", "haven", "honey", "ivory", "jade", "maple",
        "meadow", "melon", "moss", "noble", "north", "olive", "orbit", "otter",
        "pearl", "pine", "plaid", "plume", "pond", "quartz", "rain", "ridge",
        "river", "robin", "rover", "sable", "sage", "shore", "silk", "slate",
        "solar", "spark", "stone", "storm", "tide", "tiger", "trail", "vapor",
        "violet", "willow", "wind", "wolf"
    ]

    static func random() -> String {
        Array(words.shuffled().prefix(3)).joined(separator: "-")
    }
}
