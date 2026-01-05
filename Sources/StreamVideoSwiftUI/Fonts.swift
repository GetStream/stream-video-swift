//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Provides access to fonts used in the SDK.
public struct Fonts {
    
    public init() { /* Public init. */ }
    
    public var caption1 = Font.caption
    public var footnoteBold = Font.footnote.bold()
    public var footnote = Font.footnote
    public var subheadline = Font.subheadline
    public var subheadlineBold = Font.subheadline.bold()
    public var body = Font.body
    public var bodyBold = Font.body.bold()
    public var bodyItalic = Font.body.italic()
    public var headline = Font.headline
    public var headlineBold = Font.headline.bold()
    public var title = Font.title
    public var title2 = title2Font
    public var title3 = title3Font
    public var emoji = Font.system(size: 50)
    
    private static var title2Font: Font {
        if #available(iOS 14.0, *) {
            return Font.title2
        } else {
            return Font.headline
        }
    }
    
    private static var title3Font: Font {
        if #available(iOS 14.0, *) {
            return Font.title3
        } else {
            return Font.headline
        }
    }
}
