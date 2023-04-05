:::warning
Requires writing
:::

## Low-Level Client

The low-level client is used for establishing audio and video calls. It integrates with Stream's backend infrastructure, and implements the WebRTC protocol.

Here are the most important components that the low-level client provides:

- `StreamVideo` - the main SDK object.
- `Call` - represents a particular call.
- `CallViewModel` - stateful ViewModel that contains presentation logic.
