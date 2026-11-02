# Integration tests

Use this reference for real API scenarios in
`StreamVideoTests/IntegrationTests/`.
The component table uses paths relative to that suite. Other paths start at the repository root.

## Existing components

| Component | Location within the suite |
| --- | --- |
| Scenarios | `Call_IntegrationTests.swift` |
| Flow operations | `Components/Call_IntegrationTests+CallFlow.swift` |
| Assertions | `Components/Call_IntegrationTests+Assertions.swift` |
| Authentication, users, permissions, cleanup | `Components/Helpers/` |

## Procedure

1. Keep `private var helpers: Call_IntegrationTests.Helpers! = .init()`.
   Start each participant with `helpers.callFlow(...)`.
   Create generated users through their flows before using their member IDs.
2. Use `.perform` when later steps need the returned value.
   Use `.performWithoutValueOverride` when they do not.
   Use `.map`, `.tryMap`, and actor-specific variants when appropriate.
3. Use `.assert` for immediate state. Use `.assertEventually` for propagation.
   Subscribe to events before the triggering operation with `subscribe(for:)`.
   Use the existing `defaultTimeout` from
   `StreamVideoTests/TestUtils/AssertAsync.swift`.
4. Use `performWithErrorExpectation` for expected API failures.
   Check the `APIError` code and message.
   Use separate flows with `withThrowingTaskGroup` for concurrent participants.
5. Call `helpers.dismantle()` in async teardown.
   Check `call.streamVideo.state.activeCall == nil` when testing departure.
   Assert the specific user-visible behavior separately where applicable.

## Inputs and execution

- Use `String.unique` for generated identities and values.
  Use `helpers.users.knownUser*` only when the scenario requires stable users.
- Set permissions through `helpers.permissions.setMicrophonePermission(...)`
  and `setCameraPermission(...)`.
- Read `TestsAuthenticationProvider` and the helpers for current authentication.
  The default environment is `pronto`.
  Fixture-backed livestream and audio-room scenarios use `environment: "demo"`.
- Check service access before running. Do not store credentials in tests.
  Report missing access as a blocked live test.
- Select scheme `StreamVideo` and test plan `StreamVideo`.
  Use `-only-testing:StreamVideoTests/Call_IntegrationTests` for this suite.
  Check the plan's exclusions. Enable the requested cases before execution.
  Follow the test skill for counts, destinations, and repeated runs.
