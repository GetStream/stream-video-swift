// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation


// MARK: - Strings

internal enum L10n {

  internal enum Call {
    internal enum Incoming {
      /// Incoming call
      internal static var title: String { L10n.tr("Localizable", "call.incoming.title") }
    }
    internal enum Outgoing {
      /// Calling
      internal static var title: String { L10n.tr("Localizable", "call.outgoing.title") }
    }
    internal enum Participants {
      /// Add participants
      internal static var add: String { L10n.tr("Localizable", "call.participants.add") }
      /// Cancel
      internal static var cancelSearch: String { L10n.tr("Localizable", "call.participants.cancel-search") }
      /// Plural format key: "%#@participants@"
      internal static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "call.participants.count", p1)
      }
      /// Invite
      internal static var invite: String { L10n.tr("Localizable", "call.participants.invite") }
      /// Mute me
      internal static var muteme: String { L10n.tr("Localizable", "call.participants.muteme") }
      /// On the platform
      internal static var onPlatform: String { L10n.tr("Localizable", "call.participants.on-platform") }
      /// Search...
      internal static var search: String { L10n.tr("Localizable", "call.participants.search") }
      /// Participants
      internal static var title: String { L10n.tr("Localizable", "call.participants.title") }
      /// Unmute me
      internal static var unmuteme: String { L10n.tr("Localizable", "call.participants.unmuteme") }
    }
  }

  internal enum WaitingRoom {
    /// It seems you are having issues with your internet connection.
    internal static var connectionIssues: String { L10n.tr("Localizable", "waiting-room.connection-issues") }
    /// You are about to join a call.
    internal static var description: String { L10n.tr("Localizable", "waiting-room.description") }
    /// Join Call
    internal static var join: String { L10n.tr("Localizable", "waiting-room.join") }
    /// more people are in the call.
    internal static var numberOfParticipants: String { L10n.tr("Localizable", "waiting-room.number-of-participants") }
    /// Setup your audio and video
    internal static var subtitle: String { L10n.tr("Localizable", "waiting-room.subtitle") }
    /// Before Joining
    internal static var title: String { L10n.tr("Localizable", "waiting-room.title") }
    internal enum Mic {
      /// Your microphone doesn't seem to be working. Make sure you have all permissions accepted.
      internal static var notWorking: String { L10n.tr("Localizable", "waiting-room.mic.not-working") }
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

