:::warning
Requires writing
:::

# CallViewModel

The `CallViewModel` is a presentation object that can be used directly if you need to implement your custom UI. It contains a `callState`, which provides information about whether the call is in a ringing mode, inside a call, or it's about to be closed. It also publishes events about the call participants, which you can use to update your UI.

The view model provides methods for starting and joining a call. It also wraps the call-related actions such as muting audio/video, changing the camera input, hanging up, for easier access from the views.

You should use this class directly, if you want to build your custom UI components.

On the next page, we'll describe how we approach the everlasting [SwiftUI vs. UIKit](../../basics/swiftui-vs-uikit) debate.

(Spoiler alert: we support both.)
