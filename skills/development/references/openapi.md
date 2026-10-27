# Regenerating OpenAPI code

Use this development reference when coordinator API endpoints, events, or models change.
Do not edit `Sources/StreamVideo/OpenApi/generated/` by hand. Change the lists below and run the script again.

## Run the generator

1. Get access to the private backend repository through the [repository access procedure](../../../AGENTS.md#related-repositories).
   `Scripts/generate.sh` expects it at `../chat` from the repository root.
   For a worktree, add a `chat` symlink next to the worktree.
2. Run `Scripts/generate.sh`. It builds the backend `tools/openapi` binary, generates the v1 video spec,
   generates Swift, prunes the output, and formats it.
   The v1 spec keeps the `/video` paths and the guest, devices, and longpoll endpoints.
   Models encode and decode with the shared `StringCodingKey` type. The script drops the keys no model uses.
   The post-processing steps live in `Scripts/openapi_generate_helpers.sh`.
3. Run the script a second time. `git diff` must not change.

## Control the output

`Scripts/openapi-allowed.json` holds sorted lists:

| Key | Effect |
| --- | --- |
| `allowedEndpoints` | `DefaultAPI` functions to keep. The script fails if one is missing. |
| `allowedEvents` | `VideoEvent` cases to keep. The script fails if one is missing. |
| `removedProperties` | Model fields the SDK does not ship. Includes new backend fields until the SDK adopts them. |
| `retypedProperties` | Property types the SDK keeps although the spec changed them. Optional types get a `nil` init default. |
| `removedEnumCases` | Enum cases the SDK does not ship. Keys are `Model` or `Model.NestedEnum`. |
| `v2Endpoints` | Endpoints the SDK calls on their `/api/v2/video` path. The v1 spec lists them under `/video`. |

The script keeps only models that `DefaultAPI` and `VideoEvent` reach.
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
2. Run the script and review new public types and fields in the diff.
3. Update test mocks and dummies, for example `StreamVideoTests/Mock/MockDefaultAPIEndpoints.swift`.
4. Build all schemes and run the tests. Required fields fail decoding when the server omits them or sends `null`.
5. Follow the [changelog rule](../SKILL.md#changelog) for public changes.
