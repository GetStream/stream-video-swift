//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// A view that displays a user's avatar image.
///
/// `UserAvatar` fetches and displays an image from a given URL. If the image
/// cannot be loaded, a failback view is displayed instead.
public struct UserAvatar<Failback: View>: View {

    /// Typealias for a provider that returns either a Failback view or an EmptyView
    public typealias FailbackProvider = () -> _ConditionalContent<Failback, EmptyView>

    public var imageURL: URL? // URL of the user's avatar image
    public var size: CGFloat // Size of the avatar
    public var failbackProvider: FailbackProvider // Provider for the failback view

    /// Initializes a `UserAvatar` view.
    ///
    /// - Parameters:
    ///   - imageURL: The URL of the user's avatar image.
    ///   - size: The size of the avatar.
    ///   - failbackProvider: A provider that returns either a failback view or an
    ///     empty view.
    public init(imageURL: URL?, size: CGFloat, failbackProvider: (() -> Failback)?) {
        self.imageURL = imageURL
        self.size = size
        self.failbackProvider = {
            if let failbackProvider {
                return ViewBuilder.buildEither(first: failbackProvider())
            } else {
                return ViewBuilder.buildEither(second: EmptyView())
            }
        }
    }
    
    /// The content and behavior of the `UserAvatar` view.
    public var body: some View {
        StreamLazyImage(imageURL: imageURL, placeholder: failbackProvider)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

/// Extension for `UserAvatar` when `Failback` is `EmptyView`.
extension UserAvatar where Failback == EmptyView {

    /// Initializes a `UserAvatar` view with no failback provider.
    ///
    /// - Parameters:
    ///   - imageURL: The URL of the user's avatar image.
    ///   - size: The size of the avatar.
    public init(imageURL: URL?, size: CGFloat) {
        self.init(imageURL: imageURL, size: size, failbackProvider: nil)
    }
}

/// Options to configure `UserAvatarView`.
///
/// `UserAvatarViewOptions` provides configuration options for the `UserAvatar`
/// view, including the size of the avatar and a provider for the failback view.
///
/// - Parameters:
///   - size: The size of the avatar.
///   - failbackProvider: A provider that returns a failback view.
public struct UserAvatarViewOptions {
    /// Size of the avatar
    public var size: CGFloat

    /// Provider for the failback view
    public var failbackProvider: (() -> AnyView)?

    /// Initializes a `UserAvatarViewOptions` instance.
    ///
    /// - Parameters:
    ///   - size: The size of the avatar.
    ///   - failbackProvider: A provider that returns a failback view.
    public init(
        size: CGFloat,
        failbackProvider: (() -> AnyView)? = nil
    ) {
        self.size = size
        self.failbackProvider = failbackProvider
    }
}
