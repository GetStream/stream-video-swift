:::warning
Requires writing
:::

# CallController

The `CallController` class deals with a particular call. It's created before the call is started, and it should be deallocated when the call ends.

If you want to build your own presentation layer around video calls (ViewModel / Presenter), you should use this class. It provides access to call related actions, such as muting audio/video, changing the camera input, hanging up, etc.

When a call starts, the call controller communicates with our backend infrastructure, to find the best Selective Forwarding Unit (SFU) to host the call, based on the locations of the participants. It then establishes the connection with that SFU and provides updates on all events related to a call.

You can create a new call controller via the `StreamVideo`'s method `func makeCallController(callType: CallType, callId: String)`.
