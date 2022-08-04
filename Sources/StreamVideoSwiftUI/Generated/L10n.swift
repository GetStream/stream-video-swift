// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation


// MARK: - Strings

internal enum L10n {

  internal enum Call {
    internal enum Participants {
      /// Plural format key: "%#@participants@"
      internal static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "call.participants.count", p1)
      }
      /// Offline
      internal static var offline: String { L10n.tr("Localizable", "call.participants.offline") }
      /// On the call
      internal static var online: String { L10n.tr("Localizable", "call.participants.online") }
      /// Participants
      internal static var title: String { L10n.tr("Localizable", "call.participants.title") }
    }
  }
}

// MARK: - Implementation Details

extension L10n {

  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
     let format = Appearance.localizationProvider(key, table)
     return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {
  static let bundle: Bundle = .streamVideoUI
}

