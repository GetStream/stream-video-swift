# Regenerating OpenAPI code

Use this development reference when coordinator API endpoints, events, or models change.
Do not edit `Sources/StreamVideo/OpenApi/generated/` by hand. Change the lists below and run the script again.

## Run the generator

1. Run `Scripts/generate.sh`. It reads the published v1 video client spec
   `openapi/video-openapi-clientside.yaml` from [GetStream/protocol](https://github.com/GetStream/protocol).
   Set `PROTOCOL_DIR` to a local checkout, or `PROTOCOL_REF` (default `main`) to download that file.
   `Scripts/apply_renamed_models.rb` applies `Scripts/renamed-models.json` to schema names, then the script generates Swift, prunes the output, and formats it.
   The v1 spec keeps the `/video` paths and the guest, devices, and longpoll endpoints.
   Models encode and decode with the shared `StringCodingKey` type. The script drops the keys no model uses.
   The post-processing steps live in `Scripts/openapi_generate_helpers.sh`.
2. Swift generation uses the `openapi` binary from the private chat repo.
   The script uses `OPENAPI` when set, then `../chat/build/openapi`, then builds `../chat/tools/openapi` when that source tree exists.
   For a worktree, add a `chat` symlink next to the worktree, or set `OPENAPI` to the binary.
3. Run the script a second time. `git diff` must not change.

## CI

`.github/workflows/openapi.yml` starts with `workflow_dispatch` on the selected branch.
The `protocol_ref` input is a `GetStream/protocol` branch name or commit hash. It defaults to `main`.
The generate job checks out that public repository.
It downloads `openapi-linux-amd64` and its `.sha256` from a `GetStream/chat` release.
`generator_release` selects the tag. An empty value uses the latest release.
The download token comes from `vars.CI_GO_MODULES_CLIENT_ID` and `secrets.CI_GO_MODULES_PRIVATE_KEY`, with contents read on `chat`.
The job checks the checksum, then runs `Scripts/generate.sh` with `PROTOCOL_DIR` and `OPENAPI` set.
The pull request job checks out this repository only, downloads the generated files, and runs `Scripts/openapi_open_pull_request.sh`.
That script commits the generated directory and opens a pull request with `git` and `gh`. It does not install Ruby or Fastlane.
The pull request job mints a token from `vars.IOS_RELEASE_BOT_CLIENT_ID` and `secrets.IOS_RELEASE_BOT_PRIVATE_KEY`, with no extra permission inputs. Checkout and `git push` use that token. `gh pr create` uses `secrets.CI_BOT_GITHUB_TOKEN`, because this release-bot installation cannot create pull requests. Commits are authored by `github-actions[bot]`.
The pull request targets the branch the workflow ran on. Its title is `[Hygiene]OpenAPI models generation`.
A failed job notifies Slack through `secrets.SLACK_WEBHOOK_IOS_BOTS`. The Slack action reads that value from the `SLACK_WEBHOOK_URL` environment variable.

## Control the output

`Scripts/openapi-allowed.json` holds sorted lists:

| Key | Effect |
| --- | --- |
| `allowedEndpoints` | `DefaultAPI` functions to keep. The script fails if one is missing. |
| `allowedEvents` | `VideoEvent` cases to keep. The script fails if one is missing. |
| `codableModels` | Models that `DefaultAPI` both encodes and decodes. |
| `decodableModels` | Models only in responses and events. They lose `Encodable` and `JSONEncodable`. |
| `encodableModels` | Models only in request bodies. They lose `Decodable`. |
| `removedProperties` | Model fields the SDK does not ship: chat fields, including links to chat such as `channel_cid`, deprecated fields, and fields whose types only excluded endpoints use, such as the `call.stats_report_ready` payload. Remove an entry when the backend drops the field from the video client spec. Fields that are constant or unused today still ship. |
| `retypedProperties` | Property types the SDK keeps although the spec changed them. Optional types get a `nil` init default. |
| `removedEnumCases` | Enum cases the SDK does not ship. Keys are `Model` or `Model.NestedEnum`. |
| `v2Endpoints` | Endpoints the SDK calls on their `/api/v2/video` path. The v1 spec lists them under `/video`. |

The script keeps only models that `DefaultAPI` and `VideoEvent` reach.
It fails unless each kept model is in exactly one of the three coding lists.
`Scripts/renamed-models.json` maps spec schema names to Swift names. Use it when the backend renames an exposed schema.

## Keep the public API stable

Breaking changes wait for a major version. Until then:

1. To keep a model the spec no longer has but a public member still uses, move it to the Deprecated section
   of `Sources/StreamVideo/OpenApi/OpenAPI+Extensions.swift`, as for `PushNotificationSettingsResponse`.
   The script drops models that no endpoint or event reaches. List removed public models in the changelog.
2. Give removed fields a deprecated `get { nil } set {}` and a deprecated init with the old signature
   in the Deprecated section of `Sources/StreamVideo/OpenApi/OpenAPI+Extensions.swift`.
3. Use `retypedProperties` for type changes and `removedEnumCases` for new enum cases.
   Both use the generated names. The generator prefixes nested enums with the model name.
   Keep old nested enum names as typealiases in `Sources/StreamVideo/OpenApi/OpenAPI+Extensions.swift`.
4. Compare the public API with the base branch. Build both, then run
   `xcrun swift-api-digester -dump-sdk -module StreamVideo` with `-sdk`, `-target`, `-F`, and `-I`
   set to the `Debug-iphonesimulator` products, and `-diagnose-sdk` on the two dumps.

## Adopt an endpoint, event, or field

1. Add the name to the matching list, or remove the field from `removedProperties`.
2. Run the script. When it lists unclassified models, add each to the coding list that matches
   how `DefaultAPI` uses it, and run it again. Review new public types and fields in the diff.
3. Update test mocks and dummies, for example `StreamVideoTests/Mock/MockDefaultAPIEndpoints.swift`.
   Responses and events are not `Encodable`. Pass them as `PassthroughJSONDecoder.decodingData(for:)`,
   as `HTTPClient_Mock` and `JsonEventDecoder_Tests` do.
   Hand-written code that rebuilds a model with its init must pass the new fields.
   Optional fields compile without them and are silently dropped.
   A deprecated convenience init in `OpenAPI+Extensions.swift` must pass the new fields to `self.init`.
   Otherwise overload ranking can pick the convenience init itself, and it recurses.
4. Build all schemes and run the tests. Required fields fail decoding when the server omits them or sends `null`.
5. Follow the [changelog rule](../SKILL.md#changelog) for public changes.
