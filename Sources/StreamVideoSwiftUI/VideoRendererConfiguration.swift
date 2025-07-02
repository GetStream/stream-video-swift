//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration options for video rendering performance optimization.
public enum VideoRendererConfiguration {
    
    /// Prewarms video renderers to avoid UI blocking when video views are first created.
    /// This should be called early in your app lifecycle, before any video views appear.
    /// Safe to call from any thread - will never block the caller.
    ///
    /// - Parameter count: The number of video renderers to pre-create (default is 2).
    ///
    /// ## Usage
    /// ```swift
    /// // Early in app lifecycle - simple call, never blocks
    /// VideoRendererConfiguration.prewarm(count: 5)
    ///
    /// // Then later initialize StreamVideo as usual
    /// let streamVideo = StreamVideo(apiKey: apiKey, user: user, token: token)
    /// ```
    public static func prewarm(count: Int = 2) {
        Task.detached {
            await VideoRendererPool.configure(initialCapacity: count)
        }
    }
}